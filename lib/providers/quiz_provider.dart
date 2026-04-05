import 'package:flutter/foundation.dart';
import '../models/question_model.dart';
import '../models/result_model.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';

enum QuizState { idle, loading, ready, active, finished, error }

class QuizProvider extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  QuizState _state = QuizState.idle;
  QuizState get state => _state;

  // ── OCR / Extracted text ──────────────────────────────────────────────────
  String _extractedText = '';
  String get extractedText => _extractedText;

  // ── Questions ─────────────────────────────────────────────────────────────
  List<QuestionModel> _questions = [];
  List<QuestionModel> get questions => _questions;

  // ── Current quiz (Firestore) ──────────────────────────────────────────────
  String _currentQuizId = '';
  String get currentQuizId => _currentQuizId;

  // ── Exam context (set by admin before uploading) ──────────────────────────
  String _currentExam = '';
  String get currentExam => _currentExam;

  String _quizCollection = 'quizzes'; // 'quizzes' or 'daily_quizzes'
  String get quizCollection => _quizCollection;

  void setExamContext(String exam, {String collection = 'quizzes'}) {
    _currentExam = exam;
    _quizCollection = collection;
    notifyListeners();
  }

  // ── Quiz session ──────────────────────────────────────────────────────────
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final Map<int, String> _selectedAnswers = {};
  Map<int, String> get selectedAnswers => Map.unmodifiable(_selectedAnswers);

  // ── Result ────────────────────────────────────────────────────────────────
  ResultModel? _result;
  ResultModel? get result => _result;

  // ── Error ─────────────────────────────────────────────────────────────────
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // ── Save status (for admin feedback) ─────────────────────────────────────
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _savedQuizId;
  String? get savedQuizId => _savedQuizId;

  // ─────────────────────────────────────────────────────────────────────────
  // OCR
  // ─────────────────────────────────────────────────────────────────────────

  void setExtractedText(String text) {
    _extractedText = text;
    _state = QuizState.ready;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Questions
  // ─────────────────────────────────────────────────────────────────────────

  void setQuestions(List<QuestionModel> questions) {
    _questions = questions;
    _currentIndex = 0;
    _selectedAnswers.clear();
    _result = null;
    _state = QuizState.active;
    notifyListeners();
  }

  void setLoading() {
    _state = QuizState.loading;
    notifyListeners();
  }

  void setError(String msg) {
    _errorMessage = msg;
    _state = QuizState.error;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Admin: Save parsed/AI questions to Firestore
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> saveQuestionsToFirestore(String title) async {
    _isSaving = true;
    notifyListeners();
    try {
      final quizId = await FirebaseService().saveQuiz(
        title,
        _questions,
        exam: _currentExam,
        collection: _quizCollection,
      );
      _savedQuizId = quizId;
      _currentQuizId = quizId;
      return quizId;
    } catch (e) {
      _errorMessage = 'Failed to save quiz: $e';
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Student: Load questions from Firestore
  // ─────────────────────────────────────────────────────────────────────────

  String _currentQuizTitle = '';
  String get currentQuizTitle => _currentQuizTitle;

  Future<void> loadQuestionsFromFirestore(String quizId, String quizTitle, {String collection = 'quizzes'}) async {
    _state = QuizState.loading;
    _errorMessage = '';
    _currentQuizTitle = quizTitle;
    notifyListeners();
    try {
      final qs = await FirebaseService().fetchQuizQuestions(quizId, collection: collection);
      if (qs.isEmpty) throw Exception('This quiz has no questions yet.');
      _questions = qs;
      _currentQuizId = quizId;
      _currentIndex = 0;
      _selectedAnswers.clear();
      _result = null;
      _state = QuizState.active;
    } catch (e) {
      _errorMessage = e.toString();
      _state = QuizState.error;
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quiz interaction
  // ─────────────────────────────────────────────────────────────────────────

  void selectAnswer(int questionIndex, String answer) {
    _selectedAnswers[questionIndex] = answer;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void submitQuiz() {
    int correct = 0;
    final records = <AnswerRecord>[];

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selected = _selectedAnswers[i];
      if (selected == q.answer) correct++;
      records.add(AnswerRecord(
        question: q.question,
        options: q.options,
        correctAnswer: q.answer,
        selectedAnswer: selected,
      ));
    }

    final total = _questions.length;
    _result = ResultModel(
      totalQuestions: total,
      correctAnswers: correct,
      wrongAnswers: total - correct,
      percentage: total > 0 ? (correct / total) * 100 : 0,
      answers: records,
      takenAt: DateTime.now(),
    );
    _state = QuizState.finished;
    notifyListeners();

    // Save result to Firestore
    if (_currentQuizId.isNotEmpty) {
      debugPrint('Saving result for quiz: $_currentQuizId');
      FirebaseService()
          .saveQuizResult(_currentQuizId, _result!, quizTitle: _currentQuizTitle)
          .then((_) => debugPrint('Result saved successfully'))
          .catchError((e) {
            debugPrint('CRITICAL: Failed to save result: $e');
            _errorMessage = 'Result could not be saved to cloud. Please contact admin.';
            notifyListeners();
          });
    } else {
      debugPrint('WARNING: No quizId found, result will not be saved to Firestore');
    }
  }

  void resetQuiz() {
    _currentIndex = 0;
    _selectedAnswers.clear();
    _result = null;
    _state = QuizState.active;
    notifyListeners();
  }

  void reset() {
    _extractedText = '';
    _questions = [];
    _currentIndex = 0;
    _selectedAnswers.clear();
    _result = null;
    _errorMessage = '';
    _currentQuizId = '';
    _savedQuizId = null;
    _state = QuizState.idle;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 6: Translate Review results to Telugu
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> translateResultsToTelugu() async {
    if (_result == null) return;

    _state = QuizState.loading;
    notifyListeners();

    try {
      final List<QuestionModel> toTranslate = _result!.answers
          .map((r) => QuestionModel(
                question: r.question,
                options: r.options,
                answer: r.correctAnswer,
              ))
          .toList();

      final translatedQs =
          await ApiService().translateQuestionsToTelugu(toTranslate);

      final newRecords = <AnswerRecord>[];
      for (int i = 0; i < translatedQs.length; i++) {
        final tQ = translatedQs[i];
        final oldR = _result!.answers[i];
        newRecords.add(AnswerRecord(
          question: tQ.question,
          options: tQ.options,
          correctAnswer: tQ.answer,
          selectedAnswer: oldR.selectedAnswer,
        ));
      }

      _result = ResultModel(
        totalQuestions: _result!.totalQuestions,
        correctAnswers: _result!.correctAnswers,
        wrongAnswers: _result!.wrongAnswers,
        percentage: _result!.percentage,
        answers: newRecords,
        takenAt: _result!.takenAt,
      );
      _state = QuizState.finished;
    } catch (e) {
      _errorMessage = 'Translation failed: $e';
      _state = QuizState.error;
    }
    notifyListeners();
  }
}
