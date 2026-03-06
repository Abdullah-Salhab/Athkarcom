import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  // ===================== DARK THEME =====================
  final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      primary: Color.fromRGBO(97, 97, 97, 1.0),
      secondary: Color.fromRGBO(116, 116, 116, 1.0),
      surface: Color(0xFF424242),
    ),

    scaffoldBackgroundColor: Color(0xFF212121),
    cardColor: Color(0xFF424242),
    shadowColor: Colors.white24,
    hintColor: Colors.white,
    dividerColor: Color(0xFF424242),
    unselectedWidgetColor: Colors.black,

    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Color(0xFF424242),
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Amiri',
        fontSize: 18,
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32),
      displayMedium: TextStyle(fontSize: 24),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ).apply(bodyColor: Colors.white),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStatePropertyAll(Colors.blue),
      trackColor: MaterialStatePropertyAll(Colors.grey),
    ),
  );

  // ===================== LIGHT THEME =====================
  final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: const ColorScheme.light(
      primary: Color.fromRGBO(40, 112, 200, 1.0),
      secondary: Color.fromRGBO(40, 112, 200, 1.0),
    ),

    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    shadowColor: Colors.grey,
    hintColor: Colors.black,
    unselectedWidgetColor: Color(0xFF2870C8),

    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.teal,
      foregroundColor: Colors.black,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Amiri',
        fontSize: 18,
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32),
      displayMedium: TextStyle(fontSize: 24),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ),
  );

  // ===================== CURRENT THEME =====================
  late ThemeData themeMode = lightTheme;

  bool isNight = false;

  bool get getIsNight => isNight;
  ThemeData get getTheme => themeMode;

  void changeNight() {
    isNight = !isNight;
    themeMode = isNight ? darkTheme : lightTheme;
    notifyListeners();
  }

  void setNight(bool value) {
    isNight = value;
    themeMode = isNight ? darkTheme : lightTheme;
    notifyListeners();
  }
}
