import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration options for the EasyBook project.
/// These options map to the existing Firebase project "porgetto-programmazione-mobile".
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not configured for this project.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvJ_ZNSw2136LvKyqyCVfWUhU3s_ctyOA',
    appId: '1:1088763618382:android:f23885cb0ec23fb30ecf1f',
    messagingSenderId: '1088763618382',
    projectId: 'porgetto-programmazione-mobile',
    storageBucket: 'porgetto-programmazione-mobile.firebasestorage.app',
  );

  // TODO: Add iOS configuration after registering the iOS app in Firebase Console.
  // Go to Firebase Console > Project Settings > Add app > iOS
  // Then fill in the values below.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '1088763618382',
    projectId: 'porgetto-programmazione-mobile',
    storageBucket: 'porgetto-programmazione-mobile.firebasestorage.app',
    iosBundleId: 'com.example.easyBookFlutter',
  );
}
