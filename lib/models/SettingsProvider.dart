import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  // dark theme
  final darkTheme = ThemeData(
    appBarTheme: AppBarTheme(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Amiri',
          fontSize: 18
        ),
        backgroundColor: Colors.grey[800]),
    // general color
    primarySwatch: Colors.grey,
    // for text
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32),
      displayMedium: TextStyle(fontSize: 24),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ).apply(
      bodyColor: Colors.white,
    ),
    secondaryHeaderColor: const Color.fromRGBO(116, 116, 116, 1.0),
    //for app bar and splash(long press in widget )
    primaryColor: const Color.fromRGBO(97, 97, 97, 1.0),
    brightness: Brightness.dark,
    // distance in map
    backgroundColor: Colors.black,
    scaffoldBackgroundColor: Colors.grey[900],
    // main card
    cardColor: Colors.grey[800],
    // for icons
    bottomAppBarColor: Colors.grey[700],
    // shadow
    shadowColor: Colors.white.withOpacity(0.1),
    // text
    // splashColor: Colors.white,
    // limitation color
    hintColor: Colors.white,
    // accentIconTheme: IconThemeData(color: Colors.black),
    dividerColor: Colors.grey[800],
    // radio
    unselectedWidgetColor: Colors.black,
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all(Colors.blue),
      // Customize thumb color
      trackColor:
          MaterialStateProperty.all(Colors.grey), // Customize track color
    ),
    dialogBackgroundColor: Colors.grey[800]
  );

  // light theme
  final lightTheme = ThemeData(
    appBarTheme: const AppBarTheme(
        centerTitle: true,
        foregroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'Amiri',
          fontSize: 18
        ),
        backgroundColor: Colors.green),
    primarySwatch: Colors.blue,
    secondaryHeaderColor: const Color.fromRGBO(40, 112, 200, 1.0),
    cardColor: Colors.white,
    canvasColor: Colors.white,
    primaryColor: const Color.fromRGBO(40, 112, 200, 1.0),
    brightness: Brightness.light,
    backgroundColor: Colors.white,
    // accentIconTheme: IconThemeData(color: Colors.white),
    hintColor: Colors.black,
    bottomAppBarColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
    shadowColor: Colors.grey.withOpacity(0.5),
    // buttonColor: Colors.grey,
    // splashColor: Colors.green,
    unselectedWidgetColor: const Color(0xFF2870C8),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32),
      displayMedium: TextStyle(fontSize: 24),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ),
      dialogBackgroundColor: Colors.white
  );

  // default theme
  ThemeData themeMode = ThemeData(
    appBarTheme: const AppBarTheme(
        centerTitle: true,
        foregroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'Amiri',
          fontSize: 18
        ),
        backgroundColor: Colors.green),
    primarySwatch: Colors.blue,
    secondaryHeaderColor: const Color.fromRGBO(40, 112, 200, 1.0),
    cardColor: Colors.white,
    canvasColor: Colors.white,
    primaryColor: const Color.fromRGBO(40, 112, 200, 1.0),
    brightness: Brightness.light,
    backgroundColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    // accentIconTheme: IconThemeData(color: Colors.white),
    hintColor: Colors.black,
    // bottomAppBarColor:Colors.white,
    shadowColor: Colors.grey.withOpacity(0.5),
    // buttonColor: Colors.grey,
    // splashColor: Colors.green,
    unselectedWidgetColor: const Color(0xFF2870C8),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32),
      displayMedium: TextStyle(fontSize: 24),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ),
      dialogBackgroundColor: Colors.white
  );

  bool dark = false;
  bool isNight = false;

  get getIsNight => isNight;

  get getTheme => themeMode;

  void changeNight() {
    isNight = !isNight;
    (isNight) ? themeMode = darkTheme : themeMode = lightTheme;
    notifyListeners();
  }

  void setNight(bool value) {
    isNight = value;
    (isNight) ? themeMode = darkTheme : themeMode = lightTheme;
    notifyListeners();
  }
}
