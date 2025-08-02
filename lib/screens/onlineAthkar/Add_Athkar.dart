import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';
import '../check_connection.dart';

class AddAthkarScreen extends StatefulWidget {
  final String groupId;

  const AddAthkarScreen({super.key, required final this.groupId});

  @override
  AddAthkarScreenState createState() => AddAthkarScreenState();
}

class AddAthkarScreenState extends State<AddAthkarScreen> with AnalyticsMixin{
  @override
  String get screenName => 'AddGroupAthkarScreen';

  final TextEditingController _countController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _addObject() async {
    final now = DateTime.now();
    final dateToday = DateTime(now.year, now.month, now.day);

    final CollectionReference objects = FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupId)
        .collection("Athkars");

    await objects.add({
      'count': int.parse(_countController.text),
      'content': _contentController.text,
      'value': _valueController.text,
      'users': [],
      'date': dateToday,
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة ذكر جماعي'),
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
                  controller: _contentController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "* الذكر"),
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'يرجى إدخال الذكر';
                    }
                    return null;
                  },
                  maxLength: 100,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _countController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "* العدد"),
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'يرجى إدخال العدد';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: "الفضل"),
                  maxLength: 150,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate() &
                          await getConnection(context)) {
                        _formKey.currentState!.save();
                        _addObject().catchError((e) {
                          showExceptionPopup(context, e.toString());
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text(
                      'إضافة الذكر',
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
