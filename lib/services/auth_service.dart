import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Synthesise email from username for Firebase Auth
  String _toEmail(String username) => '${username.trim().toLowerCase()}@astar.app';

  // ── Register (Aspirant) ─────────────────────────────────────────

  Future<UserModel> registerUser({
    required String name,
    required String username,
    required String password,
    required String role,
    String? email,
    String? phone,
    String? classContext,
  }) async {
    // Check username uniqueness
    final existing = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Username already taken.');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email?.isNotEmpty == true ? email! : _toEmail(username),
      password: password,
    );
    final uid = cred.user!.uid;
    final user = UserModel(
      uid: uid,
      name: name.trim(),
      username: username.trim().toLowerCase(),
      role: role,
      email: email?.trim(),
      phone: phone?.trim(),
      classContext: classContext,
    );
    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }


  // ── Login (Aspirant) ────────────────────────────────────────────

  Future<UserModel> loginUser({
    required String username,
    required String password,
  }) async {
    // Support login with email or username
    String loginEmail;
    
    if (username.contains('@')) {
      loginEmail = username.trim().toLowerCase();
    } else {
      // Smart lookup: Find the actual email associated with this User ID in Firestore
      final snap = await _db
          .collection('users')
          .where('username', isEqualTo: username.trim().toLowerCase())
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final storedEmail = data['email'] as String?;
        // If the user has a real email stored, use it. Otherwise use the synthesized one.
        loginEmail = (storedEmail != null && storedEmail.isNotEmpty)
            ? storedEmail
            : _toEmail(username);
      } else {
        // Fallback: If username doesn't exist in Firestore, use synthesized format
        // so that Firebase Auth can return the correct "user not found" error.
        loginEmail = _toEmail(username);
      }
    }

    final cred = await _auth.signInWithEmailAndPassword(
      email: loginEmail,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User profile not found.');
    return UserModel.fromMap(uid, doc.data()!);
  }

  // ── Admin Login ───────────────────────────────────────────────────────────

  Future<void> loginAdmin({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async => _auth.signOut();

  // ── Username Availability ─────────────────────────────────────────────────

  Future<bool> isUsernameAvailable(String username) async {
    if (username.trim().isEmpty) return false;
    final snap = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isEmpty;
  }

  // ── Super Admins (Emails that always get admin access) ──────────────────────
  static const _superAdmins = [
    'fayaz@gmail.com', 'mdfayaz@gmail.com', 'fayazzz@astar.app', 'admin@astar.app', 'shanmukhasrinulanka@gmail.com'
  ];

  bool _isSuperAdmin(String? email) {
    if (email == null) return false;
    final e = email.trim().toLowerCase();
    return _superAdmins.contains(e) || e.startsWith('admin@');
  }

  // ── Get Current User Profile ──────────────────────────────────────────────

  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    final userEmail = currentUser!.email;

    if (!doc.exists) {
      if (_isSuperAdmin(userEmail)) {
         return UserModel(uid: uid, name: 'Admin', username: userEmail?.split('@').first ?? 'admin', role: 'admin', email: userEmail);
      }
      return null;
    }
    
    final user = UserModel.fromMap(uid, doc.data()!);
    if (_isSuperAdmin(userEmail) || user.role == 'admin' || user.username == 'fayazzz') {
       return UserModel(uid: uid, name: user.name, username: user.username, role: 'admin', email: userEmail, phone: user.phone);
    }
    return user;
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ── Delete Account ────────────────────────────────────────────────────────

  Future<void> deleteUserAccount(String uid) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) throw Exception('No authenticated user found');

    final batch = _db.batch();

    // 1. Delete user profile doc
    batch.delete(_db.collection('users').doc(uid));

    // 2. Clear centralized quiz results
    final quizResults = await _db
        .collection('student_quiz_results')
        .where('studentId', isEqualTo: uid)
        .get();
    for (var doc in quizResults.docs) {
      batch.delete(doc.reference);
    }

    // 3. Clear attendance records
    final attendance = await _db
        .collection('student_attendance')
        .where('studentId', isEqualTo: uid)
        .get();
    for (var doc in attendance.docs) {
      batch.delete(doc.reference);
    }

    // Committing Firestore deletions before Auth deletion
    await batch.commit();

    // 4. Delete Auth account (requires recent login)
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('For security, please logout and log back in before deleting your account.');
      }
      rethrow;
    }
  }
}
