import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
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
  static const String _webVapidKey =
      String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> init() async {
    // Messaging is supported on Web, Android, iOS and macOS.
    // For other platforms (Windows, Linux, Fuchsia), gracefully skip.
    if (!kIsWeb &&
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return;
    }
    if (_initialized) return;
    _initialized = true;

    // Permissions: iOS/macOS, and also Web
    try {
      if (kIsWeb) {
        // On web this will trigger the browser permission prompt.
        await _messaging.requestPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (_) {
      // Ignore permission errors to avoid breaking app startup on web.
    }

    // Background handler
    // Not applicable to Web (background handled by service worker)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

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
    try {
      final token = kIsWeb
          ? await _messaging
              .getToken(vapidKey: _webVapidKey.isEmpty ? null : _webVapidKey)
              .timeout(const Duration(seconds: 10))
          : await _messaging.getToken().timeout(const Duration(seconds: 10));
      if (token != null) {
        await _saveToken(token);
      }
    } catch (_) {
      // On web, this can throw if service worker is missing or VAPID key isn't set.
      // We swallow to keep the UI from getting stuck on a white screen.
    }
  }

  // Public method to resync token metadata (uid/site) after login
  Future<void> resyncTokenMetadata() async {
    try {
      final token = kIsWeb
          ? await _messaging
              .getToken(vapidKey: _webVapidKey.isEmpty ? null : _webVapidKey)
              .timeout(const Duration(seconds: 10))
          : await _messaging.getToken().timeout(const Duration(seconds: 10));
      if (token != null) {
        await _saveToken(token);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final session =
          Get.isRegistered<UserSession>() ? Get.find<UserSession>() : null;
      final uid = session?.uid ?? 'anonymous';
      final site = session?.site ?? '';
      final role = session?.role ?? '';

      final docId = _tokenDocId(token);
      await FirebaseFirestore.instance
          .collection('device_tokens')
          .doc(docId)
          .set({
        'token': token,
        'uid': uid,
        'site': site,
        'role': role,
        'platform': _platformLabel(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  String _tokenDocId(String token) {
    // Avoid slashes; token is URL-safe, but to be safe use its hashCode
    return token.hashCode.toString();
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// Crée une notification Firestore visible par les administrateurs.
  /// Usage: après création d'une attribution.
  Future<void> createAdminAttributionNotification({
    required String attributionId,
    required String lotNumero,
    required double quantiteAttribuee,
    required String commercialNom,
    required String site,
  }) async {
    try {
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'type': 'attribution_created',
        'attributionId': attributionId,
        'lot': lotNumero,
        'quantite': quantiteAttribuee,
        'commercial': commercialNom,
        'site': site,
        'readBy': <String>[],
        'createdAt': now.toIso8601String(),
        'serverTime': FieldValue.serverTimestamp(),
        'message':
            'Nouvelle attribution de $quantiteAttribuee kg sur lot $lotNumero pour $commercialNom',
      });
    } catch (e) {
      debugPrint(
          '❌ [PushNotificationsService] Erreur creation notif admin: $e');
    }
  }
}
