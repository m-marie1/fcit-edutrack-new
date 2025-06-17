import 'package:flutter/material.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/services/api_service.dart';
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/models/course_model.dart';

class CourseManagementScreen extends StatefulWidget {
  static const String routeName = 'admin_course_management';

  const CourseManagementScreen({Key? key}) : super(key: key);

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Course> _courses = [];

  // Controllers for the form fields
  final _formKey = GlobalKey<FormState>();
  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  // Selected days
  final List<String> _availableDays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY'
  ];
  final List<String> _selectedDays = [];

  // Edit mode
  bool _isEditMode = false;
  int? _editingCourseId;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courseProvider =
          Provider.of<CourseProvider>(context, listen: false);
      await courseProvider.fetchCourses();

      setState(() {
        _courses = courseProvider.courses;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load courses: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _courseCodeController.clear();
    _courseNameController.clear();
    _descriptionController.clear();
    _startTimeController.clear();
    _endTimeController.clear();
    _selectedDays.clear();
    _isEditMode = false;
    _editingCourseId = null;
  }

  Future<void> _createOrUpdateCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one day of the week')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> courseData = {
        'courseCode': _courseCodeController.text,
        'courseName': _courseNameController.text,
        'description': _descriptionController.text,
        'startTime': _startTimeController.text,
        'endTime': _endTimeController.text,
        'days': _selectedDays,
      };

      Map<String, dynamic> response;

      if (_isEditMode && _editingCourseId != null) {
        // Update existing course
        response =
            await _apiService.updateCourse(_editingCourseId!, courseData);
      } else {
        // Create new course
        response = await _apiService.createCourse(courseData);
      }

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Course updated successfully'
                : 'Course created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _resetForm();
        _fetchCourses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to save course'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editCourse(Course course) {
    setState(() {
      _isEditMode = true;
      _editingCourseId = course.id;
      _courseCodeController.text = course.courseCode;
      _courseNameController.text = course.courseName;
      _descriptionController.text = course.description ?? '';
      _startTimeController.text = course.startTime ?? '00:00:00';
      _endTimeController.text = course.endTime ?? '00:00:00';
      _selectedDays.clear();
      _selectedDays.addAll(course.days ?? []);
    });

    // Scroll to the form
    Future.delayed(Duration.zero, () {
      Scrollable.ensureVisible(
        _formKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        alignment: 0.0,
      );
    });
  }

  Future<void> _deleteCourse(int courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this course? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',style: TextStyle(
              color: MyAppColors.primaryColor
            ),),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.deleteCourse(courseId);

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _fetchCourses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to delete course'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

    if (selectedTime != null) {
      final String formattedTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
      controller.text = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Course Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? MyAppColors.whiteColor : MyAppColors.primaryColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: MyAppColors.primaryColor,),
            onPressed: _fetchCourses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
        color: MyAppColors.primaryColor,
      ))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchCourses,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course creation/editing form
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: isDark
                            ? MyAppColors.secondaryDarkColor
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditMode
                                      ? 'Edit Course'
                                      : 'Create New Course',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : MyAppColors.darkBlueColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Course Code
                                TextFormField(
                                  controller: _courseCodeController,
                                  cursorColor: MyAppColors.primaryColor,
                                  decoration: InputDecoration(
                                    labelText: 'Course Code',
                                    labelStyle: const TextStyle(
                                        color: MyAppColors.darkBlueColor
                                    ),
                                    hintText: 'e.g., CS101',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: MyAppColors.primaryColor,
                                        width: 2
                                      )
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: MyAppColors.darkBlueColor,
                                            width: 2
                                        )
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a course code';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Course Name
                                TextFormField(
                                  cursorColor: MyAppColors.primaryColor,
                                  controller: _courseNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Course Name',
                                    labelStyle:  const TextStyle(
                                        color: MyAppColors.darkBlueColor
                                    ),
                                    hintText:
                                        'e.g., Introduction to Computer Science',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: MyAppColors.primaryColor,
                                            width: 2
                                        )
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: MyAppColors.darkBlueColor,
                                            width: 2
                                        )
                                    ),),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a course name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Description
                                TextFormField(
                                  cursorColor: MyAppColors.primaryColor,
                                  controller: _descriptionController,
                                  decoration: InputDecoration(
                                    labelText: 'Description',
                                    labelStyle: const TextStyle(
                                        color: MyAppColors.darkBlueColor
                                    ),
                                    hintText: 'Course description',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: MyAppColors.primaryColor,
                                            width: 2
                                        )
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: MyAppColors.darkBlueColor,
                                            width: 2
                                        )
                                    ),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                // Start Time
                                TextFormField(
                                  controller: _startTimeController,
                                  decoration: InputDecoration(
                                    labelText: 'Start Time',
                                    labelStyle: const TextStyle(
                                        color: MyAppColors.darkBlueColor
                                    ),
                                    hintText: '09:00:00',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: MyAppColors.primaryColor,
                                            width: 2
                                        )
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: MyAppColors.darkBlueColor,
                                            width: 2
                                        )
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.access_time),
                                      onPressed: () => _selectTime(
                                          context, _startTimeController),
                                    ),
                                  ),
                                  readOnly: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a start time';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // End Time
                                TextFormField(
                                  controller: _endTimeController,
                                  decoration: InputDecoration(
                                    labelText: 'End Time',
                                    labelStyle: const TextStyle(
                                        color: MyAppColors.darkBlueColor
                                    ),
                                    hintText: '10:30:00',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: MyAppColors.primaryColor,
                                            width: 2
                                        )
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: MyAppColors.darkBlueColor,
                                            width: 2
                                        )
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.access_time),
                                      onPressed: () => _selectTime(
                                          context, _endTimeController),
                                    ),
                                  ),
                                  readOnly: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select an end time';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Days of the week
                                Text(
                                  'Days of the Week',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        isDark ? Colors.white : MyAppColors.darkBlueColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: _availableDays
                                      .map((day) => FilterChip(
                                            label: Text(day),
                                            selected:
                                                _selectedDays.contains(day),
                                            onSelected: (selected) {
                                              setState(() {
                                                if (selected) {
                                                  _selectedDays.add(day);
                                                } else {
                                                  _selectedDays.remove(day);
                                                }
                                              });
                                            },
                                            backgroundColor: isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade200,
                                            selectedColor:
                                                MyAppColors.primaryColor,
                                            checkmarkColor: Colors.white,
                                            labelStyle: TextStyle(
                                              color: _selectedDays.contains(day)
                                                  ? Colors.white
                                                  : (isDark
                                                      ? Colors.white
                                                      : Colors.black87),
                                            ),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 24),
                                // Submit button
                                Row(
                                  children: [
                                    if (_isEditMode)
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _resetForm,
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                          ),
                                          child: const Text('Cancel',style: TextStyle(
                                            color: MyAppColors.primaryColor
                                          ),),
                                        ),
                                      ),
                                    if (_isEditMode) const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _createOrUpdateCourse,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              MyAppColors.primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                        child: Text(_isEditMode
                                            ? 'Update Course'
                                            : 'Create Course'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Course list
                      Text(
                        'Existing Courses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? MyAppColors.whiteColor
                              : MyAppColors.darkBlueColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _courses.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.school_outlined,
                                      size: 64,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No courses found',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade700,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _courses.length,
                              itemBuilder: (context, index) {
                                final course = _courses[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  color: isDark
                                      ? MyAppColors.secondaryDarkColor
                                      : Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    course.courseName,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDark
                                                          ? Colors.white
                                                          : MyAppColors.darkBlueColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    course.courseCode,
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? Colors.grey.shade400
                                                          : Colors
                                                              .grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,color: MyAppColors.primaryColor,),
                                                  onPressed: () =>
                                                      _editCourse(course),
                                                  tooltip: 'Edit',
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black54,
                                                ),
                                                IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () =>
                                                      _deleteCourse(course.id),
                                                  tooltip: 'Delete',
                                                  color: Colors.red,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (course.description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            course.description,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: isDark
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${course.startTime ?? 'N/A'} - ${course.endTime ?? 'N/A'}',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 4,
                                          children: (course.days ?? [])
                                              .map((day) => Chip(
                                                    label: Text(
                                                      day,
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                    backgroundColor: isDark
                                                        ? Colors.grey.shade800
                                                        : Colors.grey.shade200,
                                                    padding: EdgeInsets.zero,
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}
