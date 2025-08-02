import 'package:athkar/screens/ExceptionDialog.dart';
import 'package:athkar/screens/check_connection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/AnalyticsMixin.dart';
import '../DashboardScreen.dart';
import 'CreateUserScreen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> with AnalyticsMixin{
  @override
  String get screenName => 'AccountsScreen';

  String userName = "";
  List<String> usersList = [];
  List<String> athkarList = [];
  List<String> athkarCount = [];
  List<String> athkarCurrentCount = [];
  bool isDarkThemeActive = false;
  Map<String, String> userDocIds = {}; // Store document IDs for each user
  bool _isLoadingDocIds = false;

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
    // Load document IDs for all users
    await loadUserDocumentIds();
  }

  Future<void> loadUserDocumentIds() async {
    if (usersList.isEmpty) return;

    setState(() {
      _isLoadingDocIds = true;
    });

    try {
      Map<String, String> tempDocIds = {};

      for (String user in usersList) {
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('Users')
            .where('name', isEqualTo: user)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          tempDocIds[user] = userQuery.docs.first.id;
        }
      }

      setState(() {
        userDocIds = tempDocIds;
      });
    } catch (e) {
      showExceptionPopup(context, e.toString());
    } finally {
      setState(() {
        _isLoadingDocIds = false;
      });
    }
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
    await prefs.setString('userName', selectedUser);

    setState(() {
      userName = selectedUser;
    });
  }

  Future<void> logoutUser(String selectedUser) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (selectedUser != "") {
      // Just update the necessary fields without clearing everything else.
      await prefs.setBool('theme', isDarkThemeActive);
      await prefs.setString('userName', selectedUser);
      await prefs.setStringList('usersList', usersList);
    } else {
      // If no user is left, remove user-specific keys.
      await prefs.remove('userName');
      await prefs.remove('usersList');
    }

    setState(() {
      userName = selectedUser;
    });

    saveOfflineAthkarList();
  }

  // CHANGED: This function no longer clears all preferences.
  // It now specifically removes the deleted user's report data.
  Future<void> deleteUserName(String selectedUser, String deletedUser) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Update the current user and list of users
    if (selectedUser != "") {
      await prefs.setBool('theme', isDarkThemeActive);
      await prefs.setString('userName', selectedUser);
      await prefs.setStringList('usersList', usersList);
    } else {
      // No users left, remove user-specific keys.
      await prefs.remove('userName');
      await prefs.remove('usersList');
    }

    // Specifically remove the report data for the deleted user.
    await prefs.remove('athkar_completion_data_$deletedUser');

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

    // Remove from userDocIds map
    userDocIds.remove(deletedUser);
  }

  Future<void> _showLogoutConfirmationDialog(
      BuildContext context, int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تسجيل الخروج',
              style: TextStyle(fontFamily: 'Tajawal')),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('هل انت متأكد من تسجيل الخروج من الحساب الحالي؟',
                    style: TextStyle(fontFamily: 'Tajawal')),
                SizedBox(height: 8),
                Text(
                    'سيتم الاحتفاظ بالحساب ويمكنك تسجيل الدخول مرة أخرى باستخدام معرف الحساب فقط.',
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.grey)),
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
              child: const Text('تسجيل الخروج',
                  style:
                      TextStyle(fontFamily: 'Tajawal', color: Colors.orange)),
              onPressed: () async {
                usersList.removeAt(index);
                String newSelectedUser =
                    usersList.isNotEmpty ? usersList.first : "";

                await logoutUser(newSelectedUser).catchError((e) {
                  showExceptionPopup(context, e.toString());
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
              child: const Text('حذف',
                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.red)),
              onPressed: () async {
                String deletedUser = usersList[index];
                usersList.removeAt(index);
                String newSelectedUser =
                    usersList.isNotEmpty ? usersList.first : "";

                await deleteUserName(newSelectedUser, deletedUser)
                    .catchError((e) {
                  showExceptionPopup(context, e.toString());
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

  void _showDocumentIdDialog(String userName, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('معرف حساب $userName',
              style: const TextStyle(fontFamily: 'Tajawal')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('معرف الحساب:',
                  style: TextStyle(
                      fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        documentId,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.teal),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: documentId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                            content: Text('تم نسخ معرف الحساب!',
                                style: TextStyle(fontFamily: 'Tajawal')),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'استخدم هذا المعرف لتسجيل الدخول على أجهزة أخرى',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child:
                  const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal')),
              onPressed: () => Navigator.of(context).pop(),
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
            // Loading indicator for document IDs
            if (_isLoadingDocIds)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('جاري تحميل معرفات الحسابات...',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
                  ],
                ),
              ),

            Expanded(
              child: ListView.separated(
                itemCount: usersList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final name = usersList[index];
                  final hasDocId = userDocIds.containsKey(name);
                  final isCurrentUser = name == userName;

                  return Card(
                    color: isCurrentUser ? Colors.green.shade50 : Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: isCurrentUser
                                ? Colors.teal.shade300
                                : Colors.transparent, // Changed from white
                            width: 2)), // Changed width
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isCurrentUser)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text("المستخدم الحالي",
                                  style: TextStyle(
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.bold)),
                            ),
                          if (hasDocId && !isCurrentUser)
                            const SizedBox(height: 4),
                          if (hasDocId)
                            GestureDetector(
                              onTap: () => _showDocumentIdDialog(
                                  name, userDocIds[name]!),
                              child: Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                // Adjusted padding
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  // Changed from max
                                  children: [
                                    Icon(Icons.fingerprint,
                                        size: 14, color: Colors.blue),
                                    SizedBox(width: 4), // Adjusted spacing
                                    Text(
                                      'عرض معرف الحساب',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (String value) {
                          switch (value) {
                            case 'document_id':
                              if (hasDocId) {
                                _showDocumentIdDialog(name, userDocIds[name]!);
                              }
                              break;
                            case 'logout':
                              _showLogoutConfirmationDialog(context, index);
                              break;
                            case 'delete':
                              _showDeleteConfirmationDialog(context, index);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          List<PopupMenuEntry<String>> items = [];

                          // Document ID option
                          if (hasDocId) {
                            items.add(
                              const PopupMenuItem<String>(
                                value: 'document_id',
                                child: Row(
                                  children: [
                                    Icon(Icons.qr_code,
                                        color: Colors.blue, size: 20),
                                    SizedBox(width: 8),
                                    Text('عرض معرف الحساب',
                                        style:
                                            TextStyle(fontFamily: 'Tajawal')),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Logout option (only for current user)
                          if (isCurrentUser) {
                            items.add(
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout,
                                        color: Colors.orange, size: 20),
                                    SizedBox(width: 8),
                                    Text('تسجيل الخروج',
                                        style:
                                            TextStyle(fontFamily: 'Tajawal')),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Delete option
                          items.add(
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('حذف الحساب',
                                      style: TextStyle(fontFamily: 'Tajawal')),
                                ],
                              ),
                            ),
                          );

                          return items;
                        },
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
                  await loadUserDocumentIds(); // Reload document IDs
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
