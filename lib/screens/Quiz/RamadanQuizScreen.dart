import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';

import '../../models/AnalyticsMixin.dart';
import '../ExceptionDialog.dart';
import 'QuizQuestionScreen.dart';
import 'QuizLeaderboardScreen.dart';
import 'AddQuizQuestionScreen.dart';

class RamadanQuizScreen extends StatefulWidget {
  const RamadanQuizScreen({super.key});

  @override
  State<RamadanQuizScreen> createState() => _RamadanQuizScreenState();
}

class _RamadanQuizScreenState extends State<RamadanQuizScreen> with AnalyticsMixin {
  @override
  String get screenName => 'RamadanQuizScreen';

  String userName = "";
  int userPoints = 0;
  bool isLoading = true;
  String? todayQuestionId;
  bool hasAnsweredToday = false;
  bool isQuizAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userName = prefs.getString('userName') ?? '';

      if (userName.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Check if user is a quiz admin
      await _checkIfQuizAdmin();

      // Get user's quiz points
      final userDoc = await FirebaseFirestore.instance
          .collection('QuizUsers')
          .doc(userName)
          .get();

      if (userDoc.exists) {
        userPoints = userDoc.get('points') ?? 0;
      }

      // Check today's question
      await _checkTodayQuestion();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showExceptionPopup(context, e.toString());
      }
    }
  }

  Future<void> _checkIfQuizAdmin() async {
    try {
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('QuizAdmins')
          .where('userName', isEqualTo: userName)
          .limit(1)
          .get();

      setState(() {
        isQuizAdmin = adminSnapshot.docs.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        isQuizAdmin = false;
      });
    }
  }

  Future<void> _checkTodayQuestion() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final questionSnapshot = await FirebaseFirestore.instance
        .collection('QuizQuestions')
        .where('date', isEqualTo: Timestamp.fromDate(todayDate))
        .limit(1)
        .get();

    if (questionSnapshot.docs.isNotEmpty) {
      todayQuestionId = questionSnapshot.docs.first.id;

      // Check if user already answered
      final userAnswerDoc = await FirebaseFirestore.instance
          .collection('QuizAnswers')
          .doc('${userName}_$todayQuestionId')
          .get();

      hasAnsweredToday = userAnswerDoc.exists;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مسابقة أذكاركم اليومية',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22.0,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isQuizAdmin)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    duration: const Duration(milliseconds: 500),
                    child: const AddQuizQuestionScreen(),
                  ),
                ).then((_) => _loadUserData());
              },
              icon: const Icon(Icons.add_circle),
              tooltip: 'إضافة سؤال',
              iconSize: 28,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userName.isEmpty
          ? const Center(
        child: Text(
          'يرجى تسجيل الدخول أولاً',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
          ),
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Admin Badge (if admin)
              if (isQuizAdmin)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'مسؤول المسابقة 👑',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              // User Stats Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 30,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$userPoints نقطة',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Today's Question Card
              if (todayQuestionId != null)
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: hasAnsweredToday
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          duration: const Duration(milliseconds: 500),
                          child: QuizQuestionScreen(
                            questionId: todayQuestionId!,
                            userName: userName,
                          ),
                        ),
                      ).then((_) => _loadUserData());
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Icon(
                            hasAnsweredToday
                                ? Icons.check_circle
                                : Icons.quiz,
                            size: 60,
                            color: hasAnsweredToday
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            hasAnsweredToday
                                ? 'تم الإجابة على سؤال اليوم ✅'
                                : 'سؤال اليوم 📝',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: hasAnsweredToday
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          if (!hasAnsweredToday)
                            const SizedBox(height: 10),
                          if (!hasAnsweredToday)
                            const Text(
                              'اضغط للإجابة الآن',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (todayQuestionId == null)
                const Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(25.0),
                    child: Text(
                      'لا يوجد سؤال اليوم\nتابع غداً إن شاء الله',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Admin Button - Add Question
              if (isQuizAdmin)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.bottomToTop,
                          duration: const Duration(milliseconds: 500),
                          child: const AddQuizQuestionScreen(),
                        ),
                      ).then((_) => _loadUserData());
                    },
                    icon: const Icon(
                      Icons.add_box,
                      color: Colors.white,
                      size: 30,
                    ),
                    label: const Text(
                      'إضافة سؤال جديد',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              if (isQuizAdmin)
                const SizedBox(height: 20),

              // Leaderboard Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 500),
                        child: const QuizLeaderboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.leaderboard,
                    color: Colors.white,
                    size: 30,
                  ),
                  label: const Text(
                    'لوحة المتصدرين',
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