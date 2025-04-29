import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // initialize the theme to light mode
  ThemeData appTheme = MyThemeData.lightModeStyle;

  // getter method to get the value of the current theme
  ThemeData get appThemeData => appTheme;

  // setter method to change the value of the theme
  set appThemeData(ThemeData appThemeData) {
    appTheme = appThemeData;
    notifyListeners();
  }

  // check if the current theme is dark mode
  bool isDark() => appTheme == MyThemeData.darkModeStyle;

  // toggle between the light and dark theme
  void toggleTheme() {
    if (appTheme == MyThemeData.lightModeStyle) {
      appThemeData = MyThemeData.darkModeStyle;
    } else {
      appThemeData = MyThemeData.lightModeStyle;
    }
  }
}
