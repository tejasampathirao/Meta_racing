class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role; // 'user' or 'admin'
  final String? lastLoginTime;

  User({
    this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.password,
    this.role = 'user',
    this.lastLoginTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'last_login_time': lastLoginTime,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'] ?? '',
      password: map['password'],
      role: map['role'] ?? 'user',
      lastLoginTime: map['last_login_time'],
    );
  }

  bool get isAdmin => role == 'admin';
}
