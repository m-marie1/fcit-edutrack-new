import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  static const String routeName = 'notification_screen';
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.3,
              ),
              Image.asset('assets/images/notification_logo.png',
                  width: MediaQuery.of(context).size.width * 0.8),
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.1,
              ),
              Text(
                'No Notifications Found',
                style: MyThemeData.lightModeStyle.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
