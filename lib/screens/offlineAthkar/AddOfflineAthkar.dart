import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddOfflineAthkarScreen extends StatefulWidget {
  const AddOfflineAthkarScreen({super.key});

  @override
  _AddOfflineAthkarScreenState createState() => _AddOfflineAthkarScreenState();
}

class _AddOfflineAthkarScreenState extends State<AddOfflineAthkarScreen> {
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<String> athkarList = [];
  List<String> athkarCount = [];

  @override
  void initState() {
    getAthkarList();
  }

  addToAthkarList() async {
    setState(() {
      athkarList.add(_contentController.text);
      athkarCount.add(_countController.text);
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('athkarList', athkarList);
    await prefs.setStringList('athkarCount', athkarCount);
    Navigator.of(context).pop();
  }

  getAthkarList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey('athkarList') && prefs.containsKey('athkarCount')) {
        athkarList = prefs.getStringList('athkarList')!;
        athkarCount = prefs.getStringList('athkarCount')!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة ذكر'),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      addToAthkarList();
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
