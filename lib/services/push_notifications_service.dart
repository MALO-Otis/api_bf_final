import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';


// Top-level handler for background messages (required by firebase_messaging)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No heavy work here; ensure minimal work. App will handle on resume/open.
}

class PushNotificationsService {
  PushNotificationsService._();
  static final PushNotificationsService instance = PushNotificationsService._();
  static const String _webVapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> init() async {
    // Skip initialization on unsupported platforms (e.g., Windows/Linux)
    if (!(kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    if (_initialized) return;
    _initialized = true;

    // Permissions: iOS/macOS, and also Web
    if (kIsWeb) {
      await _messaging.requestPermission();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages (optionally show a snackbar or update UI)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // You can hook into a GetX controller or show a SnackBar if needed.
      // For now we keep it minimal.
    });

    // Token registration
    await _registerToken();

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(newToken);
    });
  }

  Future<void> _registerToken() async {
    final token = kIsWeb
        ? await _messaging.getToken(
            vapidKey: _webVapidKey.isEmpty ? null : _webVapidKey,
          )
        : await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }
  }

  // Public method to resync token metadata (uid/site) after login
  Future<void> resyncTokenMetadata() async {
    final token = kIsWeb
        ? await _messaging.getToken(
            vapidKey: _webVapidKey.isEmpty ? null : _webVapidKey,
          )
        : await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final session = Get.isRegistered<UserSession>() ? Get.find<UserSession>() : null;
      final uid = session?.uid ?? 'anonymous';
      final site = session?.site ?? '';

      final docId = _tokenDocId(token);
      await FirebaseFirestore.instance.collection('device_tokens').doc(docId).set({
        'token': token,
        'uid': uid,
        'site': site,
        'platform': kIsWeb
            ? 'web'
            : Platform.isAndroid
                ? 'android'
                : Platform.isIOS
                    ? 'ios'
                    : Platform.isWindows
                        ? 'windows'
                        : Platform.isMacOS
                            ? 'macos'
                            : Platform.isLinux
                                ? 'linux'
                                : 'unknown',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  String _tokenDocId(String token) {
    // Avoid slashes; token is URL-safe, but to be safe use its hashCode
    return token.hashCode.toString();
  }
}
