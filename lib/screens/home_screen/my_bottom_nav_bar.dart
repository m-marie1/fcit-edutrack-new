import 'package:fci_edutrack/screens/home_screen/courses_screen.dart';
import 'package:fci_edutrack/screens/home_screen/drawer/my_drawer.dart';
import 'package:fci_edutrack/screens/home_screen/home_screen.dart';
import 'package:fci_edutrack/screens/home_screen/profiles/student_profile_screen.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/screens/admin/professor_requests_screen.dart';
import 'package:fci_edutrack/screens/admin/course_management_screen.dart';
import 'package:fci_edutrack/screens/professor/quiz_management_screen.dart';
// import 'package:fci_edutrack/screens/professor/attendance_recording_screen.dart'; // Will create a new one
import 'package:fci_edutrack/screens/register_attendance.dart'; // Import student attendance screen
import 'package:fci_edutrack/screens/assignment/assignment_screen.dart'; // Import assignment screen
import 'package:fci_edutrack/screens/professor/professor_attendance_management.dart'; // Import new professor attendance screen (will create)

class MyBottomNavBar extends StatefulWidget {
  static const String routeName = 'bottom_nav_bar';

  // Static reference to the current state
  static _MyBottomNavBarState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyBottomNavBarState>();
  }

  const MyBottomNavBar({super.key});

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  int selectedIndex = 0;
  DateTime? lastBackPressTime;
  // Remove internal state variables for role, read directly from provider in build
  // bool isAdmin = false;
  // bool isProfessor = false;
  // bool isLoading = true; // Loading state might still be useful if fetching data here

  // @override
  // void initState() {
  //   super.initState();
  //   // _checkUserRole(); // Don't check role here anymore
  // }

  // Future<void> _checkUserRole() async { ... } // Remove this method

  // Method to change the selected tab
  void changeTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read role directly from provider inside build
    final authProvider = Provider.of<AuthProvider>(context);
    // Use getters from AuthProvider which now correctly compare roles
    final bool isAdmin = authProvider.currentUser?.role?.toUpperCase() ==
        'ADMIN'; // Use normalized role
    final bool isProfessor = authProvider.currentUser?.role?.toUpperCase() ==
        'PROFESSOR'; // Use normalized role
    // Determine if still loading auth info
    final bool isLoading = authProvider.isLoading;
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press with double-back to exit behavior
        final now = DateTime.now();
        if (lastBackPressTime == null ||
            now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          // First back press, show toast
          lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true; // Allow app to exit
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: MyAppColors.primaryColor),
          title: isAdmin
              ? const Text('Admin Dashboard',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: MyAppColors.primaryColor))
              : isProfessor
                  ? const Text('Professor Dashboard',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: MyAppColors.primaryColor))
                  : null, // Title based on role
        ),
        drawer: const MyDrawer(),
        body: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator()) // Show loading if auth is loading
            : _getScreens(isAdmin, isProfessor)[
                selectedIndex], // Pass roles to getScreens
        backgroundColor: Provider.of<ThemeProvider>(context).isDark()
            ? MyAppColors.primaryDarkColor
            : MyAppColors.lightBackgroundColor,
        bottomNavigationBar: Container(
          color: MyAppColors.primaryColor,
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.01),
            child: GNav(
                onTabChange: (index) {
                  selectedIndex = index;
                  setState(() {});
                },
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.height * 0.02),
                backgroundColor: MyAppColors.primaryColor,
                color: Colors.white,
                activeColor: Colors.white,
                gap: 6,
                tabBackgroundColor: MyAppColors.secondaryBlueColor,
                tabs: _getNavTabs(
                    isAdmin, isProfessor)), // Pass roles to getNavTabs
          ),
        ),
      ),
    );
  }

  List<GButton> _getNavTabs(bool isAdmin, bool isProfessor) {
    // Accept roles as parameters
    if (isAdmin) {
      return const [
        GButton(
          icon: Icons.dashboard,
          text: 'Dashboard',
        ),
        GButton(
          icon: Icons.person_add,
          text: 'Requests',
        ),
        GButton(
          icon: Icons.school,
          text: 'Courses',
        ),
        GButton(
          icon: Icons.person,
          text: 'Profile',
        ),
      ];
    } else if (isProfessor) {
      // Updated Tabs for Professor
      return const [
        GButton(
          icon: Icons.school_outlined, // Or Icons.home_work_outlined
          text: 'Courses', // For enrollment/viewing
        ),
        GButton(
          icon: Icons.timer_outlined, // Or Icons.how_to_reg_outlined
          text: 'Attendance', // Manage Sessions & View History
        ),
        GButton(
          icon: Icons.quiz_outlined,
          text: 'Quizzes',
        ),
        GButton(
          icon: Icons.assignment_outlined,
          text: 'Assignments',
        ),
        GButton(
          icon: Icons.person_outline,
          text: 'Profile',
        ),
      ];
    } else {
      return const [
        GButton(
          icon: Icons.home,
          text: 'Home',
        ),
        GButton(
          icon: Icons.pin_outlined, // Changed icon to reflect code entry
          text: 'Attendance',
          textStyle: TextStyle(
            fontSize: 10,
            color: MyAppColors.whiteColor
          ),
        ),
        GButton(
          icon: Icons.school,
          text: 'Courses',
        ),
        GButton(
          icon: Icons.person,
          text: 'Profile',
        ),
      ];
    }
  }

  List<Widget> _getScreens(bool isAdmin, bool isProfessor) {
    // Accept roles as parameters
    if (isAdmin) {
      return [
        const HomeScreen(),
        const ProfessorRequestsScreen(),
        const CourseManagementScreen(),
        const StudentProfileScreen(),
      ];
    } else if (isProfessor) {
      // Updated Screens for Professor
      return [
        const CoursesScreen(), // Reuse for viewing/enrolling
        const ProfessorAttendanceManagementScreen(), // New screen for session mgmt (Create this next)
        const QuizManagementScreen(), // Existing placeholder
        const AssignmentScreen(), // Existing placeholder
        const StudentProfileScreen(), // Reuse student profile for now
      ];
    } else {
      return [
        const HomeScreen(),
        const RegisterAttendanceScreen(), // Use the updated code entry screen
        const CoursesScreen(),
        const StudentProfileScreen(),
      ];
    }
  }
}
