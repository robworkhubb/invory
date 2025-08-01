// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDjoMnOeETgX5-8U97I_HjgJFI8NxItAcg',
    appId: '1:524552556806:web:4bae50045374103e684e87',
    messagingSenderId: '524552556806',
    projectId: 'invory-b9a72',
    authDomain: 'invory-b9a72.firebaseapp.com',
    storageBucket: 'invory-b9a72.firebasestorage.app',
    measurementId: 'G-MTDPNYBZG4',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBdEy-a_JWaTUeSvD5rQrOIY_2-Xbej2UY',
    appId: '1:524552556806:android:3e64c43e85e1c82f684e87',
    messagingSenderId: '524552556806',
    projectId: 'invory-b9a72',
    storageBucket: 'invory-b9a72.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyClyc3suFD79XTTOs8B-A59dPaVZb4evq0',
    appId: '1:524552556806:ios:322fb3c477f5275b684e87',
    messagingSenderId: '524552556806',
    projectId: 'invory-b9a72',
    storageBucket: 'invory-b9a72.firebasestorage.app',
    iosBundleId: 'com.invory.app',
  );
}
