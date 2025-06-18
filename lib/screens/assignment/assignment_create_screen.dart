import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/providers/assignment_provider.dart';
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/models/course_model.dart';
import 'package:fci_edutrack/models/assignment_model.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:fci_edutrack/services/api_service.dart';

class AssignmentCreateScreen extends StatefulWidget {
  static const String routeName = 'assignment_create_screen';
  const AssignmentCreateScreen({super.key});

  @override
  State<AssignmentCreateScreen> createState() => _AssignmentCreateScreenState();
}

class _AssignmentCreateScreenState extends State<AssignmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxPointsController = TextEditingController();

  DateTime? _dueDate;
  Course? _selectedCourse;
  List<PlatformFile> _selectedFiles = [];
  bool _loadedFromDraft = false;
  bool _isEditMode = false;
  Assignment? _existingAssignment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false)
          .fetchEnrolledCourses();

      // Check for arguments (existing assignment) or drafts
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Assignment) {
        // We're editing an existing assignment
        _loadExistingAssignment(args);
      } else {
        // Check for drafts
        loadDraftIfAvailable();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxPointsController.dispose();
    super.dispose();
  }

  void _loadExistingAssignment(Assignment assignment) {
    setState(() {
      _existingAssignment = assignment;
      _isEditMode = true;
      _titleController.text = assignment.title;
      _descriptionController.text = assignment.description;
      _maxPointsController.text = assignment.maxPoints.toString();
      if (assignment.dueDate.isNotEmpty) {
        _dueDate = DateTime.parse(assignment.dueDate);
      }
    });

    // Set the course after course provider loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider =
          Provider.of<CourseProvider>(context, listen: false);

      // First make sure courses are loaded
      courseProvider.fetchEnrolledCourses().then((_) {
        if (courseProvider.enrolledCourses.isEmpty) {
          print("No courses available to select from");
          return;
        }

        // Try to find the course that matches this assignment
        // We need to call the backend to get courseId for this assignment
        final apiService = ApiService();
        apiService.getAssignmentDetails(assignment.id).then((response) {
          if (response['success'] && response['data'] != null) {
            final data = response['data'];
            final int? courseId = data['course'] is int
                ? data['course']
                : (data['courseId'] ?? 0);

            if (courseId != null && courseId > 0) {
              try {
                // Find course by ID
                final matchingCourse = courseProvider.enrolledCourses
                    .firstWhere((c) => c.id == courseId);
                setState(() {
                  _selectedCourse = matchingCourse;
                });
                return;
              } catch (e) {
                print('Course not found for ID $courseId: $e');
              }
            }
          }

          // Fallback: use first course
          setState(() {
            _selectedCourse = courseProvider.enrolledCourses.first;
          });
        }).catchError((e) {
          print('Error fetching assignment details: $e');
          // Fallback to first course
          setState(() {
            _selectedCourse = courseProvider.enrolledCourses.first;
          });
        });
      });
    });
  }

  void loadDraftIfAvailable() {
    final assignmentProvider =
        Provider.of<AssignmentProvider>(context, listen: false);

    if (assignmentProvider.hasDraft) {
      final draftData = assignmentProvider.localDraft;

      setState(() {
        _titleController.text = draftData['title'] ?? '';
        _descriptionController.text = draftData['description'] ?? '';
        _maxPointsController.text = (draftData['maxPoints'] ?? '').toString();
        if (draftData['dueDate'] != null) {
          _dueDate = DateTime.parse(draftData['dueDate']);
        }
        _selectedFiles = assignmentProvider.localDraftFiles;
        _loadedFromDraft = true;
      });

      // Set the selected course after course provider loads
      if (draftData['courseId'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final courseProvider =
              Provider.of<CourseProvider>(context, listen: false);
          try {
            _selectedCourse = courseProvider.enrolledCourses
                .firstWhere((course) => course.id == draftData['courseId']);
            setState(() {});
          } catch (e) {
            print('Course not found in enrolled courses');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);

    // Set the title based on the mode
    String screenTitle = 'Create Assignment';
    if (_isEditMode) {
      screenTitle = 'Edit Assignment';
    } else if (_loadedFromDraft) {
      screenTitle = 'Edit Draft Assignment';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle,style: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: MyAppColors.whiteColor
        ),
        ),
        backgroundColor: MyAppColors.primaryColor,
        iconTheme: const IconThemeData(
          color: MyAppColors.whiteColor
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<Course>(
                decoration: const InputDecoration(
                    labelText: 'Course',
                    labelStyle: TextStyle(
                      color: MyAppColors.primaryColor
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: MyAppColors.primaryColor
                      )
                    )
                ),
                isExpanded: true,
                value: _selectedCourse != null
                    ? courseProvider.enrolledCourses.firstWhere(
                        (course) => course.id == _selectedCourse!.id,
                        orElse: () => courseProvider.enrolledCourses.first)
                    : (_selectedCourse = courseProvider.enrolledCourses.first),
                items: courseProvider.enrolledCourses
                    .map((course) => DropdownMenuItem<Course>(
                          value: course,
                          child: Text(
                            course.courseName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ))
                    .toList(),
                onChanged: _isEditMode
                    ? null // Disable changing course in edit mode
                    : (course) {
                        setState(() {
                          _selectedCourse = course;
                        });
                      },
                validator: (val) =>
                    val == null ? 'Please select a course' : null,
              ),
              TextFormField(
                cursorColor: MyAppColors.primaryColor,
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(
                        color: MyAppColors.primaryColor
                    ),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: MyAppColors.primaryColor
                        )
                    )
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Title required' : null,
              ),
              TextFormField(
                cursorColor: MyAppColors.primaryColor,
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(
                        color: MyAppColors.primaryColor
                    ),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: MyAppColors.primaryColor
                        )
                    )
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Description required' : null,
                maxLines: 3,
              ),
              TextFormField(
                cursorColor: MyAppColors.primaryColor,
                controller: _maxPointsController,
                decoration: const InputDecoration(
                    labelText: 'Max Points',
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
                validator: (val) => val == null || int.tryParse(val) == null
                    ? 'Enter a valid number'
                    : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dueDate != null
                    ? 'Due: ${DateFormat.yMd().add_jm().format(_dueDate!)}'
                    : 'Select Due Date & Time'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
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
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
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
                        );
                      },
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _dueDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Attach Files'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: MyAppColors.primaryColor),
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(allowMultiple: true);
                  if (result != null) {
                    setState(() {
                      _selectedFiles = result.files;
                    });
                  }
                },
              ),
              if (_selectedFiles.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _selectedFiles
                      .map((f) => Chip(label: Text(f.name)))
                      .toList(),
                ),
              // Show existing files if in edit mode
              if (_isEditMode &&
                  _existingAssignment?.files != null &&
                  _existingAssignment!.files!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Current Files:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _existingAssignment!.files!
                      .map((f) => Chip(
                            label: Text(f.fileName),
                            backgroundColor: Colors.grey[200],
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              assignmentProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(
                color: MyAppColors.primaryColor,
              ))
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                final data = {
                                  'courseId': _selectedCourse!.id,
                                  'title': _titleController.text,
                                  'description': _descriptionController.text,
                                  'dueDate': _dueDate!.toIso8601String(),
                                  'maxPoints':
                                      int.tryParse(_maxPointsController.text) ??
                                          100,
                                };

                                Map<String, dynamic> result;

                                if (_isEditMode) {
                                  // We're editing an existing assignment
                                  result =
                                      await assignmentProvider.editAssignment(
                                          _existingAssignment!.id,
                                          data,
                                          _selectedFiles);
                                } else if (_loadedFromDraft) {
                                  // Clear draft and create assignment
                                  result = await assignmentProvider
                                      .createAssignment(data, _selectedFiles);
                                  assignmentProvider.clearLocalDraft();
                                } else {
                                  // Create new assignment
                                  result = await assignmentProvider
                                      .createAssignment(data, _selectedFiles);
                                }

                                if (result['success']) {
                                  Navigator.pop(context, true);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(result['message'] ??
                                            'Failed to save assignment')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyAppColors.primaryColor,
                            ),
                            child: Text(_isEditMode
                                ? 'Save Changes'
                                : (_loadedFromDraft
                                    ? 'Publish Assignment'
                                    : 'Create Assignment')),
                          ),
                        ),
                        if (!_isEditMode) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();

                                  // Save to local draft instead of sending to backend
                                  final data = {
                                    'courseId': _selectedCourse!.id,
                                    'title': _titleController.text,
                                    'description': _descriptionController.text,
                                    'dueDate': _dueDate!.toIso8601String(),
                                    'maxPoints': int.tryParse(
                                            _maxPointsController.text) ??
                                        100,
                                  };

                                  assignmentProvider.saveLocalDraft(
                                      data, _selectedFiles);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Draft saved locally'),
                                    ),
                                  );

                                  Navigator.pop(context, true);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: MyAppColors.primaryColor),
                              ),
                              child: const Text('Save as Draft',style: TextStyle(
                                color: MyAppColors.primaryColor
                              ),),
                            ),
                          ),
                        ],
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
