import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/comment_model.dart';
import '../models/report_model.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  Stream<List<ReportModel>> streamReports() {
    return _reports.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(ReportModel.fromDocument).toList(),
        );
  }

  Stream<ReportModel> streamReport(String reportId) {
    return _reports.doc(reportId).snapshots().map((document) {
      return ReportModel.fromDocument(document);
    });
  }

  Future<ReportModel?> getReport(String reportId) async {
    final document = await _reports.doc(reportId).get();
    if (!document.exists) {
      return null;
    }
    return ReportModel.fromDocument(document);
  }

  Future<String> createReport({
    required String title,
    required String description,
    required String category,
    XFile? image,
    Position? position,
  }) async {
    final user = _requireUser();
    final doc = _reports.doc();
    String? imageUrl;

    if (image != null) {
      imageUrl = await _storageService.uploadReportPhoto(
        file: image,
        reportId: doc.id,
      );
    }

    final now = DateTime.now();
    final report = ReportModel(
      id: doc.id,
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      reporterId: user.uid,
      reporterEmail: user.email ?? '-',
      status: ReportStatus.belum,
      imageUrl: imageUrl,
      latitude: position?.latitude,
      longitude: position?.longitude,
      createdAt: now,
      updatedAt: now,
    );

    await doc.set(report.toMap());
    await _notificationService.subscribeToReport(doc.id);
    return doc.id;
  }

  Future<void> updateReport({
    required String reportId,
    required String title,
    required String description,
    required String category,
    XFile? image,
    Position? position,
  }) async {
    String? imageUrl;
    if (image != null) {
      imageUrl = await _storageService.uploadReportPhoto(
        file: image,
        reportId: reportId,
      );
    }

    final data = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }
    if (position != null) {
      data['latitude'] = position.latitude;
      data['longitude'] = position.longitude;
    }

    await _reports.doc(reportId).update(data);
  }

  Future<void> updateStatus({
    required ReportModel report,
    required ReportStatus status,
  }) async {
    final user = _requireUser();

    await _reports.doc(report.id).update({
      'status': status.label,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.recordStatusUpdateNotification(
      reportId: report.id,
      reportTitle: report.title,
      status: status.label,
      changedBy: user.email ?? user.uid,
    );
  }

  Future<void> deleteReport(ReportModel report) async {
    final comments = await _reports.doc(report.id).collection('comments').get();
    final batch = _firestore.batch();

    for (final comment in comments.docs) {
      batch.delete(comment.reference);
    }
    batch.delete(_reports.doc(report.id));
    await batch.commit();

    await _storageService.deleteByUrl(report.imageUrl);
  }

  Stream<List<CommentModel>> streamComments(String reportId) {
    return _reports
        .doc(reportId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CommentModel.fromDocument).toList());
  }

  Future<void> addComment({
    required String reportId,
    required String message,
  }) async {
    final user = _requireUser();
    final comment = _reports.doc(reportId).collection('comments').doc();

    await comment.set(
      CommentModel(
        id: comment.id,
        reportId: reportId,
        userId: user.uid,
        userEmail: user.email ?? '-',
        message: message.trim(),
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User belum login.');
    }
    return user;
  }
}
