import 'package:athkar/screens/ReportScreen.dart';
import 'package:athkar/screens/offlineAthkar/OfflineAthkarList.dart';
import 'package:athkar/screens/onlineAthkar/AccountsScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import 'Drawer.dart';
import 'ExceptionDialog.dart';
import 'FirebaseMessagingAPI.dart';
import 'NotificationService.dart';
import 'OtherAthkar/OtherAthkarsScreen.dart';
import 'check_connection.dart';
import 'offlineAthkar/counter_page.dart';
import 'offlineAthkar/morningNightScreen.dart';
import 'onlineAthkar/CreateUserScreen.dart';
import 'onlineAthkar/GroupsListScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "";
  String dropdownValue = "";
  List<String> athkarList = [];
  List<String> athkarCount = [];
  List<String> athkarCurrentCount = [];

  Future<void> getUserName() async {
    // Check Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("userName")) {
      setState(() {
        userName = prefs.getString('userName')!.trim();
        dropdownValue = userName;
      });
      bool userExist = await userIsExist();
      if (userExist == false) {
        prefs.clear();
      }
    }
    if (prefs.containsKey("userName") == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'يرجى إنشاء حساب ',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ));
      Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.bottomToTop,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          child: const CreateUserScreen(),
        ),
      ).then((value) {
        Navigator.pushReplacement(
            context,
            PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.center,
              duration: const Duration(milliseconds: 500),
              reverseDuration: const Duration(milliseconds: 500),
              child: const DashboardScreen(),
            ));
      });
    }
  }

  getOfflineAthkarList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey('athkarList') && prefs.containsKey("athkarCount")) {
        athkarList = prefs.getStringList('athkarList')!;
        athkarCount = prefs.getStringList('athkarCount')!;
        athkarCurrentCount = prefs.getStringList('athkarCurrentCount')!;
      }
    });
  }

  Future<bool> userIsExist() async {
    var userQuerySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where("name", isEqualTo: userName)
        .get();
    return userQuerySnapshot.docs.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    getConnection(context);
    getUserName().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    getOfflineAthkarList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    if (kIsWeb == false) {
      NotificationService().initializeNotifications();
      NotificationService().scheduleDailyNotifications();
      FirebaseMessagingAPI().initNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        title: const Text(
          'أذكاركم',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 24.0,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext, BoxConstraints) {
          return GridView.count(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            crossAxisCount: BoxConstraints.maxWidth > 900
                ? 5
                : BoxConstraints.maxWidth > 600
                    ? 3
                    : 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).dialogBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: RawMaterialButton(
                  onPressed: () {
                    if (userName != "") {
                      Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.scale,
                            alignment: Alignment.topRight,
                            duration: const Duration(milliseconds: 500),
                            reverseDuration: const Duration(milliseconds: 500),
                            child: const GroupsListScreen(),
                          ));
                    } else {
                      Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.bottomToTop,
                            duration: const Duration(milliseconds: 500),
                            reverseDuration: const Duration(milliseconds: 500),
                            child: const CreateUserScreen(),
                          )).then((value) async {
                        await getOfflineAthkarList();
                        if (userName != "") {
                          Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.scale,
                                alignment: Alignment.center,
                                duration: const Duration(milliseconds: 500),
                                reverseDuration:
                                    const Duration(milliseconds: 500),
                                child: const GroupsListScreen(),
                              ));
                        }
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Icon(Icons.search, color: Colors.white),
                        Expanded(
                            child: Image.asset(
                          "assets/images/society.gif",
                          fit: BoxFit.cover,
                        )),
                        const SizedBox(height: 8.0),
                        const Text(
                          "أذكار جماعية",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).dialogBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: RawMaterialButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.scale,
                        alignment: Alignment.topLeft,
                        duration: const Duration(milliseconds: 500),
                        reverseDuration: const Duration(milliseconds: 500),
                        child: const MorningEveningAthkars(),
                      ),
                    );
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Icon(Icons.search, color: Colors.white),
                        Expanded(
                            child: Image.asset(
                          "assets/images/day-and-night.png",
                          fit: BoxFit.cover,
                        )),
                        const SizedBox(height: 8.0),
                        const Text(
                          "أذكار الصباح والمساء",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).dialogBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: RawMaterialButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.scale,
                          alignment: Alignment.bottomRight,
                          duration: const Duration(milliseconds: 500),
                          reverseDuration: const Duration(milliseconds: 500),
                          child: const CounterPage(
                            id: 5,
                            title: "أذكار بعد الصلاة",
                          ),
                        )).then((value) async {
                      await getOfflineAthkarList().catchError((e) {
                        showExceptionPopup(context, e.toString());
                      });
                    });
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Icon(Icons.search, color: Colors.white),
                        Expanded(
                            child: Image.asset(
                              "assets/images/praying.png",
                              fit: BoxFit.cover,
                            )),
                        const SizedBox(height: 8.0),
                        const Text(
                          "أذكار بعد الصلاة",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).dialogBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: RawMaterialButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.scale,
                          alignment: Alignment.bottomLeft,
                          duration: const Duration(milliseconds: 500),
                          reverseDuration: const Duration(milliseconds: 500),
                          child: const CounterPage(
                            id: 6,
                            title: "أذكار النوم",
                          ),
                        )).then((value) async {
                      await getOfflineAthkarList().catchError((e) {
                        showExceptionPopup(context, e.toString());
                      });
                    });
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Icon(Icons.search, color: Colors.white),
                        Expanded(
                            child: Image.asset(
                              "assets/images/sleep.png",
                              fit: BoxFit.cover,
                            )),
                        const SizedBox(height: 8.0),
                        const Text(
                          "أذكار النوم",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).dialogBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: RawMaterialButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.scale,
                          alignment: Alignment.bottomLeft,
                          duration: const Duration(milliseconds: 500),
                          reverseDuration: const Duration(milliseconds: 500),
                          child: const ReportsScreen(
                          ),
                        )).then((value) async {
                      await getOfflineAthkarList().catchError((e) {
                        showExceptionPopup(context, e.toString());
                      });
                    });
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Icon(Icons.search, color: Colors.white),
                        Expanded(
                            child: Image.asset(
                              "assets/images/calender.png",
                              fit: BoxFit.cover,
                            )),
                        const SizedBox(height: 8.0),
                        const Text(
                          "تقارير الأذكار",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).dialogBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: RawMaterialButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.scale,
                          alignment: Alignment.centerRight,
                          duration: const Duration(milliseconds: 500),
                          reverseDuration: const Duration(milliseconds: 500),
                          child: const OfflineAthkarList(),
                        )).then((value) async {
                      await getOfflineAthkarList().catchError((e) {
                        showExceptionPopup(context, e.toString());
                      });
                    });
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Icon(Icons.search, color: Colors.white),
                        Expanded(
                            child: Image.asset(
                          "assets/images/athkary.png",
                          fit: BoxFit.cover,
                        )),
                        const SizedBox(height: 8.0),
                        const Text(
                          "أذكاري",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).dialogBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: RawMaterialButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.scale,
                          alignment: Alignment.centerLeft,
                          duration: const Duration(milliseconds: 500),
                          reverseDuration: const Duration(milliseconds: 500),
                          child: const OtherAthkarScreen(),
                        )).then((value) async {
                      await getOfflineAthkarList().catchError((e) {
                        showExceptionPopup(context, e.toString());
                      });
                    });
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Icon(Icons.search, color: Colors.white),
                        Expanded(
                            child: Image.asset(
                          "assets/images/other3.png",
                          fit: BoxFit.cover,
                        )),
                        const SizedBox(height: 8.0),
                        const Text(
                          "أذكار أخرى",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).dialogBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: RawMaterialButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.scale,
                          alignment: Alignment.bottomRight,
                          duration: const Duration(milliseconds: 500),
                          reverseDuration: const Duration(milliseconds: 500),
                          child: const AccountsScreen(),
                        )).then((value) async {
                      await getOfflineAthkarList().catchError((e) {
                        showExceptionPopup(context, e.toString());
                      });
                    });
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Icon(Icons.search, color: Colors.white),
                        Expanded(
                            child: Image.asset(
                              "assets/images/accounts2.png",
                              fit: BoxFit.cover,
                            )),
                        const SizedBox(height: 8.0),
                        const Text(
                          "حسابات العائلة",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
