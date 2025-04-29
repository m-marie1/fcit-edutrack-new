import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';

class ExplainPageItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const ExplainPageItem(
      {super.key,
      required this.imagePath,
      required this.title,
      required this.description});

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath, height: height * 0.26),
        // Add your images to assets
        SizedBox(height: height * 0.011),
        Text(title, style: MyThemeData.lightModeStyle.textTheme.bodyMedium),
        SizedBox(height: height * 0.011),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            description,
            style: MyThemeData.lightModeStyle.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: height * 0.032),
      ],
    );
  }
}
