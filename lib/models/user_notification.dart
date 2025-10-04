import 'package:cloud_firestore/cloud_firestore.dart';

class UserNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? createdBy;
  final String? createdByEmail;
  final String? createdByName;
  final Map<String, dynamic> metadata;
  final List<String> channels;

  const UserNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = 'normal',
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.createdBy,
    this.createdByEmail,
    this.createdByName,
    this.metadata = const <String, dynamic>{},
    this.channels = const <String>[],
  });

  factory UserNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserNotification(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      message: (data['message'] ?? '') as String,
    type: (data['type'] ?? 'system') as String,
    priority: (data['priority'] ?? 'normal') as String,
      isRead: (data['isRead'] ?? false) as bool,
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      readAt: _parseTimestamp(data['readAt']),
      createdBy: data['createdBy'] as String?,
      createdByEmail: data['createdByEmail'] as String?,
      createdByName: data['createdByName'] as String?,
      metadata:
          Map<String, dynamic>.from(data['metadata'] ?? <String, dynamic>{}),
      channels: List<String>.from(data['channels'] ?? const <String>[]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
    'type': type,
    'priority': priority,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'createdBy': createdBy,
      'createdByEmail': createdByEmail,
      'createdByName': createdByName,
      'metadata': metadata,
      'channels': channels,
    };
  }

  UserNotification copyWith({
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    String? priority,
  }) {
    return UserNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      createdBy: createdBy,
      createdByEmail: createdByEmail,
      createdByName: createdByName,
      metadata: metadata ?? this.metadata,
      channels: channels,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
