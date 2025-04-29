import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';

import '../modules/custom_button_widget.dart';
import '../style/my_app_colors.dart';

class CameraPermissionScreen extends StatelessWidget {
  static const String routeName = 'camera_permission_screen';

  const CameraPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Container(
      color: MyAppColors.whiteColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Image.asset(
            'assets/images/camera_permission_logo.png',
            width: width * 0.8,
          ),
          Column(
            children: [
              Text(
                'السماح بالوصول الي',
                style: MyThemeData.lightModeStyle.textTheme.bodyMedium,
              ),
              SizedBox(
                height: height * 0.019,
              ),
              CustomButtonWidget(
                  label: 'camera',
                  buttonIcon: Icons.camera_alt_outlined,
                  buttonFunction: () {}),
              SizedBox(
                height: height * 0.019,
              ),
              CustomButtonWidget(
                  label: 'gallery',
                  buttonIcon: Icons.photo_outlined,
                  buttonFunction: () {}),
            ],
          ),
          CustomButtonWidget(
              label: 'confirm',
              buttonIcon: Icons.check_circle_outline,
              buttonFunction: () {}),
        ],
      ),
    );
  }
}
