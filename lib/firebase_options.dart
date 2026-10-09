// File generated based on google-services.json
// This file contains Firebase configuration for your app

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCONBD4SRTrl9m9iOj5HEYzl8k3bu5X54U',
    appId: '1:583881262834:android:0d26dbfbccadbe3916f26b',
    messagingSenderId: '583881262834',
    projectId: 'quran-tj-notifications',
    storageBucket: 'quran-tj-notifications.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDLYFCXOl2H_W4t-dR0AxJpbqTDcBK9_kg',
    appId: '1:583881262834:ios:8554a97e56802a4016f26b',
    messagingSenderId: '583881262834',
    projectId: 'quran-tj-notifications',
    databaseURL: 'https://quran-tj-notifications-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'quran-tj-notifications.firebasestorage.app',
    iosBundleId: 'com.quran.tj.quranapp',
  );
}
