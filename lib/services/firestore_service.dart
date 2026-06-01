import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get users =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get reports =>
      firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> comments(String reportId) {
    return reports.doc(reportId).collection('comments');
  }
}
