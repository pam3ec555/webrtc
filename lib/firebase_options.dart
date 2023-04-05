// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return macos;
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
    apiKey: 'AIzaSyDN82v9cqLZvDFDs8CuD7ewue3eV_KUico',
    appId: '1:462833888486:web:8593f4270db13f2d6b9f27',
    messagingSenderId: '462833888486',
    projectId: 'web-rtc-1d945',
    authDomain: 'web-rtc-1d945.firebaseapp.com',
    storageBucket: 'web-rtc-1d945.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAPQQs9FxCAJf43YST_hyROQSNkCZC0mZ4',
    appId: '1:462833888486:android:a02d533caa4959f56b9f27',
    messagingSenderId: '462833888486',
    projectId: 'web-rtc-1d945',
    storageBucket: 'web-rtc-1d945.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAqvc-nRsc1A5Xq9LedpRHE7khAD7TCxhc',
    appId: '1:462833888486:ios:7b94329bcc67a13a6b9f27',
    messagingSenderId: '462833888486',
    projectId: 'web-rtc-1d945',
    storageBucket: 'web-rtc-1d945.appspot.com',
    iosClientId:
        '462833888486-gdg9ip0kc3s670hfaj71posargbovctm.apps.googleusercontent.com',
    iosBundleId: 'com.ramil.webrtc',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAqvc-nRsc1A5Xq9LedpRHE7khAD7TCxhc',
    appId: '1:462833888486:ios:1ffa352c9293fb606b9f27',
    messagingSenderId: '462833888486',
    projectId: 'web-rtc-1d945',
    storageBucket: 'web-rtc-1d945.appspot.com',
    iosClientId:
        '462833888486-45vobmgvt3demaqo9a5jtseb1c0r8ge3.apps.googleusercontent.com',
    iosBundleId: 'com.example.webrtc',
  );
}