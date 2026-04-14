class UserModel {
  final String uid;
  final String name;
  final String username;
  final String role; // 'aspirant' | 'admin' | 'student'
  final String? email;
  final String? phone;
  final String? classContext;

  const UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.role,
    this.email,
    this.phone,
    this.classContext,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      username: map['username'] as String? ?? '',
      role: map['role'] as String? ?? 'aspirant',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      classContext: map['classContext'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'username': username,
        'role': role,
        'email': email,
        'phone': phone,
        'classContext': classContext,
      };
}
