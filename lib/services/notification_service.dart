import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  Future<void> initializeForUser(String userId) async {
    await _messaging.requestPermission();
    await saveCurrentToken(userId);
    await _messaging.subscribeToTopic('report-updates');

    _messaging.onTokenRefresh.listen((token) {
      _saveToken(userId: userId, token: token);
    });
  }

  Future<void> saveCurrentToken(String userId) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _saveToken(userId: userId, token: token);
  }

  Future<void> subscribeToReport(String reportId) {
    return _messaging.subscribeToTopic('report-$reportId');
  }

  Future<void> unsubscribeFromReport(String reportId) {
    return _messaging.unsubscribeFromTopic('report-$reportId');
  }

  Future<void> recordStatusUpdateNotification({
    required String reportId,
    required String reportTitle,
    required String status,
    required String changedBy,
  }) async {
    await _firestore.collection('notifications').add({
      'type': 'classification_update',
      'reportId': reportId,
      'reportTitle': reportTitle,
      'status': status,
      'changedBy': changedBy,
      'topic': 'report-updates',
      'createdAt': FieldValue.serverTimestamp(),
      'requiresBackendPush': true,
    });
  }

  Future<void> _saveToken({required String userId, required String token}) {
    return _firestore.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
