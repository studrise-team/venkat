class UserModel {
  final String uid;
  final String name;
  final String username;
  final String role; // 'student' | 'aspirant' | 'admin'
  final String? email;
  final String? phone;
  final String? classLevel;
  final String? address;
  final String? school;
  final bool isApproved;

  const UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.role,
    this.email,
    this.phone,
    this.classLevel,
    this.address,
    this.school,
    this.isApproved = false,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      username: map['username'] as String? ?? '',
      role: map['role'] as String? ?? 'aspirant',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      classLevel: map['classLevel'] as String?,
      address: map['address'] as String?,
      school: map['school'] as String?,
      isApproved: map['isApproved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'username': username,
        'role': role,
        'email': email,
        'phone': phone,
        'classLevel': classLevel,
        'address': address,
        'school': school,
        'isApproved': isApproved,
      };
}
