import 'package:flutter/material.dart';
import 'package:fci_edutrack/screens/admin/course_management_screen.dart';
import 'package:fci_edutrack/screens/admin/professor_requests_screen.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/auth/login_screen.dart'; // Added import
import 'package:provider/provider.dart'; // Import Provider

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
        title: const Text('Admin Dashboard',
            style: TextStyle(fontSize: 20)), // Adjust font size
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
      ),
      body: IndexedStack(
        // Use IndexedStack to keep state of screens
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
