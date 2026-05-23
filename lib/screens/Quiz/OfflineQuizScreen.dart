import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import 'OfflineQuizService.dart';
import 'OfflineQuizQuestionScreen.dart';
import 'PracticeQuizScreen.dart';

class OfflineQuizScreen extends StatefulWidget {
  const OfflineQuizScreen({super.key});

  @override
  State<OfflineQuizScreen> createState() => _OfflineQuizScreenState();
}

class _OfflineQuizScreenState extends State<OfflineQuizScreen> {
  int _score = 0;
  int _streak = 0;
  int _correctCount = 0;
  int _totalAnswered = 0;
  bool _hasAnsweredToday = false;
  Map<String, bool> _completedPracticeToday = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    int score = await OfflineQuizService.getScore();
    int streak = await OfflineQuizService.getStreak();
    int correctCount = await OfflineQuizService.getCorrectCount();
    int totalAnswered = await OfflineQuizService.getTotalAnsweredCount();
    bool answeredToday = await OfflineQuizService.hasAnsweredToday();

    final categories = ['القرآن الكريم', 'السيرة النبوية', 'الأنبياء والصحابة', 'العقيدة والفقه'];
    Map<String, bool> completedPractice = {};
    for (var cat in categories) {
      completedPractice[cat] = await OfflineQuizService.hasCompletedPracticeToday(cat);
    }

    setState(() {
      _score = score;
      _streak = streak;
      _correctCount = correctCount;
      _totalAnswered = totalAnswered;
      _hasAnsweredToday = answeredToday;
      _completedPracticeToday = completedPractice;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مسابقة أذكاركم',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Premium Stats Card
                    _buildStatsCard(isDark),
                    const SizedBox(height: 25),

                    // Today's Question Card
                    _buildTodayQuestionCard(isDark),
                    const SizedBox(height: 25),

                    // Achievements Section
                    _buildAchievementsSection(isDark),
                    const SizedBox(height: 30),

                    // Practice Section
                    _buildPracticeSection(isDark),
                    const SizedBox(height: 30),

                    // Rules Card
                    _buildRulesCard(isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.teal, Colors.tealAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('النقاط الإجمالية', '$_score', Icons.emoji_events, Colors.amber),
                Container(
                  width: 1.5,
                  height: 45,
                  color: Colors.white30,
                ),
                _buildStatItem('سلسلة الحماس', '$_streak', Icons.local_fire_department, Colors.orange),
                Container(
                  width: 1.5,
                  height: 45,
                  color: Colors.white30,
                ),
                _buildStatItem('الإجابات الصحيحة', '$_correctCount/$_totalAnswered', Icons.check_circle, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayQuestionCard(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hasAnsweredToday ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
              width: 1.5,
            ),
            color: _hasAnsweredToday 
                ? Colors.green.withOpacity(0.05) 
                : Colors.orange.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hasAnsweredToday ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _hasAnsweredToday ? Icons.check_circle : Icons.quiz,
                  size: 40,
                  color: _hasAnsweredToday ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasAnsweredToday ? 'تمت الإجابة اليوم! ✅' : 'سؤال اليوم اليومي 📝',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _hasAnsweredToday ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasAnsweredToday
                          ? 'أحسنت صنعاً! عد غداً للحصول على سؤال جديد.'
                          : 'اضغط لحل تحدي اليوم وزيادة نقاطك وشعلتك!',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_hasAnsweredToday)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.orange,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(bool isDark) {
    final List<Map<String, dynamic>> badges = [
      {
        'title': 'المبتدئ',
        'desc': 'حل سؤال صحيح',
        'icon': Icons.emoji_events,
        'unlocked': _correctCount >= 1,
        'color': Colors.amber,
      },
      {
        'title': 'المثابر',
        'desc': 'سلسلة حماس ٣ أيام',
        'icon': Icons.local_fire_department,
        'unlocked': _streak >= 3,
        'color': Colors.orange,
      },
      {
        'title': 'المتميز',
        'desc': 'سلسلة حماس ٧ أيام',
        'icon': Icons.workspace_premium,
        'unlocked': _streak >= 7,
        'color': Colors.purple,
      },
      {
        'title': 'المثقف',
        'desc': '٢٥ إجابة صحيحة',
        'icon': Icons.psychology,
        'unlocked': _correctCount >= 25,
        'color': Colors.teal,
      },
      {
        'title': 'الخبير',
        'desc': 'جمع ١٠٠ نقطة',
        'icon': Icons.star,
        'unlocked': _score >= 100,
        'color': Colors.blue,
      },
      {
        'title': 'العلاّمة',
        'desc': '٥٠ إجابة صحيحة',
        'icon': Icons.auto_stories,
        'unlocked': _correctCount >= 50,
        'color': Colors.deepPurple,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.military_tech, color: Colors.teal, size: 26),
            SizedBox(width: 8),
            Text(
              'أوسمتك وإنجازاتك',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            final unlocked = badge['unlocked'] as bool;
            return Card(
              elevation: unlocked ? 3 : 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: unlocked 
                  ? (isDark ? Colors.grey.shade900 : Colors.white)
                  : (isDark ? const Color(0xFF151515) : Colors.grey.shade100),
              child: Opacity(
                opacity: unlocked ? 1.0 : 0.45,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: unlocked 
                              ? (badge['color'] as Color).withOpacity(0.1) 
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          badge['icon'] as IconData,
                          size: 28,
                          color: unlocked ? badge['color'] as Color : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: unlocked 
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge['desc'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPracticeSection(bool isDark) {
    final List<Map<String, dynamic>> categories = [
      {
        'title': 'القرآن الكريم',
        'icon': Icons.menu_book,
        'color': Colors.blue,
      },
      {
        'title': 'السيرة النبوية',
        'icon': Icons.mosque,
        'color': Colors.teal,
      },
      {
        'title': 'الأنبياء والصحابة',
        'icon': Icons.people,
        'color': Colors.orange,
      },
      {
        'title': 'العقيدة والفقه',
        'icon': Icons.gavel,
        'color': Colors.purple,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.fitness_center, color: Colors.teal, size: 26),
            SizedBox(width: 8),
            Text(
              'التدريب الحر والأقسام',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final title = cat['title'] as String;
            final color = cat['color'] as Color;
            final isCompleted = _completedPracticeToday[title] ?? false;

            return Card(
              elevation: isCompleted ? 1 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: isCompleted
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            duration: const Duration(milliseconds: 500),
                            child: PracticeQuizScreen(category: title),
                          ),
                        ).then((_) => _loadData());
                      },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [
                              Colors.grey.withOpacity(0.12),
                              Colors.grey.withOpacity(0.02),
                            ]
                          : [
                              color.withOpacity(0.12),
                              color.withOpacity(0.02),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_outline : cat['icon'] as IconData,
                        size: 32,
                        color: isCompleted ? Colors.green : color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'اكتمل اليوم ✅',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRulesCard(bool isDark) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: isDark ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade100,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text(
                  'شروط وقوانين المسابقة:',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• تحدي اليوم يمنحك +١٠ نقاط ويزيد سلسلة حماسك بمقدار يوم.\n• الإجابة الخاطئة في التحدي اليومي تصفر سلسلة الحماس لديك.\n• التدريب الحر يمنحك سؤالاً واحداً فقط من كل قسم يومياً، ويمنحك +٢ نقطة عند الإجابة الصحيحة لتنشيط معلوماتك الدينية.',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                height: 1.5,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
