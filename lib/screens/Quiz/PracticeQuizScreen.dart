import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

import 'quiz_data.dart';
import 'OfflineQuizService.dart';

class PracticeQuizScreen extends StatefulWidget {
  final String category;

  const PracticeQuizScreen({super.key, required this.category});

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  late ConfettiController _confettiController;
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _isAnswered = false;
  int? _selectedIdx;
  bool _isLoading = true;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadCategoryQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryQuestions() async {
    try {
      final all = await QuizQuestion.loadQuestions();
      final filtered = all.where((q) => q.category == widget.category).toList();
      filtered.shuffle();
      setState(() {
        _questions = filtered.take(1).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('خطأ في تحميل الأسئلة: $e'),
          ),
        );
      }
    }
  }

  void _handleOptionSelected(int index) {
    if (_isAnswered) return;

    final isCorrect = (index == _questions[_currentIndex].correctIndex);
    setState(() {
      _isAnswered = true;
      _selectedIdx = index;
      if (isCorrect) {
        _correctCount++;
      }
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswered = false;
        _selectedIdx = null;
      });
    } else {
      // Save results (+2 points per correct answer)
      await OfflineQuizService.addPracticeResult(_correctCount, _questions.length);
      await OfflineQuizService.markPracticeCategoryCompleted(widget.category);
      setState(() {
        _isFinished = true;
      });
      if (_correctCount > 0) {
        _confettiController.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تدريب: ${widget.category}',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isFinished
                  ? _buildSummaryView(isDark)
                  : _buildQuizBody(isDark),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // fall straight down
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizBody(bool isDark) {
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'لا توجد أسئلة متوفرة في هذا القسم.',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar and Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السؤال ${_currentIndex + 1} من ${_questions.length}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              Text(
                'الإجابات الصحيحة: $_correctCount',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 30),

          // Question Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.teal.withOpacity(0.3), width: 2),
            ),
            child: Text(
              currentQuestion.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Options List
          ...List.generate(currentQuestion.options.length, (index) {
            final option = currentQuestion.options[index];
            Color buttonColor = isDark ? Colors.grey.shade900 : Colors.white;
            Color textColor = isDark ? Colors.white : Colors.black87;
            BorderSide borderSide = BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, width: 1.5);

            if (_isAnswered) {
              if (index == currentQuestion.correctIndex) {
                buttonColor = Colors.green.shade600;
                textColor = Colors.white;
                borderSide = BorderSide.none;
              } else if (index == _selectedIdx) {
                buttonColor = Colors.red.shade600;
                textColor = Colors.white;
                borderSide = BorderSide.none;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: InkWell(
                onTap: _isAnswered ? null : () => _handleOptionSelected(index),
                borderRadius: BorderRadius.circular(15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.fromBorderSide(borderSide),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 17,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Explanation Section
          if (_isAnswered) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.blue.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'التفسير والتوضيح:',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentQuestion.explanation,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _nextQuestion,
                icon: const Icon(Icons.arrow_back, color: Colors.white), // Reversed for RTL layout representation
                label: Text(
                  _currentIndex < _questions.length - 1 ? 'السؤال التالي' : 'عرض النتيجة النهائية',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryView(bool isDark) {
    final pointsEarned = _correctCount * 2;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [Colors.teal.shade900, Colors.grey.shade900]
                        : [Colors.teal.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 90,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'اكتمل التدريب! 🎉',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'لقد أجبت بشكل صحيح على',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$_correctCount من ${_questions.length} أسئلة',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.teal.withOpacity(0.3)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          'النقاط المكتسبة: +$pointsEarned نقطة',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '(+2 نقطة لكل إجابة صحيحة في وضع التدريب)',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text(
                  'العودة للقائمة الرئيسية',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
