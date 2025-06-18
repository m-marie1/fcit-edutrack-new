import 'package:flutter/material.dart';
import '../style/my_app_colors.dart';
import '../themes/my_theme_data.dart';

class HelpAndSupport extends StatelessWidget {
  static const String routeName = 'help_and_support';
  const HelpAndSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text(
          'Help and Support',
          style: MyThemeData.lightModeStyle.textTheme.titleMedium!
              .copyWith(color: MyAppColors.whiteColor),
        ),
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
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, color: MyAppColors.whiteColor,),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Having trouble?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'We’re here to assist you with:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            BulletPoint(text: 'Attendance issues'),
            BulletPoint(text: 'Course registration problems'),
            BulletPoint(text: 'Login or account access'),
            BulletPoint(text: 'Quiz or assignment difficulties'),
            SizedBox(height: 20),
            Text(
              'For help, please contact the system administrator or the faculty\'s support team.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 16)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}