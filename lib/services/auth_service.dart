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

  // ── Register (Student / Aspirant) ─────────────────────────────────────────

  Future<UserModel> registerUser({
    required String name,
    required String username,
    required String password,
    required String role,
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
      email: _toEmail(username),
      password: password,
    );
    final uid = cred.user!.uid;
    final user = UserModel(
      uid: uid,
      name: name.trim(),
      username: username.trim().toLowerCase(),
      role: role,
    );
    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  // ── Login (Student / Aspirant) ────────────────────────────────────────────

  Future<UserModel> loginUser({
    required String username,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: _toEmail(username),
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

  // ── Get Current User Profile ──────────────────────────────────────────────

  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    // Admin check — any email not ending in @astar.app is treated as an Admin
    final email = currentUser!.email ?? '';
    if (!email.endsWith('@astar.app')) {
      return UserModel(
          uid: uid,
          name: 'Admin',
          username: email.split('@').first,
          role: 'admin');
    }

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }
}
