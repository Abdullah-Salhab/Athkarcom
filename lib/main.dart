import 'dart:async';

import 'package:athkar/screens/DashboardScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyC__xvSmqgiQofAHGCGwFfZWLcVgSvlccY",
          authDomain: "athkar-com.firebaseapp.com",
          projectId: "athkar-com",
          storageBucket: "athkar-com.appspot.com",
          messagingSenderId: "1098413929041",
          appId: "1:1098413929041:web:b6234f8f25837f0d443e70",
          measurementId: "G-1VTDGVMNN7"));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MainScreen(),
      // theme: context.watch<SettingsProvider>().getTheme,
      debugShowCheckedModeBanner: false,
      title: "أذكاركم",
      theme: ThemeData(
          appBarTheme: const AppBarTheme(
              backgroundColor: Colors.green,
              titleTextStyle: TextStyle(
                  fontFamily: 'Tajawal', fontSize: 22.0, color: Colors.white),
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0),
          scaffoldBackgroundColor: Colors.white),
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
  @override
  void initState() {
    Timer(
        kIsWeb ? const Duration(seconds: 1) : const Duration(seconds: 3),
        () => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const DashboardScreen())));
    FirebaseAnalytics.instance.logEvent(name: 'open_app');
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
