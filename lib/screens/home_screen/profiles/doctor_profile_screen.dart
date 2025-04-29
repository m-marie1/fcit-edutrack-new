import 'package:fci_edutrack/modules/custome_container.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.04),
      child: SingleChildScrollView(
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: MyAppColors.primaryColor,
              radius: MediaQuery.of(context).size.width < 600
                  ? MediaQuery.of(context).size.width * 0.16
                  : MediaQuery.of(context).size.width * 0.08,
              child: Image.asset(
                'assets/images/profile_photo.png',
                width: MediaQuery.of(context).size.width < 600
                    ? MediaQuery.of(context).size.width * 0.32
                    : MediaQuery.of(context).size.width * 0.16,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.012,
            ),
            Text(
              'DR Ahmed Mohamed',
              style: MyThemeData.lightModeStyle.textTheme.bodySmall,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.06,
            ),
            CustomContainer(
              label: 'Attendance List',
              icon: Icons.list_alt_outlined,
              onContainerClick: () {},
            ),
            CustomContainer(
              label: 'Notifications',
              icon: Icons.notifications,
              onContainerClick: () {},
            ),
            CustomContainer(
              label: 'Help and Support',
              icon: Icons.help,
              onContainerClick: () {},
            ),
            CustomContainer(
              label: 'Settings',
              icon: Icons.settings,
              onContainerClick: () {},
            ),
            CustomContainer(
              label: 'Log Out',
              icon: Icons.logout,
              onContainerClick: () {},
            ),
          ],
        ),
      ),
    );
  }
}
