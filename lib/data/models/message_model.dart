import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String recipientId;
  final String title;
  final String message;
  final String notificationType; // 'notification', 'sms', 'both'
  final String status; // 'sent', 'delivered', 'read'
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.status,
    required this.sentAt,
    this.readAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'notificationType': notificationType,
      'status': status,
      'sentAt': sentAt,
      'readAt': readAt,
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is DateTime) return date;
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      recipientId: map['recipientId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      notificationType: map['notificationType'] ?? 'notification',
      status: map['status'] ?? 'sent',
      sentAt: parseDate(map['sentAt']),
      readAt: map['readAt'] != null ? parseDate(map['readAt']) : null,
      isRead: map['isRead'] ?? false,
    );
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? title,
    String? message,
    String? notificationType,
    String? status,
    DateTime? sentAt,
    DateTime? readAt,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

// For broadcast messages to multiple users
class BroadcastMessageModel {
  final String id;
  final String senderId;
  final String title;
  final String message;
  final String recipientType; // 'all', 'selected'
  final List<String> selectedUserIds; // Empty if 'all'
  final String notificationType; // 'notification', 'sms', 'both'
  final DateTime sentAt;
  final int readCount;
  final int totalRecipients;

  BroadcastMessageModel({
    required this.id,
    required this.senderId,
    required this.title,
    required this.message,
    required this.recipientType,
    required this.selectedUserIds,
    required this.notificationType,
    required this.sentAt,
    required this.readCount,
    required this.totalRecipients,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'title': title,
      'message': message,
      'recipientType': recipientType,
      'selectedUserIds': selectedUserIds,
      'notificationType': notificationType,
      'sentAt': sentAt,
      'readCount': readCount,
      'totalRecipients': totalRecipients,
    };
  }

  factory BroadcastMessageModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is DateTime) return date;
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return BroadcastMessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      recipientType: map['recipientType'] ?? 'all',
      selectedUserIds: List<String>.from(map['selectedUserIds'] ?? []),
      notificationType: map['notificationType'] ?? 'notification',
      sentAt: parseDate(map['sentAt']),
      readCount: map['readCount'] ?? 0,
      totalRecipients: map['totalRecipients'] ?? 0,
    );
  }
}
