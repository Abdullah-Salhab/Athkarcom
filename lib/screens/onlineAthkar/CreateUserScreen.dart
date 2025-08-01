import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:page_transition/page_transition.dart';

import '../ExceptionDialog.dart';
import '../check_connection.dart';
import 'LoginExistingUserScreen.dart'; // Import the login screen

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
  bool _isLoading = false;
  String? _createdDocumentId; // Store the created document ID

  Future<void> _saveUserData(String fullName) async {
    // Save to Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', fullName);
    await saveOfflineAthkarList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    usersList.add(fullName);
    await prefs.setStringList('usersList', usersList);

    // Save to Firestore and get document reference
    CollectionReference users = FirebaseFirestore.instance.collection('Users');
    DocumentReference docRef = await users.add({
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

    // Store the document ID
    _createdDocumentId = docRef.id;
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

  void _navigateToLogin() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.scale,
        alignment: Alignment.bottomCenter,
        duration: const Duration(milliseconds: 500),
        reverseDuration: const Duration(milliseconds: 500),
        child: const LoginExistingUserScreen(),
      ),
    );
  }

  @override
  void initState() {
    getOfflineAthkarList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    getUsersList().catchError((e) {
      showExceptionPopup(context, e.toString());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة الحسابات',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22.0,
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
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
            child: Column(
              children: [
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 50,
                  child: Image.asset(
                    'assets/images/App_Icon.jpg',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "إدارة الحسابات",
                  style: TextStyle(fontSize: 20, fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 20),

                // Create New Account Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_add,
                                color: Colors.teal, size: 24),
                            SizedBox(width: 10),
                            Text(
                              "إنشاء حساب جديد",
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              labelText: "* الاسم الاول",
                              labelStyle:
                                  const TextStyle(fontFamily: 'Tajawal')),
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
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              labelText: "* الاسم الآخير",
                              labelStyle:
                                  const TextStyle(fontFamily: 'Tajawal')),
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
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate() &&
                                      await getConnection(context)) {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    _formKey.currentState!.save();

                                    String firstName =
                                        _firstNameController.text.trim();
                                    String lastName =
                                        _lastNameController.text.trim();
                                    String fullName = '$firstName $lastName';

                                    bool nameExists =
                                        await _checkIfNameExists(fullName)
                                            .catchError((e) {
                                      showExceptionPopup(context, e.toString());
                                      return true; // Assume exists on error
                                    });

                                    if (nameExists) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('الحساب موجود',
                                                style: TextStyle(
                                                    fontFamily: 'Tajawal')),
                                            content: const Text(
                                                'يوجد حساب بهذا الاسم. هل تريد تسجيل الدخول بدلاً من ذلك؟',
                                                style: TextStyle(
                                                    fontFamily: 'Tajawal')),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  _firstNameController.text =
                                                      "";
                                                  _lastNameController.text = "";
                                                  Navigator.pop(context);
                                                },
                                                child: const Text(
                                                    'إنشاء حساب جديد',
                                                    style: TextStyle(
                                                        fontFamily: 'Tajawal')),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _navigateToLogin();
                                                },
                                                child: const Text('تسجيل دخول',
                                                    style: TextStyle(
                                                        fontFamily: 'Tajawal')),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      await _saveUserData(fullName)
                                          .catchError((e) {
                                        showExceptionPopup(
                                            context, e.toString());
                                      });

                                      setState(() {
                                        _isLoading = false;
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.teal,
                                          content: Text(
                                              'تم إنشاء الحساب بنجاح!',
                                              style: TextStyle(
                                                  fontFamily: 'Tajawal')),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                          style: ButtonStyle(
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.teal)),
                          child: _isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'جاري الإنشاء...',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Tajawal'),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'إنشاء الحساب',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Tajawal'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'أو',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                  ],
                ),

                const SizedBox(height: 20),

                // Login to Existing Account Button
                OutlinedButton.icon(
                  onPressed: _navigateToLogin,
                  icon: const Icon(Icons.login, color: Colors.teal),
                  label: const Text(
                    'تسجيل دخول لحساب موجود',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: BorderSide(color: Colors.teal.shade700, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
