import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';

import 'ExceptionDialog.dart';

var connectivityResult = ConnectivityResult.none;

getConnection(BuildContext context) async {
  connectivityResult =
      await (Connectivity().checkConnectivity()).catchError((e) {
    showExceptionPopup(context, e.toString());
  });
  if (connectivityResult == ConnectivityResult.none) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('لا يوجد اتصال بالإنترنت'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 7),
    ));
    return false;
  } else {
    return true;
  }
}
