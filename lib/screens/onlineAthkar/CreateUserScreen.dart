import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../ExceptionDialog.dart';
import '../check_connection.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  CreateUserScreenState createState() => CreateUserScreenState();
}

class CreateUserScreenState extends State<CreateUserScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<String> usersList = [];
  List<String> athkarList = [];
  List<String> athkarCount = [];
  List<String> athkarCurrentCount = [];

  Future<void> _saveUserData(String fullName) async {
    // Save to Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('userName', fullName);
    await saveOfflineAthkarList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    usersList.add(fullName);
    await prefs.setStringList('usersList', usersList);
    // Save to Firestore
    CollectionReference users = FirebaseFirestore.instance.collection('Users');
    await users.add({
      'name': fullName,
      'created_in': DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        DateTime.now().hour,
        DateTime.now().minute,
      ),
      'last_update': DateTime.now().toIso8601String(),
      'points': 0,
      'groupId': '',
      'groupName': ''
    });
    Navigator.of(context).pop();
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

  getUsersList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey('usersList')) {
        usersList = prefs.getStringList('usersList')!;
      }
    });
  }

  saveOfflineAthkarList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('athkarList', athkarList);
    await prefs.setStringList('athkarCount', athkarCount);
    await prefs.setStringList('athkarCurrentCount', athkarCurrentCount);
  }

  Future<bool> _checkIfNameExists(String fullName) async {
    // Check Firestore
    CollectionReference users = FirebaseFirestore.instance.collection('Users');
    var doc = await users.where("name", isEqualTo: fullName).get();
    if (doc.size != 0) {
      return true;
    }

    return false;
  }

  @override
  void initState() {
    getOfflineAthkarList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    getUsersList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة حساب جديد',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22.0,
          ),
        ),
      ),
      body: Container(
        width: 1000,
        margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(.5),
                spreadRadius: 5,
                blurRadius: 5,
                offset: const Offset(0, 3),
              )
            ],
            borderRadius: BorderRadius.circular(10)),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 50,
                  child: Image.asset(
                    'assets/images/App_Icon.jpg',
                  ),
                ),
                const Text(
                  "إنشاء حساب جديد",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "* الاسم الاول"),
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'يرجى إدخال الاسم';
                    }
                    if (usersList.length >= 10) {
                      return 'لقد تجاوزت عدد الحسابات على هذا الجهاز';
                    }
                    return null;
                  },
                  maxLength: 10,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "* الاسم الآخير"),
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'يرجى إدخال الاسم';
                    }
                    if (usersList.length >= 10) {
                      return 'لقد تجاوزت عدد الحسابات على هذا الجهاز';
                    }
                    return null;
                  },
                  maxLength: 10,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        await getConnection(context)) {
                      _formKey.currentState!.save();

                      String firstName = _firstNameController.text.trim();
                      String lastName = _lastNameController.text.trim();
                      String fullName = '$firstName $lastName';

                      bool nameExists =
                          await _checkIfNameExists(fullName).catchError((e) {
                        showExceptionPopup(context, e.toString());
                      });

                      if (nameExists) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('الحساب موجود'),
                              content: const Text(
                                  'يوجد حساب بهذا الاسم يرجى تعديل الاسم'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('حسنا'),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        await _saveUserData(fullName).catchError((e) {
                          showExceptionPopup(context, e.toString());
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('تم إنشاء الحساب بنجاح!'),
                          ),
                        );
                        // You can navigate to another screen here
                      }
                    }
                  },
                  style: ButtonStyle(
                      backgroundColor: MaterialStateColor.resolveWith(
                          (states) => Colors.green)),
                  child: const Text(
                    'إنشاء الحساب',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
