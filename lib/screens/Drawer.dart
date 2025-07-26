import 'package:athkar/screens/About.dart';
import 'package:athkar/screens/onlineAthkar/CreateUserScreen.dart';
import 'package:athkar/screens/onlineAthkar/GroupsListScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/SettingsProvider.dart';
import 'AthkarWidgetSetup.dart';
import 'DashboardScreen.dart';
import 'ExceptionDialog.dart';
import 'Feedback Screen.dart';
import 'check_connection.dart';
import 'offlineAthkar/OfflineAthkarList.dart';
import 'offlineAthkar/morningNightScreen.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String userName = "";
  List<String> usersList = [""];
  List<String> athkarList = [];
  List<String> athkarCount = [];
  List<String> athkarCurrentCount = [];
  bool isDarkThemeActive = false;

  @override
  void initState() {
    super.initState();
    getConnection(context);
    getUserName().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    getUsersList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    getCurrentTheme().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    getOfflineAthkarList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
  }

  getUserName() async {
    // Check Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey("userName")) {
        userName = prefs.getString('userName')!.trim();
      }
    });
  }

  setCurrentUserName(selectedUser) async {
    // Check Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('userName', userName);
    await prefs.setStringList('usersList', usersList);
    saveOfflineAthkarList();
    setState(() {
      userName = selectedUser;
    });
  }

  deleteUserName(selectedUser, String deletedUser) async {
    // Check Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (selectedUser != "") {
      await prefs.setBool('theme', isDarkThemeActive);
      await prefs.setString('userName', selectedUser);
      await prefs.setStringList('usersList', usersList);
    }
    setState(() {
      userName = selectedUser;
    });
    saveOfflineAthkarList();
    CollectionReference users = FirebaseFirestore.instance.collection('Users');
    CollectionReference groups =
        FirebaseFirestore.instance.collection('Groups');
    // Find and delete groups where the user is the creator
    var createdGroupsQuery =
        await groups.where("createdBy", isEqualTo: deletedUser).get();

    for (var createdGroup in createdGroupsQuery.docs) {
      await groups.doc(createdGroup.id).delete();
      final groupDocRef =
          FirebaseFirestore.instance.collection('Groups').doc(createdGroup.id);
      final athkarsCollection = groupDocRef.collection('Athkars');

      // Delete all docs in 'Athkars'
      final athkarsSnapshot = await athkarsCollection.get();
      for (var athkarDoc in athkarsSnapshot.docs) {
        await athkarsCollection.doc(athkarDoc.id).delete();
      }

      // Delete the main group document
      var group = await groupDocRef.get();
      group.reference.delete();
    }
    var user = await users.where("name", isEqualTo: deletedUser).get();
    for (var element in user.docs) {
      if (element.get('groupId') != "") {
        groups.doc(element.get('groupId')).update({
          "members.$deletedUser": FieldValue.delete(),
        });
      }
      element.reference.delete();
    }
  }

  getUsersList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey('usersList')) {
        usersList = prefs.getStringList('usersList')!;
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
      }
    });
  }

  saveOfflineAthkarList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('athkarList', athkarList);
    await prefs.setStringList('athkarCount', athkarCount);
    await prefs.setStringList('athkarCurrentCount', athkarCurrentCount);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
                color:
                    settingsProvider.isNight ? Colors.grey[800] : Colors.teal),
            accountName: Text(
              userName,
              style: const TextStyle(fontSize: 18),
            ),
            accountEmail: null,
            currentAccountPicture: CircleAvatar(
              radius: 10,
              backgroundColor:
                  settingsProvider.isNight ? Colors.black : Colors.white,
              child: const Icon(
                Icons.person,
                size: 40,
              ),
            ),
          ),
          SizedBox(
            height: 1.0 * 50 * usersList.length,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: usersList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(
                    Icons.account_box,
                    color: usersList[index] == userName
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  title: Text(usersList[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _showDeleteConfirmationDialog(context, index)
                          .catchError((e) {
                        showExceptionPopup(context, e.toString());
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      userName = usersList[index];
                    });
                    setCurrentUserName(usersList[index]).catchError((e) {
                      showExceptionPopup(context, e.toString());
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          ListTile(
            leading: const Icon(Icons.add_box),
            title: const Text(
              'إضافة حساب جديد',
            ),
            onTap: () {
              Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.bottomToTop,
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 500),
                    child: const CreateUserScreen(),
                  )).then((value) => Navigator.pushReplacement(
                  context,
                  PageTransition(
                    type: PageTransitionType.scale,
                    alignment: Alignment.center,
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 500),
                    child: const DashboardScreen(),
                  )));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text(
              'الرئيسية',
            ),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  PageTransition(
                    type: PageTransitionType.scale,
                    alignment: Alignment.center,
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 500),
                    child: const DashboardScreen(),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text(
              'الأذكار الجماعية',
            ),
            onTap: () {
              Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.leftToRightWithFade,
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 500),
                    child: const GroupsListScreen(),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text(
              'أذكار الصباح والمساء',
            ),
            onTap: () {
              Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.leftToRightWithFade,
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 500),
                    child: const MorningEveningAthkars(),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart),
            title: const Text(
              'إضافة التقرير اليومي',
            ),
            onTap: () {
              Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.leftToRightWithFade,
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 500),
                    child: const AthkarWidgetSetup(),
                  ));
            },
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.leftToRightWithFade,
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 500),
                    child: FeedbackScreen(userName),
                  ));
            },
            leading: const Icon(Icons.feedback_rounded),
            title: const Text(
              "التغذية الراجعة/إقتراحات",
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text(
              'حول التطبيق',
            ),
            onTap: () {
              Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.leftToRightWithFade,
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 500),
                    child: const AboutApp(),
                  ));
            },
          ),
          const Divider(),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Image.asset(
                "assets/images/day-mode.png",
                width: 30,
              ),
              const Text("الفاتح"),
              Switch(
                  value: isDarkThemeActive,
                  onChanged: (value) {
                    setCurrentTheme(value).catchError((e) {
                      showExceptionPopup(context, e.toString());
                    });
                    setState(() {
                      isDarkThemeActive = !isDarkThemeActive;
                    });
                    context.read<SettingsProvider>().changeNight();
                  }),
              const Text("المظلم"),
              Image.asset(
                "assets/images/night-mode.png",
                width: 30,
              ),
            ],
          )
        ],
      ),
    );
  }

  //this function will set the theme
  Future setCurrentTheme(bool value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool('theme', value);
  }

  //this function will get the theme
  Future getCurrentTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      if (sharedPreferences.containsKey('theme')) {
        isDarkThemeActive = sharedPreferences.getBool('theme')!;
      }
    });
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'حذف حساب',
            style: TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'هل انت متأكد من حذف هذا الحساب؟',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'الغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'حذف',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
              ),
              onPressed: () {
                String deletedUser = usersList[index];
                usersList.remove(usersList[index]);
                deleteUserName(
                    usersList.isNotEmpty ? usersList.first : "", deletedUser);
                if (usersList.isEmpty) {
                  Navigator.pushReplacement(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 500),
                        reverseDuration: const Duration(milliseconds: 500),
                        child: const DashboardScreen(),
                      ));
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
