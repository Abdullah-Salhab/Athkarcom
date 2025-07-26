import 'package:athkar/screens/ExceptionDialog.dart';
import 'package:athkar/screens/check_connection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../DashboardScreen.dart';
import 'CreateUserScreen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  String userName = "";
  List<String> usersList = [];
  List<String> athkarList = [];
  List<String> athkarCount = [];
  List<String> athkarCurrentCount = [];
  bool isDarkThemeActive = false;

  @override
  void initState() {
    super.initState();
    initUsers();
    getConnection(context);
    getOfflineAthkarList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
  }

  Future<void> initUsers() async {
    await getUserName().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    await getUsersList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
  }

  Future<void> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("userName")) {
      userName = prefs.getString('userName')!.trim();
    }
  }

  Future<void> getUsersList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('usersList')) {
      List<String> allUsers = prefs.getStringList('usersList')!;
      if (userName.isNotEmpty && allUsers.contains(userName)) {
        allUsers.remove(userName);
        allUsers.insert(0, userName); // set the username the first one
      }
      setState(() {
        usersList = allUsers;
      });
    }
  }

  Future<void> setCurrentUserName(String selectedUser) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('userName', selectedUser);
    await prefs.setStringList('usersList', usersList);
    saveOfflineAthkarList();
    setState(() {
      userName = selectedUser;
    });
  }

  Future<void> deleteUserName(String selectedUser, String deletedUser) async {
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

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              const Text('حذف حساب', style: TextStyle(fontFamily: 'Tajawal')),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('هل انت متأكد من حذف هذا الحساب؟',
                    style: TextStyle(fontFamily: 'Tajawal')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('الغاء', style: TextStyle(fontFamily: 'Tajawal')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('حذف', style: TextStyle(fontFamily: 'Tajawal')),
              onPressed: () async {
                String deletedUser = usersList[index];
                usersList.removeAt(index);
                String newSelectedUser =
                    usersList.isNotEmpty ? usersList.first : "";

                await deleteUserName(newSelectedUser, deletedUser)
                    .catchError((e) {
                  showExceptionPopup(context, e.toString());
                });

                setState(() {
                  userName = newSelectedUser;
                });

                if (usersList.isEmpty) {
                  Navigator.pushReplacement(
                      context,
                      PageTransition(
                        type: PageTransitionType.scale,
                        alignment: Alignment.bottomRight,
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
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'الحسابات',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 22.0,
        ),
      )),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: usersList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final name = usersList[index];
                  return Card(
                    color:
                        name == userName ? Colors.green.shade50 : Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: name == userName
                                ? Colors.teal.shade300
                                : Colors.white,
                            width: 3)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.teal,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '',
                          style: const TextStyle(
                              fontSize: 20, color: Colors.white),
                        ),
                      ),
                      title: Text(name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold)),
                      subtitle: name == userName
                          ? const Text("المستخدم الحالي",
                              style: TextStyle(color: Colors.teal))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _showDeleteConfirmationDialog(context, index),
                      ),
                      onTap: () {
                        if (name != userName) {
                          setCurrentUserName(name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.teal,
                              duration: const Duration(seconds: 1),
                              content: Text('تم التبديل إلى $name',
                                  style:
                                      const TextStyle(fontFamily: 'Tajawal')),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.scale,
                      alignment: Alignment.bottomCenter,
                      duration: const Duration(milliseconds: 500),
                      reverseDuration: const Duration(milliseconds: 500),
                      child: const CreateUserScreen(),
                    )).whenComplete(() async {
                  await getUserName();
                  await getUsersList();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text("إضافة حساب جديد",
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(70),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
