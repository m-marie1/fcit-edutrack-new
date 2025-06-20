import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// For potential future use
import 'dart:io'; // For file operations
import 'dart:typed_data'; // For Uint8List
import 'package:fci_edutrack/models/course_model.dart';
import 'package:fci_edutrack/providers/attendance_provider.dart'; // Import AttendanceProvider
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/screens/professor/attendance_recording_screen.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:path_provider/path_provider.dart'; // For file path
import 'package:open_file/open_file.dart';

import '../../themes/theme_provider.dart'; // To open the downloaded file
// TODO: Import the screen containing the main course list if needed for "Browse Courses"
// TODO: Import or create screen/widget for displaying attendees

class ProfessorAttendanceManagementScreen extends StatefulWidget {
  const ProfessorAttendanceManagementScreen({super.key});

  @override
  State<ProfessorAttendanceManagementScreen> createState() =>
      _ProfessorAttendanceManagementScreenState();
}

class _ProfessorAttendanceManagementScreenState
    extends State<ProfessorAttendanceManagementScreen> {
  // Removed local loading/error/success states, will rely on Provider
  // bool _isLoading = false;
  // String? _successMessage;
  DateTime? _selectedReportDate; // For daily report date picker
  Course? _selectedCourseForReport; // For selecting course in report sections
  bool _isDownloading = false; // Loading indicator for download

  @override
  void initState() {
    super.initState();
    // Fetch initial data needed for the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    // Fetch enrolled courses and active sessions simultaneously
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    // Use Future.wait for parallel fetching
    await Future.wait([
      courseProvider.fetchEnrolledCourses(),
      attendanceProvider.fetchActiveSessions(), // Fetch active sessions too
    ]);
    // Set default selected course for reports if courses exist
    if (courseProvider.enrolledCourses.isNotEmpty) {
      setState(() {
        _selectedCourseForReport = courseProvider.enrolledCourses.first;
      });
    }
  }

  // Refreshes data and validates selected course
  Future<void> _refreshData() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    // Store the ID of the currently selected course, if any
    final selectedCourseId = _selectedCourseForReport?.id;

    // Fetch new data
    await Future.wait([
      courseProvider.fetchEnrolledCourses(),
      attendanceProvider.fetchActiveSessions(),
    ]);

    // After fetching, find the course in the new list that matches the old ID
    Course? potentiallyStaleSelectedCourse = _selectedCourseForReport;
    Course? newSelectedCourseInstance;
    if (selectedCourseId != null && courseProvider.enrolledCourses.isNotEmpty) {
      try {
        newSelectedCourseInstance = courseProvider.enrolledCourses
            .firstWhere((course) => course.id == selectedCourseId);
      } catch (e) {
        // The previously selected course ID is no longer in the list
        newSelectedCourseInstance = null;
        print(
            "Previously selected course (ID: $selectedCourseId) not found after refresh.");
      }
    }

    // Update the state
    // Use the new instance if found, otherwise default to the first course or null
    setState(() {
      if (newSelectedCourseInstance != null) {
        _selectedCourseForReport = newSelectedCourseInstance;
      } else if (courseProvider.enrolledCourses.isNotEmpty) {
        // If the old selection is invalid or wasn't set, default to the first
        if (potentiallyStaleSelectedCourse != null) {
          print(
              "Resetting selected course as previous selection is no longer valid.");
        }
        _selectedCourseForReport = courseProvider.enrolledCourses.first;
      } else {
        // No courses available
        _selectedCourseForReport = null;
      }
    });
  }

  // Removed placeholder methods for create/fetch/view/download as they are not needed here

  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<ThemeProvider>(context).isDark();
    // Use multiple Consumers or nested Consumers if needed, or read providers directly in build methods
    return Scaffold(
      // AppBar might be handled by MyBottomNavBar, or add one here if needed
      body: RefreshIndicator(
        color: MyAppColors.primaryColor,
        onRefresh: _refreshData, // Use combined refresh method
        child: ListView(
          // Changed to ListView to accommodate multiple sections
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              children: [
                 Icon(Icons.timer_outlined,size: 30,color: isDark? MyAppColors.primaryColor:MyAppColors.darkBlueColor,),
                Text(' Attendance Management',style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                ),),

              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.03,
            ),
            // Section 1: Select Course to Create Session
            Text(
              '1. Create Attendance Session',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0, // Adjusted font size
                  color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                  ),
            ),
            const SizedBox(height: 8),
            Consumer<CourseProvider>(
              builder: (context, courseProvider, child) {
                // Use the original name here
                return _buildCourseListForSessionCreation(courseProvider);
              },
            ),
            const Divider(height: 32, thickness: 1),

            // Section 2: View Active Sessions
            Text(
              '2. Active Sessions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0, // Adjusted font size
                color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                  ),
            ),
            const SizedBox(height: 8),
            Consumer<AttendanceProvider>(
              builder: (context, attendanceProvider, child) {
                return _buildActiveSessionsList(attendanceProvider);
              },
            ),
            const Divider(height: 32, thickness: 1),

            // Section 3: Daily Reports
            Text(
              '3. Daily Attendance Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0, // Adjusted font size
                   color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                  ),
            ),
            const SizedBox(height: 8),
            // Need CourseProvider for dropdown
            Consumer<CourseProvider>(builder: (context, courseProvider, child) {
              return _buildDailyReportsSection(courseProvider);
            }),
            const Divider(height: 32, thickness: 1),

            // Section 4: Download Reports
            Text(
              '4. Download Full Report (CSV)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0, // Adjusted font size
                   color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                  ),
            ),
            const SizedBox(height: 8),
            // Need CourseProvider for dropdown
            Consumer<CourseProvider>(builder: (context, courseProvider, child) {
              return _buildDownloadReportsSection(courseProvider);
            }),
          ],
        ),
      ),
    );
  }

  // Renamed: Builds the list for selecting a course to create a session
  Widget _buildCourseListForSessionCreation(CourseProvider courseProvider) {
    if (courseProvider.isLoading && courseProvider.enrolledCourses.isEmpty) {
      // Show loading only if courses haven't been loaded yet
      return const Center(
          child: CircularProgressIndicator(
        color: MyAppColors.primaryColor,
      ));
    }

    final enrolledCourses = courseProvider.enrolledCourses;

    if (enrolledCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You must be enrolled in a course to create an attendance session.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement navigation to the main course browsing screen
                print("Navigate to Browse Courses");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Navigation to Browse Courses not implemented yet.')),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Browse Courses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyAppColors.secondaryBlueColor,
              ),
            ),
          ],
        ),
      );
    }

    // Limit height if needed, or let ListView handle scrolling within its parent constraints
    return Column(
      // Use Column instead of ListView directly if parent is already scrollable
      children: enrolledCourses.map((course) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(20)
          ),
          color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,

          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            title: Text(
              '${course.courseCode} - ${course.courseName}',
              style:  TextStyle(fontWeight: FontWeight.bold,
                  color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.blackColor ),
            ),
            subtitle: Text(
              course.description ?? 'No description',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: MyAppColors.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 14)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendanceRecordingScreen(
                      courseId: course.id,
                      courseName: course.courseName,
                      courseCode: course.courseCode,
                    ),
                  ),
                );
              },
              child: const Text('Create Session'),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Widget to display list of active sessions
  Widget _buildActiveSessionsList(AttendanceProvider attendanceProvider) {
    if (attendanceProvider.isLoading &&
        attendanceProvider.activeSessions.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(
        color: MyAppColors.primaryColor,
      ));
    }
    if (attendanceProvider.activeSessions.isEmpty) {
      return const Center(child: Text('No active sessions found.'));
    }

    return Column(
      children: attendanceProvider.activeSessions.map((session) {
        final expiresAt = DateTime.parse(session['expiresAt']);
        final formattedExpiry = DateFormat('h:mm a, MMM d').format(expiresAt);
        final bool isExpired = DateTime.now().isAfter(expiresAt);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          color: isExpired ? Provider.of<ThemeProvider>(context).isDark()?Colors.grey.shade800:Colors.grey.shade300 : null,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              '${session['courseCode']} - ${session['courseName']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpired ? Colors.grey.shade700 : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: ${session['verificationCode']}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isExpired
                            ? Colors.grey.shade700
                            : Theme.of(context).primaryColor)),
                const SizedBox(height: 4),
                Text('Expires: $formattedExpiry',
                    style: TextStyle(
                        color: isExpired ? Colors.grey.shade700 : null)),
              ],
            ),
            trailing: TextButton(
              onPressed: isExpired
                  ? null
                  : () => _viewSessionAttendees(session['sessionId']),
              child: Text(isExpired ? 'Expired' : 'View Attendees'),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Widget for Daily Reports Section
  Widget _buildDailyReportsSection(CourseProvider courseProvider) {
    final enrolledCourses = courseProvider.enrolledCourses;
    if (enrolledCourses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text("No courses available"),
        ),
      );
    }

    // Initialize selected course if needed
    if (_selectedCourseForReport == null && enrolledCourses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedCourseForReport = enrolledCourses.first;
        });
      });
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text("Loading courses..."),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(20)
      ),
      color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Dropdown
            DropdownButtonFormField<Course>(
              dropdownColor: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
              // Use ID-based comparison to find the matching course
              value: _selectedCourseForReport != null
                  ? enrolledCourses.firstWhere(
                      (c) => c.id == _selectedCourseForReport!.id,
                      orElse: () => enrolledCourses.first)
                  : null,
              items: enrolledCourses.map((Course course) {
                return DropdownMenuItem<Course>(
                  value: course,
                  child: Text(
                    '${course.courseCode} - ${course.courseName}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                    ),
                  ),
                );
              }).toList(),
              onChanged: (Course? newValue) {
                setState(() {
                  _selectedCourseForReport = newValue;
                });
              },
              decoration:  const InputDecoration(
                labelText: 'Select Course',
                labelStyle: TextStyle(
                  color: MyAppColors.primaryColor
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: MyAppColors.primaryColor
                  )
                ),
              ),
              isExpanded: true,
            ),
            const SizedBox(height: 16),
            // Date Picker
            ListTile(
              title: Text(_selectedReportDate == null
                  ? 'Select Date'
                  : 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedReportDate!)}',
                  style: TextStyle(
                    color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.darkBlueColor
                  ),),
              trailing:  Icon(Icons.calendar_today,color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.darkBlueColor,),
              onTap: _pickReportDate,
            ),
            const SizedBox(height: 16),
            // View Button
            Center(
              child: ElevatedButton.icon(
                onPressed: (_selectedCourseForReport == null ||
                        _selectedReportDate == null)
                    ? null
                    : _viewDailyAttendees,
                icon: const Icon(Icons.people_alt_outlined,color: Colors.grey,),
                label:  const Text('View Daily Attendees',
                  style: TextStyle(
                      color:Colors.grey
                  ),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for Download Reports Section
  Widget _buildDownloadReportsSection(CourseProvider courseProvider) {
    final enrolledCourses = courseProvider.enrolledCourses;
    if (enrolledCourses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text("No courses available"),
        ),
      );
    }

    // Initialize selected course if needed
    if (_selectedCourseForReport == null && enrolledCourses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedCourseForReport = enrolledCourses.first;
        });
      });
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text("Loading courses..."),
      );
    }

    return Card(

      color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(20)
      ),

      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Dropdown (similar to daily reports)
            DropdownButtonFormField<Course>(
              dropdownColor: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
              // Use ID-based comparison to find the matching course
              value: _selectedCourseForReport != null
                  ? enrolledCourses.firstWhere(
                      (c) => c.id == _selectedCourseForReport!.id,
                      orElse: () => enrolledCourses.first)
                  : null,
              items: enrolledCourses.map((Course course) {
                return DropdownMenuItem<Course>(
                  value: course,
                  child: Text(
                    '${course.courseCode} - ${course.courseName}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                    ),
                  ),
                );
              }).toList(),
              onChanged: (Course? newValue) {
                setState(() {
                  _selectedCourseForReport = newValue;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Select Course',
                labelStyle: TextStyle(
                  color: MyAppColors.primaryColor
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: MyAppColors.primaryColor
                  )
                ),
              ),
              isExpanded: true,
            ),
            const SizedBox(height: 16),
            // Download Button
            Center(
              child: ElevatedButton.icon(
                onPressed: (_selectedCourseForReport == null || _isDownloading)
                    ? null
                    : _downloadSpreadsheet,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MyAppColors.primaryColor,
                        ),
                      )
                    : const Icon(Icons.download_outlined),
                label: Text(_isDownloading
                    ? 'Downloading...'
                    : 'Download Spreadsheet (CSV)'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: MyAppColors.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods for Actions ---

  Future<void> _viewSessionAttendees(int sessionId) async {
    print("View attendees for session $sessionId");
    final provider = Provider.of<AttendanceProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await provider.fetchSessionAttendees(sessionId);

    Navigator.pop(context); // Close loading dialog

    // Check if context is still mounted before showing the next dialog
    if (!mounted) return;

    final attendees = provider.getAttendeesForSession(sessionId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attendees for Session $sessionId'),
        content: SizedBox(
          width: double.maxFinite,
          child: attendees.isEmpty
              ? const Text('No attendees found for this session.')
              : ListView.builder(
                  shrinkWrap: true, // Important for AlertDialog content
                  itemCount: attendees.length,
                  itemBuilder: (context, index) {
                    final attendee = attendees[index];
                    return ListTile(
                      leading: const Icon(Icons.person_outline), // Add an icon
                      title: Text(attendee['fullName'] ?? 'N/A'),
                      subtitle: Text(attendee['username'] ?? 'N/A'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReportDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReportDate ?? DateTime.now(),
      firstDate: DateTime(2020), // Adjust as needed
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _selectedReportDate) {
      setState(() {
        _selectedReportDate = picked;
      });
    }
  }

  Future<void> _viewDailyAttendees() async {
    if (_selectedCourseForReport == null || _selectedReportDate == null) return;
    final courseId = _selectedCourseForReport!.id;
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedReportDate!);
    print("View daily attendees for course $courseId on $dateString");

    final provider = Provider.of<AttendanceProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(
        color: MyAppColors.primaryColor,
      )),
    );

    await provider.fetchDailyAttendees(courseId, dateString);

    Navigator.pop(context); // Close loading dialog

    // Check if context is still mounted
    if (!mounted) return;

    final attendees = provider.getAttendeesForDay(courseId, dateString);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
        title: Text(
            'Attendees for ${DateFormat('MMM d, yyyy').format(_selectedReportDate!)}',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
          ),),
        content: SizedBox(
          width: double.maxFinite,
          child: attendees.isEmpty
              ? const Text('No attendees found for this date.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: attendees.length,
                  itemBuilder: (context, index) {
                    final attendee = attendees[index];
                    return ListTile(
                      leading:  Icon(
                          Icons.person_pin_circle_outlined,color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.darkBlueColor,), // Different icon
                      title: Text(attendee['fullName'] ?? 'N/A',style: TextStyle(
                        color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                      ),),
                      subtitle: Text(attendee['username'] ?? 'N/A',style: TextStyle(
                        color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.blackColor
                      ),),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: MyAppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadSpreadsheet() async {
    if (_selectedCourseForReport == null) return;
    final courseId = _selectedCourseForReport!.id;
    print("Downloading spreadsheet for course $courseId");

    setState(() => _isDownloading = true);

    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final response =
          await attendanceProvider.downloadAttendanceSpreadsheet(courseId);

      if (response['success'] && response['bytes'] != null) {
        final bytes = response['bytes'] as Uint8List;
        final filename = response['filename'] ??
            'attendance-course-$courseId-${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

        // Get temporary directory
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$filename';

        // Write the file
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        print('Spreadsheet saved to: $filePath');

        // Open the file
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          print('Error opening file: ${result.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: ${result.message}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Spreadsheet downloaded: $filename')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Download failed: ${response['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during download: $e')),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }
}
