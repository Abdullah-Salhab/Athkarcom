import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';

var connectivityResult = ConnectivityResult.none;


getConnection(BuildContext context)async{
  connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none ) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No internet connection found'),backgroundColor: Colors.red,duration: Duration(seconds: 7),));
    return false;
  }
  else{
    return true;
  }
}

Widget noInternet(){
  return Center(
    child: Container(
      child: Column(
        children: [
          Expanded(flex: 4,
              child: Container(
                width: double.infinity,
                color: Colors.white,
              )),
          Image.asset("assets/noConnection.jpg",fit: BoxFit.cover,),
          Expanded(flex: 5,
              child: Container(
                width: double.infinity,
                color: Colors.white,
              )),
        ],
      ),
    ),
  );
}