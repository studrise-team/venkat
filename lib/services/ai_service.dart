import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  GenerativeModel? _model;
  String? _apiKey;

  Future<void> _initModel() async {
    if (_model != null) return;
    
    // Try getting API key from Firestore 'settings'
    final settings = await FirebaseFirestore.instance.collection('settings').doc('ai').get();
    _apiKey = settings.data()?['geminiKey'];

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey!);
    }
  }

  Future<String> askAI(String prompt) async {
    try {
      await _initModel();
      if (_model == null) return "AI Study Partner is not configured yet. Admin needs to set the Gemini API Key.";
      
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? "Sorry, I couldn't process that.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  Future<void> updateApiKey(String key) async {
    await FirebaseFirestore.instance.collection('settings').doc('ai').set({
      'geminiKey': key,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _apiKey = key;
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey!);
  }
}
