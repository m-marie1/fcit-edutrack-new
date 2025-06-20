import 'package:fci_edutrack/themes/my_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';
class ThemeProvider extends ChangeNotifier {
  // initialize the theme to light mode
  ThemeData appTheme = MyThemeData.lightModeStyle;
  late SharedPreferences themePref ;
  // getter method to get the value of the current theme
  ThemeData get appThemeData => appTheme;

  Future <void> getTheme() async{
    themePref = await SharedPreferences.getInstance() ;
    if(themePref.getBool('isDark')??false){
      appTheme =  MyThemeData.darkModeStyle;
    }
    else{
      appTheme =  MyThemeData.lightModeStyle;
    }
    notifyListeners();
  }

  // setter method to change the value of the theme
  set appThemeData(ThemeData appThemeData) {
    appTheme = appThemeData;
    notifyListeners();
    _saveTheme(isDark());
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

  // save the theme
  void _saveTheme(bool isDark){
    themePref.setBool('isDark', isDark);
  }
}
