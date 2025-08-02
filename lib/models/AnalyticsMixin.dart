import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  String get screenName;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.setCurrentScreen(
      screenName: screenName,
      screenClassOverride: screenName,
    );
  }
}
