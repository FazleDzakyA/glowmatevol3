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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ✅ PASTE DATA DARI FIREBASE CONSOLE DI SINI
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCB8zOYFinTEjDuiPY38_NGKrvoxS3Zdm0',
    authDomain: 'glowmate-b9f50.firebaseapp.com',
    projectId: 'glowmate-b9f50',
    storageBucket: 'glowmate-b9f50.firebasestorage.app',
    messagingSenderId: '85041132278',
    appId: '1:85041132278:web:7dbfc4d5872a5b9424b2d7',
  );
}