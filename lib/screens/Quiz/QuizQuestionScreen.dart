import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';

class QuizQuestionScreen extends StatefulWidget {
  final String questionId;
  final String userName;

  const QuizQuestionScreen({
    super.key,
    required this.questionId,
    required this.userName,
  });

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> with AnalyticsMixin {
  @override
  String get screenName => 'QuizQuestionScreen';

  bool isLoading = true;
  String question = '';
  List<String> options = [];
  int correctAnswer = 0;
  int? selectedAnswer;
  bool hasSubmitted = false;
  int pointsEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    try {
      final questionDoc = await FirebaseFirestore.instance
          .collection('QuizQuestions')
          .doc(widget.questionId)
          .get();

      if (questionDoc.exists) {
        setState(() {
          question = questionDoc.get('question');
          options = List<String>.from(questionDoc.get('options'));
          correctAnswer = questionDoc.get('correctAnswer');
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showExceptionPopup(context, e.toString());
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (selectedAnswer == null) return;

    setState(() {
      hasSubmitted = true;
    });

    try {
      final isCorrect = selectedAnswer == correctAnswer;
      pointsEarned = isCorrect ? 10 : 0;

      // Save answer
      await FirebaseFirestore.instance
          .collection('QuizAnswers')
          .doc('${widget.userName}_${widget.questionId}')
          .set({
        'userName': widget.userName,
        'questionId': widget.questionId,
        'selectedAnswer': selectedAnswer,
        'isCorrect': isCorrect,
        'answeredAt': DateTime.now(),
      });

      // Update user points
      final userDocRef = FirebaseFirestore.instance
          .collection('QuizUsers')
          .doc(widget.userName);

      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        await userDocRef.update({
          'points': FieldValue.increment(pointsEarned),
          'lastAnswered': DateTime.now(),
        });
      } else {
        await userDocRef.set({
          'userName': widget.userName,
          'points': pointsEarned,
          'lastAnswered': DateTime.now(),
          'createdAt': DateTime.now(),
        });
      }

      // Show result dialog
      await _showResultDialog(isCorrect);
    } catch (e) {
      if (mounted) {
        showExceptionPopup(context, e.toString());
      }
    }
  }

  Future<void> _showResultDialog(bool isCorrect) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isCorrect ? 'إجابة صحيحة! 🎉' : 'إجابة خاطئة ❌',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                size: 80,
                color: isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                isCorrect
                    ? 'أحسنت! لقد ربحت $pointsEarned نقطة'
                    : 'الإجابة الصحيحة هي:\n${options[correctAnswer]}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                ),
              ),
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
          'سؤال اليوم',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22.0,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ...List.generate(options.length, (index) {
                final isSelected = selectedAnswer == index;
                final isCorrectOption = index == correctAnswer;
                final showCorrect = hasSubmitted && isCorrectOption;
                final showWrong = hasSubmitted && isSelected && !isCorrectOption;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: InkWell(
                    onTap: hasSubmitted
                        ? null
                        : () {
                      setState(() {
                        selectedAnswer = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: showCorrect
                            ? Colors.green.shade100
                            : showWrong
                            ? Colors.red.shade100
                            : isSelected
                            ? Colors.blue.shade100
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: showCorrect
                              ? Colors.green
                              : showWrong
                              ? Colors.red
                              : isSelected
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: showCorrect
                                  ? Colors.green
                                  : showWrong
                                  ? Colors.red
                                  : isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: isSelected || hasSubmitted
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              options[index],
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (showCorrect)
                            const Icon(Icons.check_circle, color: Colors.green),
                          if (showWrong)
                            const Icon(Icons.cancel, color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 30),
              if (!hasSubmitted)
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedAnswer != null
                          ? Colors.teal
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: selectedAnswer != null ? _submitAnswer : null,
                    child: const Text(
                      'تأكيد الإجابة',
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
    );
  }
}