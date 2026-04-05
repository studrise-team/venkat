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
    String? email,
    String? phone,
    String? classLevel,
    String? address,
    String? school,
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
      classLevel: classLevel?.trim(),
      address: address?.trim(),
      school: school?.trim(),
      isApproved: role != 'student', // Students need approval, others (aspirant) don't for now
    );
    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  // ── Login (Student / Aspirant) ────────────────────────────────────────────

  Future<UserModel> loginUser({
    required String username,
    required String password,
  }) async {
    // Support login with email or username
    String loginEmail;
    if (username.contains('@')) {
      loginEmail = username.trim().toLowerCase();
    } else {
      loginEmail = _toEmail(username);
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
}
