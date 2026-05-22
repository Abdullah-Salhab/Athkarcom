import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:math';

import 'quiz_data.dart';
import 'OfflineQuizService.dart';

class OfflineQuizQuestionScreen extends StatefulWidget {
  const OfflineQuizQuestionScreen({super.key});

  @override
  State<OfflineQuizQuestionScreen> createState() => _OfflineQuizQuestionScreenState();
}

class _OfflineQuizQuestionScreenState extends State<OfflineQuizQuestionScreen> {
  late ConfettiController _confettiController;
  QuizQuestion? _question;
  bool _isLoading = true;
  bool _isAnswered = false;
  int? _selectedIdx;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadQuestion();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    List<QuizQuestion> allQuestions = await QuizQuestion.loadQuestions();
    int index = await OfflineQuizService.getTodayQuestionIndex(allQuestions.length);
    setState(() {
      _question = allQuestions[index];
      _isLoading = false;
    });
  }

  void _handleOptionSelected(int index) async {
    if (_isAnswered || _question == null) return;
    
    setState(() {
      _isAnswered = true;
      _selectedIdx = index;
    });

    bool isCorrect = (index == _question!.correctIndex);
    
    // Save locally
    await OfflineQuizService.markQuestionHandled(isCorrect);

    if (isCorrect) {
      _confettiController.play();
    }

    _showResultDialog(isCorrect);
  }

  void _showResultDialog(bool isCorrect) {
    AwesomeDialog(
      context: context,
      dialogType: isCorrect ? DialogType.success : DialogType.error,
      animType: AnimType.scale,
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
      title: isCorrect ? 'إجابة صحيحة! 🎉' : 'إجابة خاطئة',
      desc: isCorrect 
          ? 'أحسنت! كسبت 10 نقاط وزادت شعلتك.\n\n${_question!.explanation}'
          : 'حظاً أوفر غداً! إجابتك الخاطئة أرجعت شعلتك للصفر.\n\nالجواب الصحيح: ${_question!.options[_question!.correctIndex]}\n\n${_question!.explanation}',
      descTextStyle: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      btnOkOnPress: () {
        Navigator.pop(context); // Go back to the main offline screen
      },
      btnOkText: 'حسناً',
      btnOkColor: isCorrect ? Colors.green : Colors.red,
    ).show();
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
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildQuestionBody(),

          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // fall straight down
            maxBlastForce: 5, 
            minBlastForce: 2, 
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBody() {
    if (_question == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.teal, width: 2),
            ),
            child: Text(
              _question!.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ...List.generate(_question!.options.length, (index) {
            String option = _question!.options[index];
            
            Color buttonColor = Theme.of(context).cardColor;
            Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

            if (_isAnswered) {
              if (index == _question!.correctIndex) {
                 buttonColor = Colors.green;
                 textColor = Colors.white;
              } else if (index == _selectedIdx) {
                 buttonColor = Colors.red;
                 textColor = Colors.white;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    // Adding border if light theme to show distinct button
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onPressed: _isAnswered ? null : () => _handleOptionSelected(index),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
