import 'dart:async';

import 'package:athkar/screens/DashboardScreen.dart';
import 'package:athkar/screens/ExceptionDialog.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'models/AthkarWidgetProvider.dart';
import 'models/SettingsProvider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // Initialize the home widget
    await AthkarWidgetProvider.initializeWidget();
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyC__xvSmqgiQofAHGCGwFfZWLcVgSvlccY",
            authDomain: "athkar-com.firebaseapp.com",
            projectId: "athkar-com",
            storageBucket: "athkar-com.appspot.com",
            messagingSenderId: "1098413929041",
            appId: "1:1098413929041:web:b6234f8f25837f0d443e70",
            measurementId: "G-1VTDGVMNN7"));
  }
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
  ], child: MyApp()));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      home: const MainScreen(),
      theme: context.watch<SettingsProvider>().getTheme,
      debugShowCheckedModeBanner: false,
      title: "أذكاركم",
      navigatorKey: navigatorKey, // key for the notification
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  //this function will get the current theme
  Future getCurrentTheme() async {
    SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    bool? theme = sharedPreferences.getBool('theme');
    if (theme == null) {
      theme = false;
      sharedPreferences.setBool('theme', false).catchError((e) {
        showExceptionPopup(context, e.toString());
      });
    }
    context.read<SettingsProvider>().setNight(theme);
  }

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    getCurrentTheme();
    Timer(
        kIsWeb ? const Duration(seconds: 1) : const Duration(seconds: 3),
        () => Navigator.pushReplacement(
              context,
              PageTransition(
                type: PageTransitionType.scale,
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 500),
                reverseDuration: const Duration(milliseconds: 500),
                child: const DashboardScreen(),
              ),
            ));
    FirebaseAnalytics.instance.logEvent(name: 'open_app');
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  // Request notification permission
  Future<void> _requestNotificationPermission() async {
    final bool? isGranted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    if (isGranted == false) {
      // Handle case where permission is not granted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تفعيل خاصية الإشعارات حتى يصلكم تذكير'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                "assets/images/App_Icon.jpg",
                width: 250.0,
                height: 390.0,
              ),
              const SizedBox(
                height: 120.0,
              ),
              const SpinKitFadingCube(
                color: Color.fromRGBO(12, 151, 159, 1.0),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Add this method to your main app to update widgets when athkar are completed
class AthkarWidgetHelper {
  static Future<void> updateWidgetOnCompletion() async {
    await AthkarWidgetProvider.updateWidget();
  }
}

// Call this in your main.dart initState or wherever you initialize your app
void initializeAthkarWidget() {
  AthkarWidgetProvider.initializeWidget();
}
