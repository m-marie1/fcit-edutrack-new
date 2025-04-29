import 'package:fci_edutrack/models/course_model.dart';
import 'package:fci_edutrack/providers/attendance_provider.dart';
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/screens/home_screen/my_bottom_nav_bar.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({Key? key}) : super(key: key);

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Fetch enrolled courses when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false)
          .fetchEnrolledCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark();
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      backgroundColor:
          isDark ? MyAppColors.primaryDarkColor : MyAppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Record Attendance',
          style: TextStyle(
            fontSize: 20,
            color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Courses in Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap on a course to record your attendance',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // Error and success messages
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),

            // List of enrolled courses
            Expanded(
              child: courseProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : courseProvider.enrolledCourses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No classes taking place right now',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  // Switch to the courses tab
                                  final navBarState =
                                      MyBottomNavBar.of(context);
                                  if (navBarState != null) {
                                    navBarState.changeTab(
                                        2); // Index 2 for Courses tab
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyAppColors.primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: const Text('Browse Courses'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: courseProvider.enrolledCourses.length,
                          itemBuilder: (context, index) {
                            final course =
                                courseProvider.enrolledCourses[index];
                            return CourseAttendanceCard(
                              course: course,
                              onRecordAttendance: () =>
                                  _recordAttendance(course),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordAttendance(Course course) async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    try {
      final result = await attendanceProvider.recordAttendance(course.id);

      if (result['success']) {
        setState(() {
          _successMessage =
              'Attendance recorded successfully for ${course.courseName}';
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to record attendance';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }
}

class CourseAttendanceCard extends StatelessWidget {
  final Course course;
  final VoidCallback onRecordAttendance;

  const CourseAttendanceCard({
    Key? key,
    required this.course,
    required this.onRecordAttendance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: isDark ? MyAppColors.darkCardColor : Colors.white,
      child: InkWell(
        onTap: onRecordAttendance,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: MyAppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: MyAppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.courseCode,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.how_to_reg,
                color: MyAppColors.primaryColor,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
