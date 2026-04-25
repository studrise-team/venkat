import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/question_model.dart';
import '../models/result_model.dart';
import '../models/event_model.dart';

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
    String? subject,
  }) async {
    final docRef = await _firestore.collection(collection).add({
      'title': title.isEmpty ? 'Untitled Quiz' : title,
      'exam': exam,
      'subject': subject,
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
    String? subject,
  }) async {
    await _firestore.collection(collection).doc(quizId).update({
      'title': title.isEmpty ? 'Untitled Quiz' : title,
      'exam': exam,
      'subject': subject,
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
    String? subject,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(collection)
        .where('exam', isEqualTo: exam);
    
    if (subject != null) {
      query = query.where('subject', isEqualTo: subject);
    }

    return query.snapshots().map((snapshot) {
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

  Future<void> saveQuizResult(String quizId, ResultModel result, {String quizTitle = 'Quiz'}) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    
    // Save to centralized collection for dashboards
    await _firestore.collection('student_quiz_results').add({
      'studentId': uid,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'exam': result.examContext,
      'subject': result.subjectContext,
      'score': result.correctAnswers,
      'total': result.totalQuestions,
      'percentage': result.percentage,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    // XP Logic: 10 XP per correct answer
    final xpGained = result.correctAnswers * 10;
    await _firestore.collection('users').doc(uid).update({
      'xp': FieldValue.increment(xpGained),
    });

    // Also keep the individual user's sub-collection
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('results')
        .add({
      'quizId': quizId,
      'quizTitle': quizTitle,
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
      String collection, String exam, {String? subject, String? studentName}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(collection)
        .where('exam', isEqualTo: exam);
    
    if (subject != null) {
      query = query.where('subject', isEqualTo: subject);
    }
    if (studentName != null) {
      query = query.where('studentName', isEqualTo: studentName);
    }

    return query.snapshots()
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

  // ── Materials ─────────────────────────────────────────────────────────────

  Future<void> addMaterial(Map<String, dynamic> data) async {
    await _firestore.collection('materials').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMaterial(String materialId) async {
    await _firestore.collection('materials').doc(materialId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMaterialsStream() {
    return _firestore.collection('materials').orderBy('createdAt', descending: true).snapshots();
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStats() async {
    final snaps = await _firestore.collection('quizzes').get();
    int totalQuestions = 0;
    for (final doc in snaps.docs) {
      totalQuestions += (doc.data()['questionCount'] as int? ?? 0);
    }
    
    // Students Count & Breakdown
    final studentSnaps = await _firestore.collection('users').where('role', isEqualTo: 'student').get();
    
    final Map<String, int> classBreakdown = {};
    for (var doc in studentSnaps.docs) {
      final className = (doc.data() as Map<String, dynamic>)['classContext'] ?? 'Unassigned';
      classBreakdown[className] = (classBreakdown[className] ?? 0) + 1;
    }
    
    return {
      'quizCount': snaps.docs.length,
      'totalQuestions': totalQuestions,
      'studentCount': studentSnaps.docs.length,
      'classBreakdown': classBreakdown,
      'avgScore': 0.0,
    };
  }

  // ── Attendance ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStudentsByClass(String className) async {
    final snap = await _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('classContext', isEqualTo: className)
        .get();
    return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
  }

  Future<void> saveBulkAttendance(List<Map<String, dynamic>> records) async {
    final batch = _firestore.batch();
    for (final record in records) {
      // Check if record for this student on this date and subject already exists to update instead of add
      final existing = await _firestore.collection('student_attendance')
          .where('studentId', isEqualTo: record['studentId'])
          .where('date', isEqualTo: record['date'])
          .where('subject', isEqualTo: record['subject'])
          .get();
      
      if (existing.docs.isNotEmpty) {
        batch.update(existing.docs.first.reference, {
          ...record,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final docRef = _firestore.collection('student_attendance').doc();
        batch.set(docRef, {
          ...record,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getAttendanceStream(String className, {String? studentId, String? subject}) {
    Query query = _firestore.collection('student_attendance').where('exam', isEqualTo: className);
    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    if (subject != null) {
      query = query.where('subject', isEqualTo: subject);
    }
    return query.snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {'id': d.id, ...data};
      }).toList();
    });
  }

  // ── Subjects ─────────────────────────────────────────────────────────────
  
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getSubjects(String exam) {
    return _firestore
        .collection('subjects')
        .where('exam', isEqualTo: exam)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> addSubject(String exam, String subjectName) async {
    await _firestore.collection('subjects').add({
      'exam': exam,
      'name': subjectName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSubject(String subjectId) async {
    await _firestore.collection('subjects').doc(subjectId).delete();
  }

  // ── Events ───────────────────────────────────────────────────────────────

  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> saveEvent(EventModel event) async {
    if (event.id.isEmpty) {
      await _firestore.collection('events').add(event.toMap());
    } else {
      await _firestore.collection('events').doc(event.id).update(event.toMap());
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<String> uploadEventImage(File image) async {
    final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('events/$fileName');
    final uploadTask = await ref.putFile(image);
    return await uploadTask.ref.getDownloadURL();
  }
}
