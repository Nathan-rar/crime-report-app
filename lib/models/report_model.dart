import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  belum('Belum'),
  diproses('Diproses'),
  ditangani('Ditangani');

  const ReportStatus(this.label);

  final String label;

  static ReportStatus fromValue(String? value) {
    return ReportStatus.values.firstWhere(
      (status) => status.label == value || status.name == value,
      orElse: () => ReportStatus.belum,
    );
  }
}

class ReportModel {
  const ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.reporterId,
    required this.reporterEmail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String reporterId;
  final String reporterEmail;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  factory ReportModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return ReportModel.fromMap(document.id, document.data() ?? {});
  }

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      reporterEmail: map['reporterEmail'] as String? ?? '',
      status: ReportStatus.fromValue(map['status'] as String?),
      imageUrl: map['imageUrl'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'reporterId': reporterId,
      'reporterEmail': reporterEmail,
      'status': status.label,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ReportModel copyWith({
    String? title,
    String? description,
    String? category,
    ReportStatus? status,
    String? imageUrl,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      reporterId: reporterId,
      reporterEmail: reporterEmail,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
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
