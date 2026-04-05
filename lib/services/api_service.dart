import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question_model.dart';

class ApiService {
  // Production backend deployed on Render
  static const String _baseUrl = 'https://astar-ai-backend-1ps9.onrender.com';
  static const _timeout = Duration(seconds: 90);

  /// Send raw OCR text to backend; get back parsed MCQ list.
  Future<List<QuestionModel>> parseQuestions(String rawText) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mcq/parse'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': rawText}),
    ).timeout(_timeout, onTimeout: () => throw Exception(
        'Request timed out. Make sure the backend is running with: uvicorn main:app --reload --host 0.0.0.0'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => QuestionModel.fromJson(e)).toList();
    } else {
      throw Exception('Backend error: ${response.statusCode}');
    }
  }

  /// Send theory text to AI for MCQ generation.
  Future<List<QuestionModel>> generateQuestions(String theoryText) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mcq/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': theoryText}),
    ).timeout(_timeout, onTimeout: () => throw Exception(
        'AI request timed out. Make sure the backend is running with: uvicorn main:app --reload --host 0.0.0.0'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => QuestionModel.fromJson(e)).toList();
    } else {
      String errorMessage = 'Unknown error';
      try {
        final decodedError = jsonDecode(response.body);
        if (decodedError['detail'] != null) {
          errorMessage = decodedError['detail'].toString();
        } else {
          errorMessage = response.body;
        }
      } catch (_) {
        errorMessage = response.body;
      }
      throw Exception('Error ${response.statusCode}: $errorMessage');
    }
  }

  /// Phase 6: Translate English MCQs to Telugu
  Future<List<QuestionModel>> translateQuestionsToTelugu(List<QuestionModel> englishQuestions) async {
    final payload = englishQuestions.map((q) => q.toJson()).toList();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/mcq/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mcqs': payload}),
    ).timeout(_timeout, onTimeout: () => throw Exception(
        'Translation timed out. Make sure backend is reachable.'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List mcqsData = data['data'];
      return mcqsData.map((item) => QuestionModel.fromJson(item)).toList();
    } else {
      throw Exception('Translation error: ${response.statusCode}');
    }
  }
}
