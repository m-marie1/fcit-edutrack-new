import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/quiz_models.dart';
import '../../models/course_model.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/course_provider.dart';
import '../../style/my_app_colors.dart';
import '../../themes/theme_provider.dart';

class QuizCreationScreen extends StatefulWidget {
  static const String routeName = 'quiz_creation_screen';

  // Add quizToEdit parameter for editing existing quizzes
  final Quiz? quizToEdit;

  const QuizCreationScreen({Key? key, this.quizToEdit}) : super(key: key);

  @override
  _QuizCreationScreenState createState() => _QuizCreationScreenState();
}

class _QuizCreationScreenState extends State<QuizCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingFromDraft = false;
  bool _loadedFromDraft = false;
  bool _isEditMode = false;
  Quiz? _quizToEdit;

  // Controllers for basic quiz info
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Course? _selectedCourse;
  DateTime? _startDate;
  DateTime? _endDate;
  final _durationController = TextEditingController();

  // List to hold questions being built
  List<Question> _questions = [];
  int _questionIdCounter = 1;
  int _optionIdCounter = 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load course list first
      Provider.of<CourseProvider>(context, listen: false)
          .fetchEnrolledCourses();

      // Check if we're editing an existing quiz
      if (widget.quizToEdit != null) {
        _loadExistingQuiz(widget.quizToEdit!);
      } else {
        // Check if there's a draft to load
        _checkAndLoadDraft();
      }
    });
  }

  void _checkAndLoadDraft() async {
    setState(() {
      _isLoadingFromDraft = true;
    });

    // Delay to ensure that we have courses loaded
    await Future.delayed(const Duration(milliseconds: 500));

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    if (quizProvider.hasDraft) {
      final draftData = quizProvider.localDraft;

      // Populate form fields from draft
      _titleController.text = draftData['title'] ?? '';
      _descriptionController.text = draftData['description'] ?? '';
      _durationController.text =
          (draftData['durationMinutes'] ?? '').toString();

      // Parse dates
      if (draftData['startDate'] != null) {
        _startDate = DateTime.parse(draftData['startDate']);
      }
      if (draftData['endDate'] != null) {
        _endDate = DateTime.parse(draftData['endDate']);
      }

      // Load questions if available
      if (draftData['questions'] != null) {
        // Convert the JSON questions to QuizQuestion objects
        List<dynamic> questionsList = draftData['questions'];
        _questions = questionsList.map((q) => Question.fromJson(q)).toList();

        // Find the highest question and option IDs for counter initialization
        int highestQuestionId = 0;
        int highestOptionId = 0;

        for (var question in _questions) {
          if (question.id != null && question.id! > highestQuestionId) {
            highestQuestionId = question.id!;
          }

          if (question.options != null) {
            for (var option in question.options!) {
              if (option.id != null && option.id! > highestOptionId) {
                highestOptionId = option.id!;
              }
            }
          }
        }

        _questionIdCounter = highestQuestionId + 1;
        _optionIdCounter = highestOptionId + 1;
      }

      // Set selected course
      if (draftData['courseId'] != null) {
        final courseProvider =
            Provider.of<CourseProvider>(context, listen: false);
        try {
          _selectedCourse = courseProvider.enrolledCourses
              .firstWhere((course) => course.id == draftData['courseId']);
        } catch (e) {
          print('Failed to find course with ID ${draftData['courseId']}');
        }
      }

      setState(() {
        _loadedFromDraft = true;
        _isLoadingFromDraft = false;
      });
    } else {
      setState(() {
        _isLoadingFromDraft = false;
      });
    }
  }

  void _loadExistingQuiz(Quiz quiz) {
    setState(() {
      _isEditMode = true;
      _quizToEdit = quiz;

      // Populate form fields with existing quiz data
      _titleController.text = quiz.title;
      _descriptionController.text = quiz.description;
      _durationController.text = quiz.durationMinutes.toString();
      _startDate = quiz.startDate;
      _endDate = quiz.endDate;
      _questions = quiz.questions;

      // Set up course selection
      final courseProvider =
          Provider.of<CourseProvider>(context, listen: false);
      try {
        _selectedCourse = courseProvider.enrolledCourses
            .firstWhere((c) => c.id == quiz.courseId);
      } catch (e) {
        // If course not found, use first available course
        if (courseProvider.enrolledCourses.isNotEmpty) {
          _selectedCourse = courseProvider.enrolledCourses.first;
        }
      }

      // Initialize question and option counters
      int highestQuestionId = 0;
      int highestOptionId = 0;

      for (var question in _questions) {
        if (question.id != null && question.id! > highestQuestionId) {
          highestQuestionId = question.id!;
        }

        if (question.options != null) {
          for (var option in question.options!) {
            if (option.id != null && option.id! > highestOptionId) {
              highestOptionId = option.id!;
            }
          }
        }
      }

      _questionIdCounter = highestQuestionId + 1;
      _optionIdCounter = highestOptionId + 1;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    // Dispose question/option controllers if added later
    super.dispose();
  }

  // --- UI Building Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode
            ? 'Edit Quiz'
            : (_loadedFromDraft ? 'Edit Draft Quiz' : 'Create Quiz')),
        backgroundColor: MyAppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save as Draft',
            onPressed: _saveQuizAsDraft,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          // Use ListView for scrolling
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildQuizInfoSection(),
            const Divider(height: 32),
            _buildQuestionsSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quiz Details', style: Theme.of(context).textTheme.titleLarge!.copyWith(
           color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
        )),
        const SizedBox(height: 16),
        TextFormField(
          cursorColor: MyAppColors.primaryColor,
          controller: _titleController,
          decoration: const InputDecoration(
              labelText: 'Quiz Title',
              labelStyle: TextStyle(
                color: MyAppColors.primaryColor
              ),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: MyAppColors.primaryColor
                )
              ),

          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Please enter a title' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          cursorColor: MyAppColors.primaryColor,
          controller: _descriptionController,
          decoration: const InputDecoration(
              labelText: 'Description',
            labelStyle: TextStyle(
                color: MyAppColors.primaryColor
            ),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: MyAppColors.primaryColor
                )
            ),
          ),
          maxLines: 3,
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter a description'
              : null,
        ),
        const SizedBox(height: 12),
        Consumer<CourseProvider>(
          builder: (context, courseProvider, _) {
            // Only show dropdown after courses are loaded
            if (courseProvider.enrolledCourses.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(
                    color: MyAppColors.primaryColor,
                  ),
                ),
              );
            }

            // Reset selected course if courses loaded and no course selected
            if (_selectedCourse == null &&
                courseProvider.enrolledCourses.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedCourse = courseProvider.enrolledCourses.first;
                });
              });
              // Return a placeholder while we wait for setState to complete
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text("Loading courses..."),
              );
            }

            return DropdownButtonFormField<Course>(
              dropdownColor: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
              decoration: const InputDecoration(
                labelText: 'Course',
                labelStyle: TextStyle(
                    color: MyAppColors.primaryColor
                ),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: MyAppColors.primaryColor
                    )
                ),
              ),
              isExpanded: true,
              value: _selectedCourse != null
                  ? courseProvider.enrolledCourses.firstWhere(
                      (c) => c.id == _selectedCourse!.id,
                      orElse: () => courseProvider.enrolledCourses.first)
                  : (_selectedCourse = courseProvider.enrolledCourses.first),
              items: courseProvider.enrolledCourses.map((course) {
                return DropdownMenuItem<Course>(
                  value: course,
                  child: Text(
                    '${course.courseName} (${course.courseCode})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MyAppColors.primaryColor
                    ),
                  ),
                );
              }).toList(),
              onChanged: _isEditMode
                  ? null // Disable in edit mode
                  : (course) {
                      setState(() {
                        _selectedCourse = course;
                      });
                    },
              validator: (val) => val == null ? 'Please select a course' : null,
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildDateTimePicker('Start Date', _startDate,
                    (date) => setState(() => _startDate = date))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildDateTimePicker('End Date', _endDate,
                    (date) => setState(() => _endDate = date))),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          cursorColor: MyAppColors.primaryColor,
          controller: _durationController,
          decoration: const InputDecoration(
              labelText: 'Duration (Minutes)',
              labelStyle: TextStyle(
                color: MyAppColors.primaryColor
              ),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(
                color: MyAppColors.primaryColor
              ) ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter duration';
            if (int.tryParse(value) == null || int.parse(value) <= 0) {
              return 'Enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(
      String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return InkWell(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate:
              DateTime.now().subtract(const Duration(days: 1)), // Allow today
          lastDate: DateTime.now()
              .add(const Duration(days: 365 * 2)), // Allow 2 years in future
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: Theme.of(context).copyWith(
                datePickerTheme: DatePickerThemeData(
                  backgroundColor: MyAppColors.lightBackgroundColor,
                ),
                colorScheme: const ColorScheme.light(
                  primary: MyAppColors.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
            builder: (BuildContext context, Widget? child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    timePickerTheme: TimePickerThemeData(
                        helpTextStyle: const TextStyle(
                            color: MyAppColors.darkBlueColor,
                            fontSize: 16
                        ),
                        backgroundColor: MyAppColors.lightBackgroundColor,
                        hourMinuteColor:MyAppColors.primaryColor,
                        hourMinuteTextColor: Colors.white,
                        dayPeriodTextColor: MyAppColors.whiteColor,
                        dialBackgroundColor: MyAppColors.whiteColor,
                        dialHandColor: MyAppColors.primaryColor,
                        dialTextColor: Colors.black,
                        entryModeIconColor: MyAppColors.primaryColor,
                        dayPeriodColor: MyAppColors.primaryColor
                    ),
                    colorScheme: const ColorScheme.light(
                      primary: MyAppColors.primaryColor,
                    ),
                  ),
                  child: child!,
                ),
              );
            },
          );
          if (pickedTime != null) {
            final finalDateTime = DateTime(pickedDate.year, pickedDate.month,
                pickedDate.day, pickedTime.hour, pickedTime.minute);
            onDateSelected(finalDateTime);
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          selectedDate == null
              ? 'Select Date & Time'
              : DateFormat('yyyy-MM-dd HH:mm').format(selectedDate),
        ),
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Questions (${_questions.length})',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color:Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
            )),
        const SizedBox(height: 8),
        if (_questions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
                child: Text(
                    'No questions added yet. Click "Add Question" below.')),
          )
        else
          ListView.builder(
            shrinkWrap: true, // Important inside a ListView
            physics:
                const NeverScrollableScrollPhysics(), // Disable inner scrolling
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final question = _questions[index];
              return Card(
                color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(question.text,
                      style: TextStyle(
                        color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                      ),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      'Type: ${question.type.name}, Points: ${question.points}',style: TextStyle(
                    color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.blackColor
                  ),),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit_outlined, color: Colors.blue),
                        tooltip: 'Edit Question',
                        onPressed: () =>
                            _editQuestion(index), // Call edit method
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Remove Question',
                        onPressed: () =>
                            _removeQuestion(index), // Call remove method
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Question'),
          onPressed: _addQuestion, // Calls the updated method
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: MyAppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ))
            : const Text('Save Quiz'),
      ),
    );
  }

  // --- Logic Methods ---

  // Method to show dialog for adding/editing a question
  Future<void> _showQuestionDialog({int? editIndex}) async {
    final isEditing = editIndex != null;
    final existing = isEditing ? _questions[editIndex!] : null;

    final questionTextController = TextEditingController(text: existing?.text ?? '');
    final pointsController = TextEditingController(text: existing?.points.toString() ?? '');
    final textAnswerController = TextEditingController(text: existing?.correctAnswer ?? '');

    QuestionType selectedType = existing?.type ?? QuestionType.MULTIPLE_CHOICE;

    List<TextEditingController> optionControllers = [];
    int? correctOptionIndex;

    if (selectedType == QuestionType.MULTIPLE_CHOICE && existing?.options != null) {
      optionControllers = existing!.options!
          .map((opt) => TextEditingController(text: opt.text))
          .toList();
      correctOptionIndex = existing.options!.indexWhere((opt) => opt.isCorrect);
      if (correctOptionIndex == -1) correctOptionIndex = null;
    } else {
      optionControllers = [TextEditingController(), TextEditingController()];
    }

    final navigator = Navigator.of(context, rootNavigator: true);

    final result = await showDialog<Question>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
              title: Text(isEditing ? 'Edit Question' : 'Add New Question',style:
                const TextStyle(
                  color: MyAppColors.primaryColor
                ),),
              content: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      cursorColor: MyAppColors.primaryColor,
                      controller: questionTextController,
                      decoration: const InputDecoration(
                          labelText: 'Question Text',
                          labelStyle: TextStyle(
                            color: MyAppColors.primaryColor
                          ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: MyAppColors.primaryColor
                          )
                        )
                      ),
                    ),
                    TextField(
                      cursorColor: MyAppColors.primaryColor,
                      controller: pointsController,
                      decoration: const InputDecoration(labelText: 'Points',
                          labelStyle: TextStyle(
                            color: MyAppColors.primaryColor
                          ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: MyAppColors.primaryColor
                          )
                        )
                        ),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<QuestionType>(
                      dropdownColor: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
                      value: selectedType,
                      items: QuestionType.values
                          .where((t) => t != QuestionType.UNKNOWN)
                          .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type.name)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setDialogState(() => selectedType = value);
                      },
                      decoration: const InputDecoration(
                          labelText: 'Question Type',
                          labelStyle: TextStyle(
                            color: MyAppColors.primaryColor
                          ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: MyAppColors.primaryColor
                          )
                        )
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedType == QuestionType.MULTIPLE_CHOICE)
                      _buildMultipleChoiceOptions(
                        setDialogState,
                        optionControllers,
                        correctOptionIndex,
                            (index) => setDialogState(() => correctOptionIndex = index),
                      ),
                    if (selectedType == QuestionType.TEXT_ANSWER)
                      TextField(
                        cursorColor: MyAppColors.primaryColor,
                        controller: textAnswerController,
                        decoration:
                        const InputDecoration(
                            labelText: 'Correct Answer',
                            labelStyle: TextStyle(
                              color: MyAppColors.primaryColor
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: MyAppColors.primaryColor
                              )
                            )
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => navigator.pop(),
                  child: const Text('Cancel',style: TextStyle(
                    color: MyAppColors.primaryColor
                  ),),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (questionTextController.text.isEmpty || pointsController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fill in all required fields')),
                      );
                      return;
                    }

                    if (selectedType == QuestionType.MULTIPLE_CHOICE) {
                      if (optionControllers.any((c) => c.text.isEmpty) || correctOptionIndex == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fill all options and mark one as correct')),
                        );
                        return;
                      }
                    } else if (selectedType == QuestionType.TEXT_ANSWER &&
                        textAnswerController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Provide correct answer')),
                      );
                      return;
                    }

                    // Close the keyboard safely
                    FocusScope.of(context).unfocus();
                    await Future.delayed(const Duration(milliseconds: 300));

                    final newQuestion = Question(
                      text: questionTextController.text,
                      type: selectedType,
                      points: int.parse(pointsController.text),
                      options: selectedType == QuestionType.MULTIPLE_CHOICE
                          ? optionControllers.asMap().entries.map((entry) {
                        return Option(
                          text: entry.value.text,
                          isCorrect: entry.key == correctOptionIndex,
                        );
                      }).toList()
                          : null,
                      correctAnswer: selectedType == QuestionType.TEXT_ANSWER
                          ? textAnswerController.text
                          : null,
                    );

                    if (mounted && navigator.canPop()) {
                      navigator.pop(newQuestion);
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add'),
                  ),
                  ],
                  );
                },
              );
            },
          );

    if (result != null && mounted) {
      setState(() {
        if (isEditing) {
          _questions[editIndex!] = result;
        } else {
          _questions.add(result);
        }
      });
    }

    questionTextController.dispose();
    pointsController.dispose();
    textAnswerController.dispose();
    for (final c in optionControllers) {
      c.dispose();
    }
  }


  // Helper Widget for Multiple Choice Options
  Widget _buildMultipleChoiceOptions(
      StateSetter setDialogState,
      List<TextEditingController> controllers,
      int? correctIndex,
      Function(int?) onCorrectSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...controllers.asMap().entries.map((entry) {
          int idx = entry.key;
          TextEditingController ctrl = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    cursorColor: MyAppColors.primaryColor,
                    controller: ctrl,
                    decoration: InputDecoration(
                        labelText: 'Option ${idx + 1}',
                        labelStyle: const TextStyle(
                          color: MyAppColors.primaryColor
                        ),
                         focusedBorder: const UnderlineInputBorder(
                           borderSide: BorderSide(
                             color: MyAppColors.primaryColor
                           )
                         )
                    ),
                  ),
                ),
                Radio<int?>(
                  fillColor: WidgetStateProperty.all(MyAppColors.primaryColor),
                  value: idx,
                  groupValue: correctIndex,
                  onChanged: onCorrectSelected,
                  visualDensity: VisualDensity.compact, // Make radio smaller
                ),
                const Text('Correct'),
                // Only show remove button if more than 2 options
                if (controllers.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 20),
                    tooltip: 'Remove Option',
                    onPressed: () {
                      setDialogState(() {
                        ctrl.dispose(); // Dispose controller before removing
                        controllers.removeAt(idx);
                        // Adjust correct index if necessary
                        if (correctIndex == idx) {
                          onCorrectSelected(null); // Unset correct option
                        } else if (correctIndex != null && correctIndex > idx) {
                          onCorrectSelected(
                              correctIndex - 1); // Shift index down
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.add_circle_outline, size: 18,color: MyAppColors.primaryColor,),
          label: const Text('Add Option',style: TextStyle(
            color: MyAppColors.primaryColor
          ),),
          onPressed: () {
            setDialogState(() {
              controllers.add(TextEditingController());
            });
          },
        ),
      ],
    );
  }

  // Placeholder for editing (calls the same dialog)
  void _editQuestion(int index) {
    _showQuestionDialog(editIndex: index);

  }

  // Method to remove a question
  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  // Updated _addQuestion to call the dialog
  void _addQuestion() {
    _showQuestionDialog();
  }

  // New method to save quiz as draft
  void _saveQuizAsDraft() {
    if (!_formKey.currentState!.validate()) {
      // Show error for required fields
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // Create map of quiz data
    final quizData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'courseId': _selectedCourse?.id,
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'durationMinutes': int.tryParse(_durationController.text) ?? 60,
      'questions': _questions.map((q) => q.toJson()).toList(),
    };

    // Save to provider
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    quizProvider.saveLocalDraft(quizData);

    // Show confirmation and go back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Quiz saved as draft'), backgroundColor: Colors.green),
    );
    Navigator.pop(context, true);
  }

  // Update saveQuiz method
  void _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      // Show errors for required fields
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    // When editing, make sure we preserve question IDs
    final questions = _isEditMode
        ? _questions // Keep original questions with IDs preserved
        : _questions.map((q) {
            // For new quizzes, remove IDs to let backend assign them
            return Question(
              text: q.text,
              type: q.type,
              points: q.points,
              options: q.options,
              correctAnswer: q.correctAnswer,
            );
          }).toList();

    final quiz = Quiz(
      id: _isEditMode ? _quizToEdit!.id : null, // Include ID for editing
      title: _titleController.text,
      description: _descriptionController.text,
      courseId: _selectedCourse!.id,
      startDate: _startDate!,
      endDate: _endDate!,
      durationMinutes: int.parse(_durationController.text),
      questions: questions,
    );

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final Map<String, dynamic> response;

    if (_isEditMode) {
      // Edit existing quiz
      response = await quizProvider.editQuiz(_quizToEdit!.id!, quiz);
    } else {
      // Create new quiz
      response = await quizProvider.createQuiz(quiz);
    }

    // Clear draft if we were editing one
    if (_loadedFromDraft) {
      quizProvider.clearLocalDraft();
    }

    if (!mounted) return; // Check if widget is still mounted

    setState(() => _isLoading = false);

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isEditMode
                ? 'Quiz updated successfully!'
                : 'Quiz created successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Go back to management screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to ${_isEditMode ? 'update' : 'create'} quiz: ${response['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red),
      );
    }
  }
}
