class User {
  final String uid;
  final String email;
  final String role;

  User({required this.uid, required this.email, required this.role});

  factory User.fromMap(String uid, Map<String, dynamic> map) {
    return User(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'driver',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
    };
  }
}
