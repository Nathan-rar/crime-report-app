import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  static const localAdminEmail = 'admin@local.app';
  static const localAdminPassword = 'admin123';
  static bool _isLocalAdminSignedIn = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  User? get currentUser => _auth.currentUser;

  bool get isLocalAdminSignedIn => _isLocalAdminSignedIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<UserModel?> streamCurrentUserProfile() {
    return authStateChanges.asyncExpand((user) {
      if (user == null) {
        return Stream<UserModel?>.value(null);
      }

      return _firestore.collection('users').doc(user.uid).snapshots().map((
        document,
      ) {
        if (!document.exists) {
          return UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
          );
        }

        return UserModel.fromDocument(document);
      });
    });
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final document = await _firestore.collection('users').doc(user.uid).get();
    if (!document.exists) {
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
    }

    return UserModel.fromDocument(document);
  }

  Future<bool> isCurrentUserAdmin() async {
    if (_isLocalAdminSignedIn) {
      return true;
    }

    final profile = await getCurrentUserProfile();
    return profile?.isAdmin ?? false;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInReporter({
    required String email,
    required String password,
  }) async {
    final credential = await signIn(email: email, password: password);
    final profile = await getCurrentUserProfile();

    if (profile?.isAdmin ?? false) {
      await signOut();
      throw Exception('Akun admin harus masuk melalui halaman admin.');
    }

    return credential;
  }

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    if (email.trim() == localAdminEmail && password == localAdminPassword) {
      _isLocalAdminSignedIn = true;
      return;
    }

    await signIn(email: email, password: password);
    final profile = await getCurrentUserProfile();

    if (!(profile?.isAdmin ?? false)) {
      await signOut();
      throw Exception('Akun ini bukan admin.');
    }
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
      'role': UserRole.user.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'fcmTokens': <String>[],
    }, SetOptions(merge: true));

    return credential;
  }

  Future<void> signOut() async {
    _isLocalAdminSignedIn = false;
    await _auth.signOut();
  }
}
