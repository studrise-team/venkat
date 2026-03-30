import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';
import '../models/result_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ── Admin: Save Quiz to Firestore ──────────────────────────────────────────

  Future<String> saveQuiz(
    String title,
    List<QuestionModel> questions, {
    String exam = '',
    String collection = 'quizzes',
  }) async {
    final docRef = await _firestore.collection(collection).add({
      'title': title.isEmpty ? 'Untitled Quiz' : title,
      'exam': exam,
      'questionCount': questions.length,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUser?.uid ?? 'admin',
      'questions': questions.map((q) => q.toJson()).toList(),
    });
    return docRef.id;
  }

  // ── Update Quiz ────────────────────────────────────────────────────────────

  Future<void> updateQuiz(
    String quizId,
    String title,
    List<QuestionModel> questions, {
    String exam = '',
    String collection = 'quizzes',
  }) async {
    await _firestore.collection(collection).doc(quizId).update({
      'title': title.isEmpty ? 'Untitled Quiz' : title,
      'exam': exam,
      'questionCount': questions.length,
      'questions': questions.map((q) => q.toJson()).toList(),
    });
  }

  // ── Delete Quiz ────────────────────────────────────────────────────────────

  Future<void> deleteQuiz(String quizId, {String collection = 'quizzes'}) async {
    await _firestore.collection(collection).doc(quizId).delete();
  }

  // ── Fetch Quizzes by Exam ──────────────────────────────────────────────────

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getQuizzesByExam(
    String exam, {
    String collection = 'quizzes',
  }) {
    return _firestore
        .collection(collection)
        .where('exam', isEqualTo: exam)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final t1 = a.data()['createdAt'] as Timestamp?;
        final t2 = b.data()['createdAt'] as Timestamp?;
        if (t1 == null || t2 == null) return 0;
        return t2.compareTo(t1);
      });
      return docs;
    });
  }

  // ── All Quizzes Stream (legacy / aspirant) ─────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> getQuizzesStream() {
    return _firestore
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── Fetch Quiz Questions ───────────────────────────────────────────────────

  Future<List<QuestionModel>> fetchQuizQuestions(
    String quizId, {
    String collection = 'quizzes',
  }) async {
    final doc = await _firestore.collection(collection).doc(quizId).get();
    final data = doc.data();
    if (data == null) throw Exception('Quiz not found.');
    final List raw = data['questions'] ?? [];
    return raw
        .map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q)))
        .toList();
  }

  // ── Student: Save Quiz Result ──────────────────────────────────────────────

  Future<void> saveQuizResult(String quizId, ResultModel result) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('results')
        .add({
      'quizId': quizId,
      'totalQuestions': result.totalQuestions,
      'correctAnswers': result.correctAnswers,
      'percentage': result.percentage,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ── Generic CRUD helpers ───────────────────────────────────────────────────

  Future<String> addDocument(
      String collection, Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection(collection).add(data);
    return ref.id;
  }

  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getDocumentsByExam(
      String collection, String exam) {
    return _firestore
        .collection(collection)
        .where('exam', isEqualTo: exam)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final t1 = a.data()['createdAt'] as Timestamp?;
        final t2 = b.data()['createdAt'] as Timestamp?;
        if (t1 == null || t2 == null) return 0;
        return t2.compareTo(t1);
      });
      return docs;
    });
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStats() async {
    final snaps = await _firestore.collection('quizzes').get();
    int totalQuestions = 0;
    for (final doc in snaps.docs) {
      totalQuestions += (doc.data()['questionCount'] as int? ?? 0);
    }
    return {
      'quizCount': snaps.docs.length,
      'totalQuestions': totalQuestions,
      'avgScore': 0.0,
    };
  }
}
