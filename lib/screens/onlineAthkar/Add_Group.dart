import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ExceptionDialog.dart';
import '../check_connection.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  AddGroupScreenState createState() => AddGroupScreenState();
}

class AddGroupScreenState extends State<AddGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String userName = "";
  final _formKey = GlobalKey<FormState>();

  Future<void> _addGroup() async {
    final now = DateTime.now();
    final dateToday = DateTime(
        now.year, now.month, now.day, now.hour, now.minute, now.second);

    final CollectionReference objects =
        FirebaseFirestore.instance.collection('Groups');
    await getUserName();
    final docRef = await objects.add({
      'name': _nameController.text,
      'desc': _descController.text,
      'members': {userName: true},
      'createdAt': dateToday,
      'createdBy': userName,
    });
    // Now create a sub collection named 'Athkars'
    docRef.collection('Athkars');
    print(docRef.id);
    var userQuerySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where("name", isEqualTo: userName)
        .get();
    // set group id to the user
    if (userQuerySnapshot.docs.isNotEmpty) {
      if (userQuerySnapshot.docs.length == 1 &&
          userQuerySnapshot.docs.first.get('groupId') == '') {
        var userDocument = userQuerySnapshot.docs.first;
        await userDocument.reference.update({'groupId': docRef.id});
      } else {
        // create new user with the group id
        CollectionReference users =
            FirebaseFirestore.instance.collection('Users');
        await users.add({
          'name': userName,
          'created_in': DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            DateTime.now().hour,
            DateTime.now().minute,
          ),
          'last_login': DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            DateTime.now().hour,
            DateTime.now().minute,
          ),
          'last_update': DateTime.now().toIso8601String(),
          'points': 0,
          'groupId': docRef.id,
          'groupName':_nameController.text
        });
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('تم إنشاء المجموعة بنجاح'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة مجموعة'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "* اسم المجموعة"),
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'يرجى إدخال الاسم';
                    }
                    return null;
                  },
                  maxLength: 20,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "* الوصف"),
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'يرجى إدخال وصف للمجموعة';
                    }
                    return null;
                  },
                  maxLength: 100,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate() &
                          await getConnection(context)) {
                        _formKey.currentState!.save();
                        _addGroup().catchError((e) {
                          showExceptionPopup(context, e.toString());
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'إنشاء المجموعة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Tajawal',
                      ),
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
