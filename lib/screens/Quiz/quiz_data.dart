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
