import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apisavana_gestion/services/email_service.dart';
import 'package:apisavana_gestion/models/user_notification.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';

class NotificationService extends GetxService {
  NotificationService() {
    _emailService = Get.isRegistered<EmailService>()
        ? Get.find<EmailService>()
        : Get.put(EmailService());
  }

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('notifications');

  late final EmailService _emailService;

  UserSession? get _session =>
      Get.isRegistered<UserSession>() ? Get.find<UserSession>() : null;

  Stream<List<UserNotification>> streamForUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserNotification.fromDoc(doc)).toList());
  }

  Future<int> countUnread(String userId) async {
    final result = await _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    return result.size;
  }

  Future<void> markAsRead(String notificationId) async {
    await _collection.doc(notificationId).update({
      'isRead': true,
      'status': 'read',
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsUnread(String notificationId) async {
    await _collection.doc(notificationId).update({
      'isRead': false,
      'status': 'unread',
      'readAt': null,
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final query = await _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (query.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _collection.doc(notificationId).delete();
  }

  Stream<int> unreadCountStream(String userId) {
    return streamForUser(userId)
        .map((list) => list.where((n) => !n.isRead).length)
        .distinct();
  }

  Future<String?> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? metadata,
    bool sendEmail = false,
    String? userEmail,
    String? userName,
    String priority = 'normal',
  }) async {
    final createdBy = _session?.uid;
    final createdByEmail = _session?.email;
    final createdByName = _session?.nom;

    final docRef = _collection.doc();
    final data = {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'metadata': metadata ?? <String, dynamic>{},
      'isRead': false,
      'status': 'unread',
      'channels':
          sendEmail ? <String>['in-app', 'email'] : const <String>['in-app'],
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'createdByEmail': createdByEmail,
      'createdByName': createdByName,
    };

    await docRef.set(data);

    if (sendEmail && userEmail != null && userEmail.isNotEmpty) {
      try {
        await _emailService.sendUserNotificationEmail(
          userEmail: userEmail,
          userName: userName ?? userEmail,
          subject: title,
          message: message,
        );
      } catch (e) {
        if (kDebugMode) {
          print('❌ Email notification error: $e');
        }
      }
    }

    return docRef.id;
  }
}
