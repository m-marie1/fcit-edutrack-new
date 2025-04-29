import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';

import '../style/my_app_colors.dart';

typedef ButtonAction = void Function();

class CustomButtonWidget extends StatelessWidget {
  final String label;
  final ButtonAction buttonFunction;

  final IconData? buttonIcon;

  const CustomButtonWidget(
      {super.key,
      required this.label,
      required this.buttonFunction,
      this.buttonIcon});

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return ElevatedButton(
      onPressed: buttonFunction,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(width * 0.5, height * 0.06),
        backgroundColor: MyAppColors.primaryColor,
        foregroundColor: MyAppColors.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(width * 0.02),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (buttonIcon != null) ...[
            Icon(
              buttonIcon,
              color: Colors.white,
            ),
            SizedBox(width: width * 0.02),
          ],
          Text(
            label,
            style: MyThemeData.lightModeStyle.textTheme.bodySmall!
                .copyWith(color: MyAppColors.whiteColor),
          ),
        ],
      ),
    );
  }
}
