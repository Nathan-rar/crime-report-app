import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.role = UserRole.user,
    this.photoUrl,
    this.fcmTokens = const [],
  });

  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final UserRole role;
  final String? photoUrl;
  final List<String> fcmTokens;

  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return UserModel.fromMap(document.id, document.data() ?? {});
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: UserRole.fromValue(data['role'] as String?),
      photoUrl: data['photoUrl'] as String?,
      createdAt: _dateFromValue(data['createdAt']),
      fcmTokens: List<String>.from(data['fcmTokens'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.value,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'fcmTokens': fcmTokens,
    };
  }

  static DateTime _dateFromValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }
}

enum UserRole {
  user('user'),
  admin('admin');

  const UserRole(this.value);

  final String value;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value || role.name == value,
      orElse: () => UserRole.user,
    );
  }
}
