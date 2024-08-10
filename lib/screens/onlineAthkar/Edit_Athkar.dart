import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAthkarScreen extends StatefulWidget {
  final String objectId;

  const EditAthkarScreen({super.key, required this.objectId});

  @override
  _EditAthkarScreenState createState() => _EditAthkarScreenState();
}

class _EditAthkarScreenState extends State<EditAthkarScreen> {
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchObject();
  }

  Future<void> _fetchObject() async {
    final objectRef = FirebaseFirestore.instance
        .collection('athkar_group')
        .doc(widget.objectId);
    final objectSnapshot = await objectRef.get();

    final objectData = objectSnapshot.data() as Map<String, dynamic>;

    setState(() {
      _countController.text = objectData['count'].toString();
      _contentController.text = objectData['content'];
      _valueController.text = objectData['value'];
    });
  }

  Future<void> _updateObject() async {
    final collection = FirebaseFirestore.instance.collection('athkar_group');

    final objectRef = FirebaseFirestore.instance
        .collection('athkar_group')
        .doc(widget.objectId);

    var object = await objectRef.get();
    final date = object.get("date");
    // Create new one for not use old cash count
    collection.add({
      'count': int.parse(_countController.text),
      'content': _contentController.text,
      'value': _valueController.text,
      'date': date,
      'users': [],
    });
    await objectRef.delete();

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل الذكر'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
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
              SizedBox(
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
              SizedBox(
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
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _updateObject();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'تعديل الذكر',
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
