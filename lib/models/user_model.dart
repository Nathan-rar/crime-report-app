import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.photoUrl,
    this.fcmTokens = const [],
  });

  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final String? photoUrl;
  final List<String> fcmTokens;

  factory UserModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return UserModel(
      id: document.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      createdAt: _dateFromValue(data['createdAt']),
      fcmTokens: List<String>.from(data['fcmTokens'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
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
