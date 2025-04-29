import 'package:flutter/material.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/providers/attendance_provider.dart';
import 'package:fci_edutrack/screens/home_screen/my_bottom_nav_bar.dart'; // For navigation
import '../models/course_model.dart'; // Import Course model

class RegisterAttendanceScreen extends StatefulWidget {
  static const String routeName = 'register_attendance_screen';

  const RegisterAttendanceScreen({super.key});

  @override
  State<RegisterAttendanceScreen> createState() =>
      _RegisterAttendanceScreenState();
}

class _RegisterAttendanceScreenState extends State<RegisterAttendanceScreen> {
  final bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _fetchEnrolledCourses();
  }

  void _fetchEnrolledCourses() {
    // Fetch enrolled courses from the provider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use listen: false here as we only need to trigger the fetch
      Provider.of<CourseProvider>(context, listen: false)
          .ensureEnrolledCoursesFetched();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark();
    // Listen to changes in CourseProvider to rebuild when courses are loaded
    final courseProvider = Provider.of<CourseProvider>(context);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    return Scaffold(
      backgroundColor:
          isDark ? MyAppColors.primaryDarkColor : MyAppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Record Attendance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
        ),
      ),
      body: courseProvider.isLoading // Check loading state from CourseProvider
          ? const Center(child: CircularProgressIndicator())
          : courseProvider.enrolledCourses.isEmpty
              ? _buildNoCourses(context, isDark) // Pass context
              : _buildCourseList(
                  context,
                  isDark,
                  courseProvider.enrolledCourses,
                  attendanceProvider), // Pass context and provider
    );
  }

  Widget _buildNoCourses(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
              'You are not enrolled in any courses yet.\nPlease enroll in courses first.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Browse Courses'),
              onPressed: () {
                // Navigate to the 'Courses' tab (index 2) in MyBottomNavBar
                final navBarState = MyBottomNavBar.of(context);
                if (navBarState != null) {
                  navBarState
                      .changeTab(2); // Index 2 corresponds to Courses tab
                } else {
                  // Fallback if not within MyBottomNavBar context
                  // This might happen if accessed directly, though unlikely
                  Navigator.pop(context); // Just pop the current screen
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyAppColors.primaryColor,
                foregroundColor: Colors.white, // Text color
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(BuildContext context, bool isDark,
      List<Course> courses, AttendanceProvider attendanceProvider) {
    return RefreshIndicator(
      onRefresh: () => Provider.of<CourseProvider>(context, listen: false)
          .ensureEnrolledCoursesFetched(),
      child: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: MyAppColors.primaryColor.withOpacity(0.1),
                child:
                    const Icon(Icons.book_outlined, color: MyAppColors.primaryColor),
              ),
              title: Text(course.courseName),
              subtitle: Text(course.courseCode),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {
                _showCodeEntryDialog(context, course, attendanceProvider);
              },
            ),
          );
        },
      ),
    );
  }

  void _showCodeEntryDialog(BuildContext context, Course course,
      AttendanceProvider attendanceProvider) {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? dialogError; // Error specific to the dialog

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage dialog's internal state (like error messages)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Record Attendance for ${course.courseCode}'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Prevent excessive height
                  children: [
                    const Text(
                        'Enter the 6-character code provided by your professor:'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                      ),
                      keyboardType: TextInputType.text,
                      maxLength: 6,
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the code';
                        }
                        if (value.trim().length != 6) {
                          return 'Code must be 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(dialogError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12)),
                    ]
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close the dialog
                  },
                ),
                ElevatedButton(
                  onPressed: attendanceProvider.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() {
                              // Update dialog state
                              dialogError = null; // Clear previous error
                              // Optionally show loading indicator inside dialog?
                            });

                            final response = await attendanceProvider
                                .recordAttendanceWithCode(
                              course.id,
                              codeController.text
                                  .trim()
                                  .toUpperCase(), // Send uppercase code
                            );

                            if (!dialogContext.mounted) {
                              return; // Check if dialog context is still valid
                            }

                            if (response['success']) {
                              Navigator.of(dialogContext)
                                  .pop(); // Close the dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(response['message'] ??
                                      'Attendance recorded successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setDialogState(() {
                                // Update dialog state with error
                                dialogError = response['message'] ??
                                    'Failed to record attendance.';
                              });
                            }
                          }
                        },
                  child: attendanceProvider.isLoading // Check loading state
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Removed _submitVerificationCode as logic is now in the dialog
  // Removed _buildQrCodeScanner and _buildScannerPrompt as they are no longer used
}
