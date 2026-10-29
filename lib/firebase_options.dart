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
        return macOS;
      case TargetPlatform.windows:
        return android; // Fallback for Windows desktop using Android credentials
      case TargetPlatform.linux:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCI6WiH-tZzO47ELPzEzT3ZPfVmeYGRDSM',
    appId: '1:748201032855:web:64498c8471044174dcbdd2',
    messagingSenderId: '748201032855',
    projectId: 'smart-attendance-sys-app',
    storageBucket: 'smart-attendance-sys-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCI6WiH-tZzO47ELPzEzT3ZPfVmeYGRDSM',
    appId: '1:748201032855:android:64498c8471044174dcbdd2',
    messagingSenderId: '748201032855',
    projectId: 'smart-attendance-sys-app',
    storageBucket: 'smart-attendance-sys-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCI6WiH-tZzO47ELPzEzT3ZPfVmeYGRDSM',
    appId: '1:748201032855:ios:64498c8471044174dcbdd2',
    messagingSenderId: '748201032855',
    projectId: 'smart-attendance-sys-app',
    storageBucket: 'smart-attendance-sys-app.firebasestorage.app',
    iosBundleId: 'com.example.smartattendance',
  );

  static const FirebaseOptions macOS = FirebaseOptions(
    apiKey: 'AIzaSyCI6WiH-tZzO47ELPzEzT3ZPfVmeYGRDSM',
    appId: '1:748201032855:ios:64498c8471044174dcbdd2',
    messagingSenderId: '748201032855',
    projectId: 'smart-attendance-sys-app',
    storageBucket: 'smart-attendance-sys-app.firebasestorage.app',
    iosBundleId: 'com.example.smartattendance',
  );
}
