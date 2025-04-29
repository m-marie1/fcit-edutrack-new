import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/quiz_models.dart';
import '../../models/course_model.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/course_provider.dart';
import '../../style/my_app_colors.dart';

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
        Text('Quiz Details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
              labelText: 'Quiz Title', border: OutlineInputBorder()),
          validator: (value) =>
              value == null || value.isEmpty ? 'Please enter a title' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
              labelText: 'Description', border: OutlineInputBorder()),
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
                  child: CircularProgressIndicator(),
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
              decoration: const InputDecoration(
                labelText: 'Course',
                border: OutlineInputBorder(),
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
          controller: _durationController,
          decoration: const InputDecoration(
              labelText: 'Duration (Minutes)', border: OutlineInputBorder()),
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
        );
        if (pickedDate != null) {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
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
            style: Theme.of(context).textTheme.titleLarge),
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
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(question.text,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      'Type: ${question.type.name}, Points: ${question.points}'),
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
    final questionTextController = TextEditingController();
    final pointsController = TextEditingController();
    QuestionType selectedType = QuestionType.MULTIPLE_CHOICE;
    // Declare controllers and state variables needed within the dialog scope
    List<TextEditingController> optionControllers = [];
    int? correctOptionIndex; // Index of the correct option for MC questions
    final textAnswerController = TextEditingController();

    bool isEditing = editIndex != null;
    if (isEditing) {
      final existingQuestion = _questions[editIndex];
      questionTextController.text = existingQuestion.text;
      pointsController.text = existingQuestion.points.toString();
      selectedType = existingQuestion.type;
      // Populate options/answer controllers based on existing question
      if (existingQuestion.type == QuestionType.MULTIPLE_CHOICE &&
          existingQuestion.options != null) {
        optionControllers = existingQuestion.options!
            .map((opt) => TextEditingController(text: opt.text))
            .toList();
        correctOptionIndex =
            existingQuestion.options!.indexWhere((opt) => opt.isCorrect);
        if (correctOptionIndex == -1) {
          correctOptionIndex =
              null; // Handle case where no correct option was marked
        }
      } else if (existingQuestion.type == QuestionType.TEXT_ANSWER) {
        textAnswerController.text = existingQuestion.correctAnswer ?? '';
      }
    } else {
      // Initialize with two empty options for new MC questions by default
      optionControllers.add(TextEditingController());
      optionControllers.add(TextEditingController());
    }

    await showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage dialog's internal state (like dropdown)
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Question' : 'Add New Question'),
            content: SingleChildScrollView(
              // Allow scrolling if content overflows
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionTextController,
                    decoration:
                        const InputDecoration(labelText: 'Question Text'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<QuestionType>(
                    value: selectedType,
                    items: QuestionType.values
                        .where((t) => t != QuestionType.UNKNOWN)
                        .map((type) {
                      // Exclude UNKNOWN
                      return DropdownMenuItem<QuestionType>(
                        value: type,
                        child: Text(type.name), // Display enum name
                      );
                    }).toList(),
                    onChanged: (QuestionType? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          // Use setDialogState for dialog UI updates
                          selectedType = newValue;
                        });
                      }
                    },
                    decoration:
                        const InputDecoration(labelText: 'Question Type'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pointsController,
                    decoration: const InputDecoration(labelText: 'Points'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // --- Dynamic Fields based on Question Type ---
                  if (selectedType == QuestionType.MULTIPLE_CHOICE)
                    _buildMultipleChoiceOptions(
                        setDialogState, optionControllers, correctOptionIndex,
                        (index) {
                      setDialogState(() => correctOptionIndex =
                          index); // Update correct index state
                    }),
                  if (selectedType == QuestionType.TEXT_ANSWER)
                    TextField(
                      controller: textAnswerController,
                      decoration: const InputDecoration(
                          labelText: 'Correct Answer Text'),
                      maxLines: 2,
                    ),
                  // --- End Dynamic Fields ---
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // --- Validation ---
                  if (questionTextController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please enter the question text.')));
                    return;
                  }
                  if (pointsController.text.isEmpty ||
                      int.tryParse(pointsController.text) == null ||
                      int.parse(pointsController.text) <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Please enter valid points (positive number).')));
                    return;
                  }
                  // Additional validation based on type
                  if (selectedType == QuestionType.MULTIPLE_CHOICE) {
                    if (optionControllers.length < 2 ||
                        optionControllers.any((c) => c.text.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please provide at least two non-empty options.')),
                      );
                      return;
                    }
                    if (correctOptionIndex == null ||
                        correctOptionIndex! < 0 ||
                        correctOptionIndex! >= optionControllers.length) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please mark one option as correct.')),
                      );
                      return;
                    }
                  } else if (selectedType == QuestionType.TEXT_ANSWER) {
                    if (textAnswerController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please provide the correct text answer.')),
                      );
                      return;
                    }
                  }
                  // --- End Validation ---

                  final newQuestion = Question(
                    // id: isEditing ? _questions[editIndex].id : null, // Keep ID if editing
                    text: questionTextController.text,
                    type: selectedType,
                    points: int.parse(pointsController.text),
                    options: selectedType == QuestionType.MULTIPLE_CHOICE
                        ? optionControllers.asMap().entries.map((entry) {
                            int idx = entry.key;
                            TextEditingController ctrl = entry.value;
                            return Option(
                                text: ctrl.text,
                                isCorrect: idx == correctOptionIndex);
                          }).toList()
                        : null,
                    correctAnswer: selectedType == QuestionType.TEXT_ANSWER
                        ? textAnswerController.text
                        : null,
                  );

                  setState(() {
                    // Update the main screen's state
                    if (isEditing) {
                      _questions[editIndex] = newQuestion;
                    } else {
                      _questions.add(newQuestion);
                    }
                  });
                  Navigator.pop(context); // Close dialog
                },
                child: Text(isEditing ? 'Save Changes' : 'Add'),
              ),
            ],
          );
        });
      },
    );
    // Dispose controllers after dialog is closed
    questionTextController.dispose();
    pointsController.dispose();
    textAnswerController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
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
                    controller: ctrl,
                    decoration: InputDecoration(labelText: 'Option ${idx + 1}'),
                  ),
                ),
                Radio<int?>(
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
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('Add Option'),
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
