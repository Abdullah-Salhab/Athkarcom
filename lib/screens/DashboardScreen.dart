import 'package:athkar/screens/offlineAthkar/OfflineAthkarList.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/SettingsProvider.dart';
import 'Drawer.dart';
import 'offlineAthkar/morningNightScreen.dart';
import 'onlineAthkar/CreateUserScreen.dart';
import 'onlineAthkar/groupAthkarScreen.dart';
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

  getUserName() async {
    // Check Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey("userName")) {
        userName = prefs.getString('userName')!.trim();
        dropdownValue = userName;
      } else {
        Navigator.push(context,
                MaterialPageRoute(builder: (context) => CreateUserScreen()))
            .then((value) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => DashboardScreen()));
        });
      }
    });
  }

  getOfflineAthkarList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey('athkarList') && prefs.containsKey("athkarCount")) {
        athkarList = prefs.getStringList('athkarList')!;
        athkarCount = prefs.getStringList('athkarCount')!;
        athkarCurrentCount = prefs.getStringList('athkarCurrentCount')!;
        // print(athkarList);
        // print(athkarCount);
        // print(athkarCurrentCount);
      }
    });
  }

  Future<void> updateLastLogin() async {
    // Save to Firestore
    var userQuerySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where("name", isEqualTo: userName)
        .get();

    if (userQuerySnapshot.docs.isNotEmpty) {
      var userDocument = userQuerySnapshot.docs.first;

      await userDocument.reference.update({
        'last_login': DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          DateTime.now().hour,
          DateTime.now().minute,
        ),
      });
    }
  }

  @override
  void initState() {
    getUserName();
    if (userName != "") {
      updateLastLogin();
    }
    getOfflineAthkarList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
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
                        MaterialPageRoute(
                            builder: (context) =>
                                const GroupAthkarListScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreateUserScreen()),
                      ).then((value) async {
                        await getOfflineAthkarList();
                        if (userName != "") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const GroupAthkarListScreen()),
                          );
                        }
                        return null;
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
                          "assets/images/network.png",
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
                      MaterialPageRoute(
                          builder: (context) => const MorningEveningAthkars()),
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
                      MaterialPageRoute(
                          builder: (context) => const OfflineAthkarList()),
                    ).then((value) async {
                      await getOfflineAthkarList();
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
                      MaterialPageRoute(
                          builder: (context) => const OfflineAthkarList()),
                    ).then((value) async {
                      await getOfflineAthkarList();
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
                          "assets/images/other.png",
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
                      MaterialPageRoute(
                          builder: (context) => CreateUserScreen()),
                    ).then((value) async {
                      await getOfflineAthkarList();
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
                          "assets/images/network2.png",
                          fit: BoxFit.cover,
                        )),
                        const SizedBox(height: 8.0),
                        const Text(
                          "إنشاء حساب جديد",
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
