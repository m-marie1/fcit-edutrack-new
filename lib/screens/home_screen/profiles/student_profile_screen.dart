import 'package:fci_edutrack/modules/custome_container.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:fci_edutrack/screens/home_screen/notifications_screen.dart';
import 'package:fci_edutrack/screens/settings_screen.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/auth/login_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<ThemeProvider>(context).isDark();
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      color: isDark ? MyAppColors.primaryDarkColor : MyAppColors.whiteColor,
      padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.04),
      child: SingleChildScrollView(
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: MyAppColors.primaryColor.withOpacity(0.2),
              radius: MediaQuery.of(context).size.width * 0.16,
              child: Icon(
                Icons.person,
                size: MediaQuery.of(context).size.width * 0.16,
                color: MyAppColors.primaryColor,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.012,
            ),
            Text(
              authProvider.currentUser?.fullName ?? 'User',
              style: isDark
                  ? MyThemeData.darkModeStyle.textTheme.bodySmall
                  : MyThemeData.lightModeStyle.textTheme.bodySmall,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.06,
            ),
            CustomContainer(
              label: 'My Attendance',
              icon: Icons.list_alt_outlined,
              onContainerClick: () {
                // Navigate to attendance history
                Navigator.pushNamed(context, 'attendance_history');
              },
            ),
            CustomContainer(
              label: 'Notifications',
              icon: Icons.notifications,
              onContainerClick: () {
                Navigator.pushNamed(context, NotificationsScreen.routeName);
              },
            ),
            CustomContainer(
              label: 'Help and Support',
              icon: Icons.help,
              onContainerClick: () {},
            ),
            CustomContainer(
              label: 'Settings',
              icon: Icons.settings,
              onContainerClick: () {
                Navigator.pushNamed(context, SettingsScreen.routeName);
              },
            ),
            CustomContainer(
              label: 'Log Out',
              icon: Icons.logout,
              onContainerClick: () async {
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await authProvider.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      LoginScreen.routeName, (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
