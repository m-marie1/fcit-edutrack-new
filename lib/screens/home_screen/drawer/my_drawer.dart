import 'package:fci_edutrack/screens/assignment/assignment_screen.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/screens/admin/professor_requests_screen.dart';
import 'package:fci_edutrack/screens/admin/course_management_screen.dart';
import 'package:fci_edutrack/screens/professor/quiz_management_screen.dart';
import 'package:fci_edutrack/screens/professor/attendance_recording_screen.dart';
import 'package:fci_edutrack/screens/student/student_quiz_list_screen.dart'; // Import student quiz list screen

import '../../settings_screen.dart';
import 'drawer_tile.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Provider.of<ThemeProvider>(context).isDark()
          ? MyAppColors.primaryDarkColor
          : MyAppColors.lightBackgroundColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.width * 0.2,
          horizontal: MediaQuery.of(context).size.width * 0.03,
        ),
        child: Column(
          children: [
            // logo
            Icon(
              Icons.school_outlined,
              color: MyAppColors.primaryColor,
              size: MediaQuery.of(context).size.width * 0.26,
            ),
            Divider(
              color: Provider.of<ThemeProvider>(context).isDark()
                  ? MyAppColors.whiteColor
                  : MyAppColors.blackColor,
              thickness: 1.25,
            ),
            //Assignment
            MyDrawerTile(
                title: 'A S S I G N M E N T',
                icon: Icons.assignment,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AssignmentScreen.routeName);
                }),
            //quiz
            MyDrawerTile(
                title: 'Q U I Z',
                icon: Icons.lightbulb_outline,
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to Student Quiz List Screen
                  Navigator.pushNamed(context, StudentQuizListScreen.routeName);
                }),
            // settings
            MyDrawerTile(
                title: 'S E T T I N G S',
                icon: Icons.settings,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, SettingsScreen.routeName);
                }),

            // Admin section - only show for admin users
            FutureBuilder<bool>(
              future:
                  Provider.of<AuthProvider>(context, listen: false).isAdmin(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return Column(
                    children: [
                      Divider(
                        color: Provider.of<ThemeProvider>(context).isDark()
                            ? MyAppColors.whiteColor
                            : MyAppColors.blackColor,
                        thickness: 1.25,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Text(
                              'A D M I N',
                              style: TextStyle(
                                color: MyAppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Professor requests for admin
                      MyDrawerTile(
                        title: 'P R O F E S S O R  R E Q U E S T S',
                        icon: Icons.person_add,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            ProfessorRequestsScreen.routeName,
                          );
                        },
                      ),
                      // Course management for admin
                      MyDrawerTile(
                        title: 'C O U R S E  M A N A G E M E N T',
                        icon: Icons.school,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            CourseManagementScreen.routeName,
                          );
                        },
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Professor section - only show for professors
            FutureBuilder<bool>(
              future: Provider.of<AuthProvider>(context, listen: false)
                  .isProfessor(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return Column(
                    children: [
                      Divider(
                        color: Provider.of<ThemeProvider>(context).isDark()
                            ? MyAppColors.whiteColor
                            : MyAppColors.blackColor,
                        thickness: 1.25,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Text(
                              'P R O F E S S O R',
                              style: TextStyle(
                                color: MyAppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Create Quiz
                      MyDrawerTile(
                        title: 'M A N A G E  Q U I Z Z E S',
                        icon: Icons.quiz,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            QuizManagementScreen.routeName,
                          );
                        },
                      ),
                      // Record Class Attendance
                      MyDrawerTile(
                        title: 'R E C O R D  A T T E N D A N C E',
                        icon: Icons.class_,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AttendanceRecordingScreen.routeName,
                          );
                        },
                      ),
                      // Manage Assignments
                      MyDrawerTile(
                        title: 'M A N A G E  A S S I G N M E N T S',
                        icon: Icons.assignment,
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Assignment management coming soon!'),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const Spacer(),
            // logout
            // MyDrawerTile(
            //     title: 'L O G O U T',
            //     icon: Icons.logout,
            //     onTap: () async {
            //       Navigator.pop(context); // Close drawer first
            //
            //       // Show confirmation dialog
            //       final shouldLogout = await showDialog<bool>(
            //         context: context,
            //         builder: (context) => AlertDialog(
            //           title: const Text('Log Out'),
            //           content: const Text('Are you sure you want to log out?'),
            //           actions: [
            //             TextButton(
            //               onPressed: () => Navigator.of(context).pop(false),
            //               child: const Text('Cancel'),
            //             ),
            //             TextButton(
            //               onPressed: () => Navigator.of(context).pop(true),
            //               child: const Text('Log Out'),
            //             ),
            //           ],
            //         ),
            //       );
            //
            //       if (shouldLogout == true) {
            //         final authProvider =
            //             Provider.of<AuthProvider>(context, listen: false);
            //         await authProvider.logout();
            //         // No explicit navigation needed here.
            //         // AuthWrapper will handle navigating to LoginScreen
            //         // when it detects the user is logged out after logout() completes.
            //       }
            //     }),
          ],
        ),
      ),
    );
  }
}
