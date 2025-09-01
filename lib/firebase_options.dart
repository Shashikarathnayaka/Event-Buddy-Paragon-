import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Define the Firebase configuration for each platform
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS and macOS configuration
      log("IOS PLATFORM");
      return ios;
    } else {
      // Android configuration
      log("ANDROID PLATFORM");
      return android;
    }
  }

  // Firebase configuration for iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '',
    projectId: '',
    messagingSenderId: '',
    appId: '',
    iosBundleId: '',
  );

  // Firebase configuration for Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAyCQjsq-A6C3xksGGKah_BuSIPBJaGuOk',
    projectId: 'event-buddy-92dfd',
    messagingSenderId: '127304838376',
    appId: '1:127304838376:android:87805dc6778fcd8e37ed5d',
  );
}


// Explanation of Fields
// apiKey: The API key for your Firebase project.
// authDomain: The authentication domain for your Firebase project.
// projectId: The project ID for your Firebase project.
// storageBucket: The storage bucket for your Firebase project.
// messagingSenderId: The sender ID for Firebase Cloud Messaging.
// appId: The application ID for your Firebase project.
// measurementId: The measurement ID for Google Analytics (used only for web).
// iosBundleId: The bundle ID for the iOS app.