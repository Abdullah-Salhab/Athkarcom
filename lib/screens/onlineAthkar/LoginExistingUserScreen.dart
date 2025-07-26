import 'package:athkar/screens/ExceptionDialog.dart';
import 'package:athkar/screens/check_connection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../DashboardScreen.dart';

class LoginExistingUserScreen extends StatefulWidget {
  const LoginExistingUserScreen({super.key});

  @override
  State<LoginExistingUserScreen> createState() => _LoginExistingUserScreenState();
}

class _LoginExistingUserScreenState extends State<LoginExistingUserScreen> {
  final TextEditingController _docIdController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getConnection(context);
  }

  @override
  void dispose() {
    _docIdController.dispose();
    super.dispose();
  }

  Future<void> _loginExistingUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String docId = _docIdController.text.trim();

      // Check if the document exists with the provided ID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(docId)
          .get();

      if (!userDoc.exists) {
        _showErrorDialog('معرف المستند غير صحيح', 'لم يتم العثور على حساب بهذا المعرف');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get the user name from the document
      String userName = userDoc.get('name') ?? '';

      // Save user data to SharedPreferences
      await _saveUserData(userName);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          content: Text('تم تسجيل الدخول بنجاح، أهلاً بك $userName',
              style: const TextStyle(fontFamily: 'Tajawal')),
        ),
      );

      // Navigate to Dashboard
      Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 500),
            reverseDuration: const Duration(milliseconds: 500),
            child: const DashboardScreen(),
          ));

    } catch (e) {
      showExceptionPopup(context, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData(String userName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get existing users list
    List<String> usersList = [];
    if (prefs.containsKey('usersList')) {
      usersList = prefs.getStringList('usersList')!;
    }

    // Add user to list if not already exists
    if (!usersList.contains(userName)) {
      usersList.add(userName);
    }

    // Save current user and users list
    await prefs.setString('userName', userName);
    await prefs.setStringList('usersList', usersList);
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontFamily: 'Tajawal')),
          content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
          actions: [
            TextButton(
              child: const Text('موافق', style: TextStyle(fontFamily: 'Tajawal')),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تسجيل دخول حساب موجود',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22.0,
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Welcome message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.person_outline,
                          size: 50,
                          color: Colors.teal),
                      SizedBox(height: 10),
                      Text(
                        'مرحباً بك مرة أخرى',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'الرجاء إدخال معرف حسابك للدخول',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Document ID Field
                TextFormField(
                  controller: _docIdController,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                  decoration: InputDecoration(
                    labelText: 'معرف الحساب',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    prefixIcon: const Icon(Icons.fingerprint, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
                    ),
                    helperText: 'معرف الحساب يمكن الحصول عليه من صفحة الحسابات',
                    helperStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال معرف الحساب';
                    }
                    if (value.trim().length < 10) {
                      return 'معرف الحساب غير صالح';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 50),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginExistingUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'جاري التحقق...',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                      : const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Back button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'العودة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}