import 'package:flutter/material.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/providers/attendance_provider.dart';
import 'package:fci_edutrack/screens/home_screen/my_bottom_nav_bar.dart'; // For navigation
import '../models/course_model.dart'; // Import Course model
import 'package:network_info_plus/network_info_plus.dart'; // Import for network info
import 'package:permission_handler/permission_handler.dart'; // Import for permissions
import 'dart:io' show Platform; // To check platform
import 'package:flutter/services.dart'; // For PlatformException
import 'package:shared_preferences/shared_preferences.dart'; // For reading target BSSID

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
  String _targetBSSID = '88:QQ:5L:9B:KS:4M'; // Default Target Wi-Fi MAC Address
  bool _isLoadingBSSID = false; // To manage loading state for BSSID setting
  bool _isCheckingNetwork = false; // To manage loading state for network check

  @override
  void initState() {
    super.initState();
    _loadTargetBSSID(); // Load custom BSSID on init
    _fetchEnrolledCourses();
  }

  // Load target BSSID from SharedPreferences
  Future<void> _loadTargetBSSID() async {
    setState(() => _isLoadingBSSID = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final customBSSID = prefs.getString('custom_target_bssid');
      if (customBSSID != null && customBSSID.isNotEmpty) {
        _targetBSSID = customBSSID;
      } else {
        // Use default if nothing is saved or it's empty
        _targetBSSID = '88:QQ:5L:9B:KS:4M';
      }
    } catch (e) {
      // Handle error loading preferences, maybe log it
      print("Error loading target BSSID: $e");
      _targetBSSID = '88:QQ:5L:9B:KS:4M'; // Fallback to default
    } finally {
      if (mounted) {
        setState(() => _isLoadingBSSID = false);
      }
    }
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
       appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.pin_outlined , size: 30, color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor,),
            Text(
                ' Record Attendance',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                )
            ),
          ],
        ),
      ),
      body: courseProvider.isLoading // Check loading state from CourseProvider
          ? const Center(child: CircularProgressIndicator(color: MyAppColors.primaryColor,))
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
    // Reload BSSID when refreshing the list as well
    final refreshAction = () async {
      await _loadTargetBSSID(); // Reload BSSID setting
      await Provider.of<CourseProvider>(context, listen: false)
          .ensureEnrolledCoursesFetched(); // Fetch courses
    };

    return RefreshIndicator(
      color: MyAppColors.primaryColor,
      onRefresh: refreshAction,
      child: _isLoadingBSSID // Show loading indicator while BSSID loads
          ? const Center(child: CircularProgressIndicator(
        color: MyAppColors.primaryColor,
      ))
          : ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  color: isDark?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          MyAppColors.primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.book_outlined,
                          color: MyAppColors.primaryColor),
                    ),
                    title: Text(course.courseName,style: TextStyle(
                      color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                    ),),
                    subtitle: Text(course.courseCode),
                    // Show indicator in trailing if checking this specific item (optional enhancement)
                    // For now, just disable tap globally
                    trailing: _isCheckingNetwork
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.keyboard_arrow_right,color: MyAppColors.darkBlueColor,),
                    onTap: _isCheckingNetwork // Disable tap while checking
                        ? null
                        : () {
                            // Check network before showing the code dialog
                            _checkNetworkAndProceed(
                                context, course, attendanceProvider);
                          },
                  ),
                );
              },
            ),
    );
  }

  // --- Permission Handling ---
  Future<bool> _requestLocationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Permissions likely not needed or handled differently on other platforms
      return true;
    }

    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      return true;
    }
    if (status.isDenied) {
      // Request permission
      status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        return true;
      }
    }

    // Handle permanently denied or restricted states
    if (status.isPermanentlyDenied || status.isRestricted) {
      // Show a dialog guiding the user to app settings
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
                'Location permission is needed to verify the Wi-Fi network. Please enable it in app settings.'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  openAppSettings(); // Opens app settings
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          ),
        );
      }
      return false;
    }
    return false; // Default case if not granted
  }

  // --- Network Check and Code Entry ---
  void _checkNetworkAndProceed(BuildContext context, Course course,
      AttendanceProvider attendanceProvider) async {
    if (_isCheckingNetwork) return; // Prevent concurrent checks

    setState(() {
      _isCheckingNetwork = true; // Start loading state
    });

    try {
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to check Wi-Fi.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {

        String? currentBSSID;
        String? errorMessage;

        try {
          final wifiName = await NetworkInfo().getWifiName();
          if (wifiName == null) {
            errorMessage = 'Wi-Fi is not connected or enabled.';
          } else {
            currentBSSID = await NetworkInfo().getWifiBSSID();
            if (currentBSSID == null) {
              errorMessage =
              'Could not retrieve Wi-Fi BSSID. Ensure location services are enabled.';
            }
          }
        } on PlatformException catch (e) {
          errorMessage =
          'Network check failed: ${e.message}. Ensure location services are enabled.';
        } catch (e) {
          errorMessage =
          'An unexpected error occurred while checking the network: ${e.toString()}';
        }

        if (errorMessage != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Normalize BSSIDs
          String normalizeBSSID(String? bssid) =>
              bssid?.toLowerCase().replaceAll(RegExp(r'[:-]'), '') ?? '';

          final normalizedTarget = normalizeBSSID(_targetBSSID);
          final normalizedCurrent = normalizeBSSID(currentBSSID);

          if (normalizedCurrent == normalizedTarget) {
            if (mounted) {
              _showCodeEntryDialog(context, course, attendanceProvider);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'You are not connected to the designated Wi-Fi network ($_targetBSSID). Current: ${currentBSSID ?? "Not Found"}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingNetwork = false;
        });
      }
    }
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
              backgroundColor: Provider.of<ThemeProvider>(context).isDark()? MyAppColors.secondaryDarkColor: MyAppColors.whiteColor,
              title: Text('Record Attendance for ${course.courseCode}',style: TextStyle(
                color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
              ),),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Prevent excessive height
                    children: [
                      const Text(
                          'Enter the 6-character code provided by your professor:'),
                      const SizedBox(height: 16),
                      TextFormField(
                        cursorColor: MyAppColors.primaryColor,
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Verification Code',
                          labelStyle: TextStyle(
                            color: MyAppColors.primaryColor
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MyAppColors.primaryColor
                            )
                          ),
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
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel',style: TextStyle(
                    color: MyAppColors.primaryColor
                  ),),
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
