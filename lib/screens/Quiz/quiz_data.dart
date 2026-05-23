import 'dart:convert';
import 'package:flutter/services.dart';

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  String get category {
    const quran = {1, 3, 5, 7, 8, 11, 15, 17, 23, 25, 34, 35, 36, 40, 44, 48, 50, 52, 60, 63, 67, 74, 77, 79, 81, 83, 86, 92};
    const seerah = {10, 13, 16, 18, 19, 21, 22, 26, 28, 30, 38, 42, 43, 45, 53, 54, 55, 56, 57, 68, 70, 71, 89, 94, 95, 99};
    const prophetsCompanions = {2, 4, 6, 12, 14, 24, 27, 29, 31, 32, 37, 39, 46, 51, 58, 59, 64, 69, 72, 73, 76, 80, 84, 87, 91, 98, 100};

    if (quran.contains(id)) {
      return 'القرآن الكريم';
    } else if (seerah.contains(id)) {
      return 'السيرة النبوية';
    } else if (prophetsCompanions.contains(id)) {
      return 'الأنبياء والصحابة';
    } else {
      return 'العقيدة والفقه';
    }
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctIndex: json['correctIndex'],
      explanation: json['explanation'],
    );
  }

  static Future<List<QuizQuestion>> loadQuestions() async {
    final String response = await rootBundle.loadString('assets/database/quiz_questions.json');
    final data = await json.decode(response);
    return (data as List).map((e) => QuizQuestion.fromJson(e)).toList();
  }
}
