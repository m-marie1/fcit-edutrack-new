import 'package:fci_edutrack/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:fci_edutrack/screens/admin/course_management_screen.dart';
import 'package:fci_edutrack/screens/admin/professor_requests_screen.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/auth/login_screen.dart'; // Added import
import 'package:provider/provider.dart';

import '../../style/my_app_colors.dart'; // Import Provider

class AdminHomeScreen extends StatefulWidget {
  static const String routeName = 'admin_home_screen';

  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CourseManagementScreen(),
    const ProfessorRequestsScreen(),
    const SettingsScreen(),
    // Add other admin screens here if needed
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.school),
      label: 'Courses',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_search),
      label: 'Requests',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
    // Add other admin nav items here
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
        title:  Text('Admin Dashboard',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: MyAppColors.whiteColor
            )), // Adjust font size
        actions: [
          IconButton(
            icon: const Icon(Icons.logout,color: MyAppColors.whiteColor,),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              // Navigate back to login screen after logout
              Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginScreen.routeName, // Use the correct route name
                  (Route<dynamic> route) => false);
            },
          ),
        ],
        elevation: 0,
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
      ),
      body: IndexedStack(
        // Use IndexedStack to keep state of screens
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        backgroundColor: MyAppColors.primaryColor,
        currentIndex: _selectedIndex,
        selectedItemColor: MyAppColors.whiteColor,
        unselectedItemColor: MyAppColors.greyColor,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
      ),
    );
  }
}
