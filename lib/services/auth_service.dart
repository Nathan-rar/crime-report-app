import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    XFile? photo,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;

    if (user == null) {
      throw Exception('Registrasi gagal: user tidak ditemukan.');
    }

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _storageService.uploadUserPhoto(
        file: photo,
        userId: user.uid,
      );
    }

    await user.updateDisplayName(name.trim());
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'name': name.trim(),
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'fcmTokens': <String>[],
    }, SetOptions(merge: true));

    return credential;
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
