import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OfflineQuizService {
  static const String SCORE_KEY = 'offline_quiz_score';
  static const String STREAK_KEY = 'offline_quiz_streak';
  static const String LAST_ANSWERED_DATE_KEY = 'offline_quiz_last_answered';
  static const String CURRENT_QUESTION_INDEX_KEY = 'offline_quiz_current_q_index';
  static const String CURRENT_QUESTION_DATE_KEY = 'offline_quiz_current_q_date';
  static const String CORRECT_COUNT_KEY = 'offline_quiz_correct_count';
  static const String TOTAL_ANSWERED_KEY = 'offline_quiz_total_answered';

  static Future<int> getScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(SCORE_KEY) ?? 0;
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(STREAK_KEY) ?? 0;
  }

  static Future<int> getCorrectCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(CORRECT_COUNT_KEY) ?? 0;
  }

  static Future<int> getTotalAnsweredCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(TOTAL_ANSWERED_KEY) ?? 0;
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
    
    int correctCount = prefs.getInt(CORRECT_COUNT_KEY) ?? 0;
    int totalAnswered = prefs.getInt(TOTAL_ANSWERED_KEY) ?? 0;
    await prefs.setInt(TOTAL_ANSWERED_KEY, totalAnswered + 1);

    if (isCorrect) {
      int score = await getScore();
      int streak = await getStreak();
      await prefs.setInt(SCORE_KEY, score + 10); // Reward: 10 points
      await prefs.setInt(STREAK_KEY, streak + 1);
      await prefs.setInt(CORRECT_COUNT_KEY, correctCount + 1);
    } else {
      // Wrong answer resets the streak to 0, but retains the score
      await prefs.setInt(STREAK_KEY, 0);
    }
  }

  static Future<void> addPracticeResult(int correct, int total) async {
    final prefs = await SharedPreferences.getInstance();
    int currentScore = prefs.getInt(SCORE_KEY) ?? 0;
    int currentCorrect = prefs.getInt(CORRECT_COUNT_KEY) ?? 0;
    int currentTotal = prefs.getInt(TOTAL_ANSWERED_KEY) ?? 0;

    await prefs.setInt(SCORE_KEY, currentScore + (correct * 2));
    await prefs.setInt(CORRECT_COUNT_KEY, currentCorrect + correct);
    await prefs.setInt(TOTAL_ANSWERED_KEY, currentTotal + total);
  }

  static Future<bool> hasCompletedPracticeToday(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    final lastDate = prefs.getString('practice_completed_date_$category');
    return lastDate == today;
  }

  static Future<void> markPracticeCategoryCompleted(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    await prefs.setString('practice_completed_date_$category', today);
  }
}
