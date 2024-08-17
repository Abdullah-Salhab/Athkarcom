import 'package:athkar/screens/About.dart';
import 'package:athkar/screens/onlineAthkar/CreateUserScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/SettingsProvider.dart';
import 'DashboardScreen.dart';
import 'Feedback Screen.dart';
import 'offlineAthkar/OfflineAthkarList.dart';
import 'offlineAthkar/morningNightScreen.dart';
import 'onlineAthkar/groupAthkarScreen.dart';

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
    getUserName();
    getUsersList();
    getCurrentTheme();
    getOfflineAthkarList();
    super.initState();
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
    var doc = await users.where("name", isEqualTo: deletedUser).get();
    doc.docs.first.reference.delete();
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
                    settingsProvider.isNight ? Colors.grey[800] : Colors.green),
            accountName: Text(
              userName,
              style: TextStyle(fontSize: 16),
            ),
            accountEmail: Text(""),
            currentAccountPicture: CircleAvatar(
              backgroundColor:
                  settingsProvider.isNight ? Colors.black : Colors.white,
              child: Icon(
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
                      _showDeleteConfirmationDialog(context, index);
                    },
                  ),
                  onTap: () {
                    setState(() {
                      userName = usersList[index];
                    });
                    setCurrentUserName(usersList[index]);
                  },
                );
              },
            ),
          ),
          SizedBox(
            height: 10,
          ),
          ListTile(
            leading: const Icon(Icons.add_box),
            title: const Text(
              'إضافة حساب جديد',
              // style: GoogleFonts.getFont(settingsProvider.getFontFamily,
              //     fontSize: settingsProvider.getFontSize),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateUserScreen())).then((value) =>
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DashboardScreen())));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text(
              'الرئيسية',
              // style: GoogleFonts.getFont(settingsProvider.getFontFamily,
              //     fontSize: settingsProvider.getFontSize),
            ),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DashboardScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text(
              'الأذكار الجماعية',
              // style: GoogleFonts.getFont(settingsProvider.getFontFamily,
              //     fontSize: settingsProvider.getFontSize),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GroupAthkarListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text(
              'أذكار الصباح والمساء',
              // style: GoogleFonts.getFont(settingsProvider.getFontFamily,
              //     fontSize: settingsProvider.getFontSize),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MorningEveningAthkars()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.my_library_books_rounded),
            title: const Text(
              'أذكاري',
              // style: GoogleFonts.getFont(settingsProvider.getFontFamily,
              //     fontSize: settingsProvider.getFontSize),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OfflineAthkarList()));
            },
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FeedbackScreen(userName)));
            },
            leading: const Icon(Icons.feedback_rounded),
            title: const Text(
              "التغذية الراجعة/إقتراحات",
              // style: GoogleFonts.getFont(settingsProvider.getFontFamily,
              //     fontSize: settingsProvider.getFontSize),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text(
              'حول التطبيق',
              // style: GoogleFonts.getFont(settingsProvider.getFontFamily,
              //     fontSize: settingsProvider.getFontSize),
            ),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AboutApp()));
            },
          ),
          const Divider(),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Image.asset(
                "assets/images/day-mode.png",
                width: 30,
              ),
              Text("الفاتح"),
              Switch(
                  value: isDarkThemeActive,
                  onChanged: (value) {
                    setCurrentTheme(value);
                    setState(() {
                      isDarkThemeActive = !isDarkThemeActive;
                    });
                    context.read<SettingsProvider>().changeNight();
                    print(value);
                  }),
              Text("المظلم"),
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
                if (usersList.isEmpty)
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DashboardScreen()));
                else
                  Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
