import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/comment_model.dart';
import '../models/report_model.dart';

class LocalReportStore {
  LocalReportStore._();

  static final LocalReportStore instance = LocalReportStore._();
  static const _reportsKey = 'local_reports';
  static const _commentsKey = 'local_report_comments';

  final _reportsController = StreamController<List<ReportModel>>.broadcast();
  final _commentsControllers = <String, StreamController<List<CommentModel>>>{};

  List<ReportModel>? _reports;
  Map<String, List<CommentModel>>? _comments;

  Stream<List<ReportModel>> streamReports() {
    _load().then((_) => _emitReports());
    return _reportsController.stream;
  }

  Stream<ReportModel> streamReport(String reportId) {
    return streamReports().map((reports) {
      return reports.firstWhere(
        (report) => report.id == reportId,
        orElse: () => throw Exception('Laporan lokal tidak ditemukan.'),
      );
    });
  }

  Future<ReportModel?> getReport(String reportId) async {
    await _load();
    return _reports!.where((report) => report.id == reportId).firstOrNull;
  }

  Future<String> createReport({
    required String title,
    required String description,
    required String category,
    required String reporterId,
    required String reporterEmail,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    await _load();
    final now = DateTime.now();
    final report = ReportModel(
      id: 'local-${now.microsecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      reporterId: reporterId,
      reporterEmail: reporterEmail,
      status: ReportStatus.belum,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      createdAt: now,
      updatedAt: now,
    );

    _reports = [report, ..._reports!];
    await _saveReports();
    _emitReports();
    return report.id;
  }

  Future<void> updateReport({
    required String reportId,
    required String title,
    required String description,
    required String category,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    await _load();
    _reports = _reports!.map((report) {
      if (report.id != reportId) {
        return report;
      }

      return ReportModel(
        id: report.id,
        title: title.trim(),
        description: description.trim(),
        category: category.trim(),
        reporterId: report.reporterId,
        reporterEmail: report.reporterEmail,
        status: report.status,
        imageUrl: imageUrl ?? report.imageUrl,
        latitude: latitude ?? report.latitude,
        longitude: longitude ?? report.longitude,
        createdAt: report.createdAt,
        updatedAt: DateTime.now(),
      );
    }).toList();

    await _saveReports();
    _emitReports();
  }

  Future<void> updateStatus({
    required ReportModel report,
    required ReportStatus status,
  }) async {
    await _load();
    _reports = _reports!.map((item) {
      if (item.id != report.id) {
        return item;
      }
      return item.copyWith(status: status, updatedAt: DateTime.now());
    }).toList();

    await _saveReports();
    _emitReports();
  }

  Future<void> deleteReport(ReportModel report) async {
    await _load();
    _reports = _reports!.where((item) => item.id != report.id).toList();
    _comments!.remove(report.id);

    await _saveReports();
    await _saveComments();
    _emitReports();
    _emitComments(report.id);
  }

  Stream<List<CommentModel>> streamComments(String reportId) {
    final controller = _commentsControllers.putIfAbsent(
      reportId,
      () => StreamController<List<CommentModel>>.broadcast(),
    );
    _load().then((_) => _emitComments(reportId));
    return controller.stream;
  }

  Future<void> addComment({
    required String reportId,
    required String userId,
    required String userEmail,
    required String message,
  }) async {
    await _load();
    final now = DateTime.now();
    final comment = CommentModel(
      id: 'local-comment-${now.microsecondsSinceEpoch}',
      reportId: reportId,
      userId: userId,
      userEmail: userEmail,
      message: message.trim(),
      createdAt: now,
    );

    _comments![reportId] = [..._comments![reportId] ?? const [], comment];
    await _saveComments();
    _emitComments(reportId);
  }

  Future<void> _load() async {
    if (_reports != null && _comments != null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final reportRows = prefs.getStringList(_reportsKey) ?? const [];
    final commentRows = prefs.getStringList(_commentsKey) ?? const [];

    _reports =
        reportRows
            .map(
              (row) => _reportFromJson(jsonDecode(row) as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _comments = {};
    for (final row in commentRows) {
      final comment = _commentFromJson(jsonDecode(row) as Map<String, dynamic>);
      _comments!.putIfAbsent(comment.reportId, () => []).add(comment);
    }

    for (final comments in _comments!.values) {
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _reportsKey,
      _reports!.map((report) => jsonEncode(_reportToJson(report))).toList(),
    );
  }

  Future<void> _saveComments() async {
    final prefs = await SharedPreferences.getInstance();
    final rows = _comments!.values.expand((comments) => comments).map((
      comment,
    ) {
      return jsonEncode(_commentToJson(comment));
    }).toList();
    await prefs.setStringList(_commentsKey, rows);
  }

  void _emitReports() {
    if (!_reportsController.isClosed) {
      _reportsController.add(List.unmodifiable(_reports!));
    }
  }

  void _emitComments(String reportId) {
    final controller = _commentsControllers[reportId];
    if (controller != null && !controller.isClosed) {
      controller.add(List.unmodifiable(_comments![reportId] ?? const []));
    }
  }

  Map<String, dynamic> _reportToJson(ReportModel report) {
    return {
      'id': report.id,
      'title': report.title,
      'description': report.description,
      'category': report.category,
      'reporterId': report.reporterId,
      'reporterEmail': report.reporterEmail,
      'status': report.status.label,
      'imageUrl': report.imageUrl,
      'latitude': report.latitude,
      'longitude': report.longitude,
      'createdAt': report.createdAt.toIso8601String(),
      'updatedAt': report.updatedAt.toIso8601String(),
    };
  }

  ReportModel _reportFromJson(Map<String, dynamic> data) {
    return ReportModel(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      reporterId: data['reporterId'] as String? ?? '',
      reporterEmail: data['reporterEmail'] as String? ?? '',
      status: ReportStatus.fromValue(data['status'] as String?),
      imageUrl: data['imageUrl'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> _commentToJson(CommentModel comment) {
    return {
      'id': comment.id,
      'reportId': comment.reportId,
      'userId': comment.userId,
      'userEmail': comment.userEmail,
      'message': comment.message,
      'createdAt': comment.createdAt.toIso8601String(),
    };
  }

  CommentModel _commentFromJson(Map<String, dynamic> data) {
    return CommentModel(
      id: data['id'] as String? ?? '',
      reportId: data['reportId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
