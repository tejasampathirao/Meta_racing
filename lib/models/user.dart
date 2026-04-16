class User {
  final int? id;
  final String username;
  final String identifier; // email or phone
  final String password;

  User({this.id, required this.username, required this.identifier, required this.password});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'identifier': identifier,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      identifier: map['identifier'],
      password: map['password'],
    );
  }
}
