import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import 'OfflineQuizService.dart';
import 'OfflineQuizQuestionScreen.dart';

class OfflineQuizScreen extends StatefulWidget {
  const OfflineQuizScreen({super.key});

  @override
  State<OfflineQuizScreen> createState() => _OfflineQuizScreenState();
}

class _OfflineQuizScreenState extends State<OfflineQuizScreen> {
  int _score = 0;
  int _streak = 0;
  bool _hasAnsweredToday = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    int score = await OfflineQuizService.getScore();
    int streak = await OfflineQuizService.getStreak();
    bool answeredToday = await OfflineQuizService.hasAnsweredToday();

    setState(() {
      _score = score;
      _streak = streak;
      _hasAnsweredToday = answeredToday;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مسابقة أذكاركم',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Stats Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
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
                            Icons.emoji_events,
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'النقاط',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    '$_score',
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 2,
                                height: 50,
                                color: Colors.white30,
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'الشعلة',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_streak',
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Today's Question Card
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      onTap: _hasAnsweredToday
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.fade,
                                  duration: const Duration(milliseconds: 500),
                                  child: const OfflineQuizQuestionScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          children: [
                            Icon(
                              _hasAnsweredToday
                                  ? Icons.check_circle
                                  : Icons.quiz,
                              size: 70,
                              color: _hasAnsweredToday
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _hasAnsweredToday
                                  ? 'تم الإجابة بنجاح ✅'
                                  : 'سؤال اليوم 📝',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _hasAnsweredToday
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _hasAnsweredToday
                                  ? 'عد غداً للحصول على سؤال جديد'
                                  : 'اضغط للإجابة على سؤال اليوم وزيادة شعلتك',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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

                  const SizedBox(height: 30),
                  
                  // Rules Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Theme.of(context).cardColor.withOpacity(0.5),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                'كيفية اللعب:',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            '• يظهر سؤال واحد جديد كل يوم.\n• الإجابة الصحيحة تمنحك 10 نقاط وتزيد شعلتك.\n• الإجابة الخاطئة تُعيد شعلتك للصفر لكنك تحتفظ بنقاطك.\n• اختبر معلوماتك الدينية يومياً!',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
