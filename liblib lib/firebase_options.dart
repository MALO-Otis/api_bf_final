import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
// GENERATED-LIKE FILE (manually authored): Firebase configuration for all platforms.
// This mirrors the structure created by `flutterfire configure` so we can
// consistently initialize Firebase across platforms, including Windows.

/// Default [FirebaseOptions] for the current platform.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Using web-style config as a fallback when dedicated config isn't provided.
        return web;
      case TargetPlatform.iOS:
        return web;
      case TargetPlatform.macOS:
        return web;
      case TargetPlatform.windows:
        // Windows desktop uses Firebase C++ SDK; web credentials are acceptable
        // for desktop in FlutterFire when not using Google Services files.
        return windows;
      case TargetPlatform.linux:
        return web;
      case TargetPlatform.fuchsia:
        return web;
    }
  }

  // Values taken from the user's existing configuration in main.dart
  // Project: apisavana-bf-226
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCQVVqssk1aMPh5cgJi2a3XAqFJ2_cOXPc',
    authDomain: 'apisavana-bf-226.firebaseapp.com',
    projectId: 'apisavana-bf-226',
    storageBucket: 'apisavana-bf-226.firebasestorage.app',
    messagingSenderId: '955408721623',
    appId: '1:955408721623:web:e78c39e6801db32545b292',
    measurementId: 'G-NH4D0Q9NTS',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCQVVqssk1aMPh5cgJi2a3XAqFJ2_cOXPc',
    authDomain: 'apisavana-bf-226.firebaseapp.com',
    projectId: 'apisavana-bf-226',
    storageBucket: 'apisavana-bf-226.firebasestorage.app',
    messagingSenderId: '955408721623',
    // Desktop commonly reuses the Web app ID unless you configured a
    // specific Windows app in Firebase. This matches the previous config.
    appId: '1:955408721623:web:e78c39e6801db32545b292',
    measurementId: 'G-NH4D0Q9NTS',
  );
}
