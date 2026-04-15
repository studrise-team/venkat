// File generated based on google-services.json and Firebase project config.
// DO NOT commit secret API keys to public repositories.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
          'DefaultFirebaseOptions have not been configured for iOS – '
          'add GoogleService-Info.plist and regenerate this file.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─── Web ──────────────────────────────────────────────────────────────────
  // These values come from the Firebase Console → Project Settings → Web app.
  // Replace them with the exact values from your own web app config if they
  // differ (Project ID and storageBucket are already matched to your project).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCQz8omQ-fAbczuIVnpZmSB0iD8GHMSQ2w',
    appId: '1:716584583860:web:astarai',          // update with web appId from console
    messagingSenderId: '716584583860',
    projectId: 'astarai',
    authDomain: 'astarai.firebaseapp.com',
    storageBucket: 'astarai.firebasestorage.app',
  );

  // ─── Android ──────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCQz8omQ-fAbczuIVnpZmSB0iD8GHMSQ2w',
    appId: '1:716584583860:android:b58b4901b17f2b325e0de1',
    messagingSenderId: '716584583860',
    projectId: 'astarai',
    storageBucket: 'astarai.firebasestorage.app',
  );
}
