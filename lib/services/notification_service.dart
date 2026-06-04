import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  Future<void> initializeForUser(String userId) async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      await saveCurrentToken(userId);
      await _trySubscribeToTopic('report-updates');

      _messaging.onTokenRefresh.listen((token) {
        _saveToken(userId: userId, token: token);
      });
    } on FirebaseException catch (error) {
      if (_isIgnorableMessagingError(error)) {
        debugPrint('Firebase Messaging skipped: ${error.code}');
        return;
      }
      rethrow;
    }
  }

  Future<void> saveCurrentToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      await _saveToken(userId: userId, token: token);
    } on FirebaseException catch (error) {
      if (_isIgnorableMessagingError(error)) {
        debugPrint('FCM token skipped: ${error.code}');
        return;
      }
      rethrow;
    }
  }

  Future<void> subscribeToReport(String reportId) {
    return _trySubscribeToTopic('report-$reportId');
  }

  Future<void> unsubscribeFromReport(String reportId) async {
    try {
      await _messaging.unsubscribeFromTopic('report-$reportId');
    } on FirebaseException catch (error) {
      if (_isIgnorableMessagingError(error)) {
        debugPrint('FCM unsubscribe skipped: ${error.code}');
        return;
      }
      rethrow;
    }
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

  Future<void> _trySubscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } on FirebaseException catch (error) {
      if (_isIgnorableMessagingError(error)) {
        debugPrint('FCM topic subscribe skipped: ${error.code}');
        return;
      }
      rethrow;
    }
  }

  bool _isIgnorableMessagingError(FirebaseException error) {
    return error.code == 'permission-blocked' ||
        error.code == 'permission-denied' ||
        error.code == 'unsupported-browser' ||
        error.code == 'unsupported-platform' ||
        error.code == 'messaging/unsupported-browser';
  }

  Future<void> _saveToken({required String userId, required String token}) {
    return _firestore.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
