import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/comment_model.dart';
import '../models/report_model.dart';
import 'auth_service.dart';
import 'local_report_store.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final LocalReportStore _localReports = LocalReportStore.instance;
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  Stream<List<ReportModel>> streamReports() {
    if (_authService.isLocalAdminSignedIn) {
      return _localReports.streamReports();
    }

    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ReportModel.fromDocument).toList(),
        );
  }

  Stream<ReportModel> streamReport(String reportId) {
    if (_authService.isLocalAdminSignedIn) {
      return _localReports.streamReport(reportId);
    }

    return _reports.doc(reportId).snapshots().map((document) {
      return ReportModel.fromDocument(document);
    });
  }

  Future<ReportModel?> getReport(String reportId) async {
    if (_authService.isLocalAdminSignedIn) {
      return _localReports.getReport(reportId);
    }

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
    double? latitude,
    double? longitude,
  }) async {
    final user = _auth.currentUser;
    final isLocalAdmin = _authService.isLocalAdminSignedIn;
    if (user == null && !isLocalAdmin) {
      throw Exception('User belum login.');
    }

    final doc = _reports.doc();
    String? imageUrl;

    if (image != null) {
      imageUrl = await _storageService.uploadReportPhoto(
        file: image,
        reportId: doc.id,
      );
    }

    if (isLocalAdmin) {
      return _localReports.createReport(
        title: title,
        description: description,
        category: category,
        reporterId: 'local-admin',
        reporterEmail: AuthService.localAdminEmail,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
      );
    }

    final now = DateTime.now();
    final report = ReportModel(
      id: doc.id,
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      reporterId: user?.uid ?? 'local-admin',
      reporterEmail: user?.email ?? AuthService.localAdminEmail,
      status: ReportStatus.belum,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      createdAt: now,
      updatedAt: now,
    );

    await doc.set(report.toMap());
    try {
      await _notificationService.subscribeToReport(doc.id);
    } catch (_) {
      // Notifikasi bersifat tambahan; laporan tetap berhasil dibuat.
    }
    return doc.id;
  }

  Future<void> updateReport({
    required String reportId,
    required String title,
    required String description,
    required String category,
    XFile? image,
    double? latitude,
    double? longitude,
  }) async {
    await _requireAdmin();

    String? imageUrl;
    if (image != null) {
      imageUrl = await _storageService.uploadReportPhoto(
        file: image,
        reportId: reportId,
      );
    }

    if (_authService.isLocalAdminSignedIn) {
      await _localReports.updateReport(
        reportId: reportId,
        title: title,
        description: description,
        category: category,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
      );
      return;
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
    if (latitude != null && longitude != null) {
      data['latitude'] = latitude;
      data['longitude'] = longitude;
    }

    await _reports.doc(reportId).update(data);
  }

  Future<void> updateStatus({
    required ReportModel report,
    required ReportStatus status,
  }) async {
    await _requireAdmin();
    final user = _auth.currentUser;

    if (_authService.isLocalAdminSignedIn) {
      await _localReports.updateStatus(report: report, status: status);
      return;
    }

    await _reports.doc(report.id).update({
      'status': status.label,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.recordStatusUpdateNotification(
      reportId: report.id,
      reportTitle: report.title,
      status: status.label,
      changedBy: user?.email ?? AuthService.localAdminEmail,
    );
  }

  Future<void> deleteReport(ReportModel report) async {
    await _requireAdmin();

    if (_authService.isLocalAdminSignedIn) {
      await _localReports.deleteReport(report);
      await _storageService.deleteByUrl(report.imageUrl);
      return;
    }

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
    if (_authService.isLocalAdminSignedIn) {
      return _localReports.streamComments(reportId);
    }

    return _reports
        .doc(reportId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(CommentModel.fromDocument).toList(),
        );
  }

  Future<void> addComment({
    required String reportId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    final isLocalAdmin = _authService.isLocalAdminSignedIn;
    if (user == null && !isLocalAdmin) {
      throw Exception('User belum login.');
    }

    if (isLocalAdmin) {
      await _localReports.addComment(
        reportId: reportId,
        userId: 'local-admin',
        userEmail: AuthService.localAdminEmail,
        message: message,
      );
      return;
    }

    final comment = _reports.doc(reportId).collection('comments').doc();

    await comment.set(
      CommentModel(
        id: comment.id,
        reportId: reportId,
        userId: user?.uid ?? 'local-admin',
        userEmail: user?.email ?? AuthService.localAdminEmail,
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

  Future<void> _requireAdmin() async {
    if (_authService.isLocalAdminSignedIn) {
      return;
    }

    _requireUser();
    final isAdmin = await _authService.isCurrentUserAdmin();
    if (!isAdmin) {
      throw Exception('Aksi ini hanya tersedia untuk admin.');
    }
  }
}
