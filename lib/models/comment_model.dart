import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  const CommentModel({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.userEmail,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String reportId;
  final String userId;
  final String userEmail;
  final String message;
  final DateTime createdAt;

  factory CommentModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return CommentModel(
      id: document.id,
      reportId: data['reportId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'userId': userId,
      'userEmail': userEmail,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
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
