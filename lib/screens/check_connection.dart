import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'ExceptionDialog.dart';

Future<bool> getConnection(BuildContext context) async {
  try {
    final List<ConnectivityResult> connectivityResults =
    await Connectivity().checkConnectivity();

    // If no internet connection
    if (connectivityResults.contains(ConnectivityResult.none)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد اتصال بالإنترنت'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 7),
        ),
      );
      return false;
    }

    return true;
  } catch (e) {
    showExceptionPopup(context, e.toString());
    return false;
  }
}
