// lib/models/user_data.dart

class UserData {
  final String id;
  final String displayName;
  final String email;

  UserData({
    required this.id,
    required this.displayName,
    required this.email,
  });

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
    };
  }
}
