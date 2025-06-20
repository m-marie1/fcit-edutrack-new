import 'package:fci_edutrack/screens/home_screen/profiles/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:fci_edutrack/screens/professor/professor_attendance_management.dart'; // Import the correct screen
import 'package:fci_edutrack/screens/professor/quiz_management_screen.dart'; // Placeholder for quiz management
import 'package:fci_edutrack/screens/assignment/assignment_screen.dart'; // Placeholder for assignment management
import 'package:fci_edutrack/screens/home_screen/courses_screen.dart'; // For enrolling/viewing courses
import 'package:fci_edutrack/providers/auth_provider.dart'; // Import AuthProvider
import 'package:provider/provider.dart'; // Import Provider
import 'package:fci_edutrack/auth/login_screen.dart';

import '../../style/my_app_colors.dart'; // Import LoginScreen for navigation

// TODO: Implement actual screens for professor features

class ProfessorHomeScreen extends StatefulWidget {
  static const String routeName = 'professor_home_screen';

  const ProfessorHomeScreen({super.key});

  @override
  State<ProfessorHomeScreen> createState() => _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends State<ProfessorHomeScreen> {
  int _selectedIndex = 0;

  // Define the screens for the professor
  // Replace placeholders with actual implemented screens later
  final List<Widget> _screens = [
    const CoursesScreen(), // For enrolling/viewing courses
    const ProfessorAttendanceManagementScreen(), // Use the management screen here
    const QuizManagementScreen(), // Placeholder for quizzes
    const AssignmentScreen(), // Placeholder for assignments
    const StudentProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.school_outlined), // Changed icon
      label: 'Courses',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.timer_outlined), // Changed icon
      label: 'Attendance',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.quiz_outlined), // Changed icon
      label: 'Quizzes',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assignment_outlined), // Changed icon
      label: 'Assignments',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person), // Changed icon
      label: 'Profile',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false); // Get AuthProvider

    return Scaffold(
      appBar: AppBar(
        title:  Text('Professor Dashboard',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: MyAppColors.whiteColor
            )), // Adjust font size
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft:
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
            bottomRight:
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
        ),
        backgroundColor: MyAppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout,color: Colors.white,),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              // Navigate back to login screen after logout
              Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginScreen.routeName, // Use LoginScreen.routeName
                  (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
      body: IndexedStack(
        // Use IndexedStack to keep state of screens
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: MyAppColors.whiteColor,
        selectedIconTheme: const IconThemeData(
          size: 27
        ),
        unselectedIconTheme: const IconThemeData(
            size: 17
        ),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: MyAppColors.primaryColor,
        type: BottomNavigationBarType.fixed, // Ensure all labels are visible
      ),
    );
  }
}
