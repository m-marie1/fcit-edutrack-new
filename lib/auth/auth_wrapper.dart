import 'package:fci_edutrack/auth/login_or_register_screen.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/screens/admin/admin_home_screen.dart';
import 'package:fci_edutrack/screens/home_screen/my_bottom_nav_bar.dart';
import 'package:fci_edutrack/screens/professor/professor_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  static const String routeName = 'auth_wrapper';

  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to AuthProvider changes
    final authProvider = Provider.of<AuthProvider>(context);

    print(
        "AuthWrapper build: isLoggedIn=${authProvider.isLoggedIn}, isLoading=${authProvider.isLoading}, userRole=${authProvider.userRole}");

    // Show loading indicator while checking auth state initially or during logout transition
    // Check specifically if currentUser is null while loading to distinguish initial load/logout
    if (authProvider.isLoading && authProvider.currentUser == null) {
      print("AuthWrapper: Showing loading indicator (initial load/logout)");
      // Use Scaffold to provide a basic structure during loading
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If logged in, determine the correct home screen
    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      final role = authProvider.userRole?.toUpperCase();
      print("AuthWrapper: User logged in with role $role");
      if (role == 'ADMIN') {
        return const AdminHomeScreen();
      } else if (role == 'PROFESSOR') {
        return const ProfessorHomeScreen();
      } else {
        // Default to student home (MyBottomNavBar)
        return const MyBottomNavBar();
      }
    } else {
      // If not logged in (or state cleared after logout), show the login/register screen
      print("AuthWrapper: User not logged in, showing LoginOrRegisterScreen");
      return const LoginOrRegisterScreen();
    }
  }
}
