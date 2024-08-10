import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddAthkarScreen extends StatefulWidget {
  const AddAthkarScreen({super.key});

  @override
  _AddAthkarScreenState createState() => _AddAthkarScreenState();
}

class _AddAthkarScreenState extends State<AddAthkarScreen> {
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _addObject() async {
    final now = DateTime.now();
    final dateToday = DateTime(now.year, now.month, now.day);

    final CollectionReference objects =
        FirebaseFirestore.instance.collection('athkar_group');

    var documentReference = await objects.add({
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              ),
              const SizedBox(
                height: 20,
              ),
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
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _addObject();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
    );
  }
}
