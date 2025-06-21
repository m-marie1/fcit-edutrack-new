import 'package:flutter/material.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../../providers/attendance_provider.dart';
import '../../themes/theme_provider.dart'; // Import AttendanceProvider

class AttendanceRecordingScreen extends StatefulWidget {
  static const String routeName = 'attendance_recording';

  // Add required parameters
  final int courseId;
  final String courseName;
  final String courseCode;

  const AttendanceRecordingScreen({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    Key? key,
  }) : super(key: key);

  @override
  State<AttendanceRecordingScreen> createState() =>
      _AttendanceRecordingScreenState();
}

class _AttendanceRecordingScreenState extends State<AttendanceRecordingScreen> {
  bool _isLoadingApiCall = false;
  DateTime selectedDate = DateTime.now();
  final _expiryMinutesController = TextEditingController(text: '5'); // Default to 5 minutes
  final _topicController = TextEditingController();
  // Initialize controllers without default text here
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  // Store TimeOfDay for logic
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _initializeTimeControllers();
  }

  @override
  void dispose() {
    _expiryMinutesController.dispose();
    _topicController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _initializeTimeControllers() {
    final now = DateTime.now();
    // Default start time: previous hour sharp
    final defaultStartTime = DateTime(now.year, now.month, now.day, now.hour);
    // Default end time: start time + 90 minutes
    final defaultEndTime = defaultStartTime.add(const Duration(minutes: 90));

    _selectedStartTime = TimeOfDay.fromDateTime(defaultStartTime);
    _selectedEndTime = TimeOfDay.fromDateTime(defaultEndTime);

    // Format and set initial text for controllers
    final timeFormatter = DateFormat('h:mm a'); // e.g., 10:00 AM
    _startTimeController.text = timeFormatter.format(defaultStartTime);
    _endTimeController.text = timeFormatter.format(defaultEndTime);
  }

  // Removed _loadProfessorCourses method as course is passed via constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Record Attendance',
          style: TextStyle(
            fontSize: 20,
            color: MyAppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: MyAppColors.primaryColor),
      ),
      // Directly build the recorder, remove course selection logic
      body: _buildAttendanceRecorder(),
    );
  }

  // Removed _buildCourseSelection widget as course is passed via constructor

  Widget _buildAttendanceRecorder() {
    // Wrap with SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display Course Name - Use widget properties
          Text(
            '${widget.courseCode} - ${widget.courseName}', // Access via widget
            style: const TextStyle(
              fontSize: 20, // Increased size
              fontWeight: FontWeight.bold,
              color: MyAppColors.primaryColor, // Use theme color
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Date selector (Keep as is)
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.grey.shade400), // Lighter border
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(Icons.calendar_today, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Class Details Section
          const Text(
            'Class Details (Optional)', // Made optional
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            cursorColor: MyAppColors.primaryColor,
            controller: _topicController, // Use controller
            decoration: const InputDecoration(
              labelText: 'Topic Covered',
              labelStyle: TextStyle(
                color: MyAppColors.primaryColor
              ),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: MyAppColors.primaryColor
                )
              ),
              prefixIcon: Icon(Icons.subject),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startTimeController,
                  readOnly: true, // Make read-only
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    labelStyle: TextStyle(
                        color: MyAppColors.primaryColor
                    ),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: MyAppColors.primaryColor
                        )
                    ),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  onTap: _selectStartTime, // Add onTap handler
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _endTimeController,
                  readOnly: true, // Make read-only
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    labelStyle: TextStyle(
                        color: MyAppColors.primaryColor
                    ),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: MyAppColors.primaryColor
                        )
                    ),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  onTap: _selectEndTime, // Add onTap handler
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Spacing

          // Expiry Duration Input
          const Text(
            'Session Validity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            cursorColor: MyAppColors.primaryColor,
            controller: _expiryMinutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              labelStyle: TextStyle(
                  color: MyAppColors.primaryColor
              ),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: MyAppColors.primaryColor
                  )
              ),
              prefixIcon: Icon(Icons.timer),
              hintText: 'e.g., 5, 10, 15',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a duration';
              }
              final minutes = int.tryParse(value);
              if (minutes == null || minutes <= 0) {
                return 'Please enter a valid positive number';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),
          // Info Text (Keep as is)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align text better
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.blue, size: 20), // Slightly smaller icon
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Students will use the generated code to mark their attendance within the specified duration.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          // Use SizedBox instead of Spacer inside SingleChildScrollView
          const SizedBox(height: 24),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyAppColors.primaryColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 16), // More padding
                textStyle: const TextStyle(fontSize: 16), // Consistent style
              ),
              // Disable button while API call is in progress
              onPressed: _isLoadingApiCall ? null : _recordClass,
              child: _isLoadingApiCall
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text('Generate Verification Code'),
            ),
          ),
        ],
      ),
    ) // Closes Padding
  ); // Closes SingleChildScrollView
}

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Method to show time picker for Start Time
  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
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
    if (picked != null && picked != _selectedStartTime) {
      setState(() {
        _selectedStartTime = picked;
        // Update the text field
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        _startTimeController.text = DateFormat('h:mm a').format(dt);

        // Optional: Auto-adjust end time if needed, e.g., maintain 90 min duration
        // final newEndTime = dt.add(const Duration(minutes: 90));
        // _selectedEndTime = TimeOfDay.fromDateTime(newEndTime);
        // _endTimeController.text = DateFormat('h:mm a').format(newEndTime);
      });
    }
  }

  // Method to show time picker for End Time
  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
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
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
        // Update the text field
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        _endTimeController.text = DateFormat('h:mm a').format(dt);
      });
    }
  }

  // Updated _recordClass to call API
  Future<void> _recordClass() async {
    final expiryText = _expiryMinutesController.text;
    final expiryMinutes = int.tryParse(expiryText);

    if (expiryMinutes == null || expiryMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please enter a valid positive number for duration.')),
      );
      return;
    }

    setState(() {
      _isLoadingApiCall = true;
    });

    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context,
          listen: false); // Correct Provider usage
      final response = await attendanceProvider.createAttendanceSession(
          widget.courseId, expiryMinutes); // Access courseId via widget

      if (response['success'] && response['data'] != null) {
        final sessionData = response['data'];
        final verificationCode = sessionData['verificationCode'];
        final expiresAtString = sessionData['expiresAt']; // ISO 8601 format
        final expiresAt = DateTime.parse(expiresAtString);
        final formattedExpiry = DateFormat('h:mm a, MMM d').format(expiresAt);

        // Show success dialog with actual data
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
            title:  Text('Session Created',style: TextStyle(
               color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
            ),),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Verification Code for Student Attendance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 200,
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: MyAppColors.primaryColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      verificationCode ?? 'N/A', // Handle null code
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: MyAppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_off_outlined, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Expires at: $formattedExpiry', // Show actual expiry time
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Students must enter this code to record their attendance for this session.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close',style: TextStyle(
                  color: MyAppColors.primaryColor
                ),),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyAppColors.primaryColor,
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        // Show error message from API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to create session: ${response['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoadingApiCall = false;
      });
    }
  }
}
