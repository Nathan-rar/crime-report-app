import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase options for iOS belum dikonfigurasi. Jalankan flutterfire configure untuk iOS atau tambahkan GoogleService-Info.plist.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Firebase options for macOS belum dikonfigurasi.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Firebase options for Windows belum dikonfigurasi.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase options for Linux belum dikonfigurasi.',
        );
      default:
        throw UnsupportedError(
          'Platform ini belum didukung oleh Firebase config.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCcZBzfo5YNd7fbZRA7xZnPIPygvjkfqkA',
    authDomain: 'prj-nathan.firebaseapp.com',
    projectId: 'prj-nathan',
    storageBucket: 'prj-nathan.firebasestorage.app',
    messagingSenderId: '898567194869',
    appId: '1:898567194869:web:932ddfd0d24fbd7ecbddbc',
    measurementId: 'G-S4YL38QEK7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNOc6xfBxP2ScHT2-GxaBD1xbRmGi5yzQ',
    appId: '1:898567194869:android:1d717e3a419125b1cbddbc',
    messagingSenderId: '898567194869',
    projectId: 'prj-nathan',
    storageBucket: 'prj-nathan.firebasestorage.app',
  );
}
