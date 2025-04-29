import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../style/my_app_colors.dart';

class CustomConfirmationCell extends StatelessWidget {
  const CustomConfirmationCell({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.13,
      height: MediaQuery.of(context).size.height * 0.059,
      child: TextFormField(
        onSaved: (pin1) {},
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(context).nextFocus();
          }
        },
        style: Theme.of(context).textTheme.bodyMedium,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.025),
              borderSide: BorderSide(
                  color: MyAppColors.primaryColor,
                  width: MediaQuery.of(context).size.width * 0.001)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.025),
              borderSide: BorderSide(
                  color: Provider.of<ThemeProvider>(context).isDark()
                      ? MyAppColors.lightBlueColor
                      : MyAppColors.primaryColor,
                  width: MediaQuery.of(context).size.width * 0.002)),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }
}
