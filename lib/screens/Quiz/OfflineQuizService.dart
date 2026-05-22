import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OfflineQuizService {
  static const String SCORE_KEY = 'offline_quiz_score';
  static const String STREAK_KEY = 'offline_quiz_streak';
  static const String LAST_ANSWERED_DATE_KEY = 'offline_quiz_last_answered';
  static const String CURRENT_QUESTION_INDEX_KEY = 'offline_quiz_current_q_index';
  static const String CURRENT_QUESTION_DATE_KEY = 'offline_quiz_current_q_date';

  static Future<int> getScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(SCORE_KEY) ?? 0;
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(STREAK_KEY) ?? 0;
  }

  static String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static Future<bool> hasAnsweredToday() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastAnswered = prefs.getString(LAST_ANSWERED_DATE_KEY);
    return lastAnswered == _getTodayDateString();
  }

  static Future<int> getTodayQuestionIndex(int totalQuestions) async {
    final prefs = await SharedPreferences.getInstance();
    final todayDate = _getTodayDateString();
    
    String? assignedDate = prefs.getString(CURRENT_QUESTION_DATE_KEY);
    int? currentIndex = prefs.getInt(CURRENT_QUESTION_INDEX_KEY);
    
    if (assignedDate == todayDate && currentIndex != null) {
      return currentIndex; // We already generated an index for today
    }
    
    // Otherwise, generate a new random index
    final random = Random();
    int newIndex = random.nextInt(totalQuestions);
    
    await prefs.setString(CURRENT_QUESTION_DATE_KEY, todayDate);
    await prefs.setInt(CURRENT_QUESTION_INDEX_KEY, newIndex);
    
    return newIndex;
  }

  static Future<void> markQuestionHandled(bool isCorrect) async {
    final prefs = await SharedPreferences.getInstance();
    final todayDate = _getTodayDateString();
    
    await prefs.setString(LAST_ANSWERED_DATE_KEY, todayDate);
    
    if (isCorrect) {
      int score = await getScore();
      int streak = await getStreak();
      await prefs.setInt(SCORE_KEY, score + 10); // Reward: 10 points
      await prefs.setInt(STREAK_KEY, streak + 1);
    } else {
      // Wrong answer resets the streak to 0, but retains the score
      await prefs.setInt(STREAK_KEY, 0);
    }
  }
}
