import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';

class AddQuizQuestionScreen extends StatefulWidget {
  const AddQuizQuestionScreen({super.key});

  @override
  State<AddQuizQuestionScreen> createState() => _AddQuizQuestionScreenState();
}

class _AddQuizQuestionScreenState extends State<AddQuizQuestionScreen> with AnalyticsMixin {
  @override
  String get screenName => 'AddQuizQuestionScreen';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
        (index) => TextEditingController(),
  );
  int _correctAnswer = 0;
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      try {
        final questionDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );

        await FirebaseFirestore.instance.collection('QuizQuestions').add({
          'question': _questionController.text.trim(),
          'options': _optionControllers.map((c) => c.text.trim()).toList(),
          'correctAnswer': _correctAnswer,
          'date': Timestamp.fromDate(questionDate),
          'createdAt': DateTime.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                'تم إضافة السؤال بنجاح',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          showExceptionPopup(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة سؤال جديد',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Picker
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text(
                      'تاريخ السؤال',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                    subtitle: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontFamily: 'Tajawal'),
                    ),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 20),

                // Question
                TextFormField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    labelText: 'السؤال',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال السؤال';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Options
                const Text(
                  'الخيارات:',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                ...List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _correctAnswer,
                          onChanged: (value) {
                            setState(() {
                              _correctAnswer = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[index],
                            decoration: InputDecoration(
                              labelText: 'الخيار ${String.fromCharCode(65 + index)}',
                              labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال الخيار';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // Correct Answer Indicator
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'الإجابة الصحيحة: الخيار ${String.fromCharCode(65 + _correctAnswer)}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _saveQuestion,
                    child: const Text(
                      'حفظ السؤال',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        color: Colors.white,
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

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}