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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions tidak mendukung platform ini.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'API_KEY_WEB',
    authDomain: 'PROJECT_ID.firebaseapp.com',
    projectId: 'PROJECT_ID',
    storageBucket: 'PROJECT_ID.appspot.com',
    messagingSenderId: 'SENDER_ID',
    appId: 'APP_ID',
    measurementId: 'MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'API_KEY_ANDROID',
    authDomain: 'PROJECT_ID.firebaseapp.com',
    projectId: 'PROJECT_ID',
    storageBucket: 'PROJECT_ID.appspot.com',
    messagingSenderId: 'SENDER_ID',
    appId: 'APP_ID',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'API_KEY_IOS',
    authDomain: 'PROJECT_ID.firebaseapp.com',
    projectId: 'PROJECT_ID',
    storageBucket: 'PROJECT_ID.appspot.com',
    messagingSenderId: 'SENDER_ID',
    appId: 'APP_ID',
    iosClientId: 'CLIENT_ID',
    iosBundleId: 'BUNDLE_ID',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'API_KEY_MACOS',
    authDomain: 'PROJECT_ID.firebaseapp.com',
    projectId: 'PROJECT_ID',
    storageBucket: 'PROJECT_ID.appspot.com',
    messagingSenderId: 'SENDER_ID',
    appId: 'APP_ID',
    iosClientId: 'CLIENT_ID',
    iosBundleId: 'BUNDLE_ID',
  );
}
