import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../../services/local/database_helper.dart';
import '../../services/local/connectivity_service.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class MessageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _db = DatabaseHelper();
  final ConnectivityService _connectivity = ConnectivityService();
  final NotificationRepository _notificationRepo = NotificationRepository();
  
  static const String _messagesCollection = 'messages';
  static const String _broadcastMessagesCollection = 'broadcast_messages';

  // ==================== GET USER MESSAGES ====================
  Stream<List<MessageModel>> getUserMessagesStream(String userId) {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_messagesCollection)
          .where('recipientId', isEqualTo: userId)
          .snapshots()
          .asyncMap((snapshot) async {
            for (var doc in snapshot.docs) {
              await _saveToLocal(doc);
            }
            
            final messages = snapshot.docs
                .map((doc) => MessageModel.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .toList();
            
            // Sort by sentAt descending
            messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
            
            return messages;
          });
    } else {
      return Stream.periodic(Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_messagesCollection,
          where: 'recipientId = ?',
          whereArgs: [userId],
          orderBy: 'sentAt DESC');
        
        return localData
            .map((data) => MessageModel.fromMap({
                  ...data,
                  'sentAt': Timestamp.fromDate(DateTime.parse(data['sentAt'] as String)),
                  'readAt': data['readAt'] != null 
                    ? Timestamp.fromDate(DateTime.parse(data['readAt'] as String))
                    : null,
                  'isRead': data['isRead'] == 1,
                }))
            .toList();
      });
    }
  }

  // ==================== GET SENT MESSAGES ====================
  Stream<List<MessageModel>> getSentMessagesStream(String userId) {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_messagesCollection)
          .where('senderId', isEqualTo: userId)
          .snapshots()
          .asyncMap((snapshot) async {
            for (var doc in snapshot.docs) {
              await _saveToLocal(doc);
            }
            
            final messages = snapshot.docs
                .map((doc) => MessageModel.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .toList();
            
            // Sort by sentAt descending
            messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
            
            return messages;
          });
    } else {
      return Stream.periodic(Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_messagesCollection,
          where: 'senderId = ?',
          whereArgs: [userId],
          orderBy: 'sentAt DESC');
        
        return localData
            .map((data) => MessageModel.fromMap({
                  ...data,
                  'sentAt': Timestamp.fromDate(DateTime.parse(data['sentAt'] as String)),
                  'readAt': data['readAt'] != null 
                    ? Timestamp.fromDate(DateTime.parse(data['readAt'] as String))
                    : null,
                  'isRead': data['isRead'] == 1,
                }))
            .toList();
      });
    }
  }

  // ==================== SEND MESSAGE ====================
  Future<String> sendMessage(MessageModel message) async {
    try {
      final messageId = message.id.isEmpty 
        ? _firestore.collection(_messagesCollection).doc().id 
        : message.id;

      final messageWithId = MessageModel(
        id: messageId,
        senderId: message.senderId,
        recipientId: message.recipientId,
        title: message.title,
        message: message.message,
        notificationType: message.notificationType,
        status: message.status,
        sentAt: message.sentAt,
        readAt: message.readAt,
        isRead: message.isRead,
      );

      // Save to local DB
      await _db.insert(_messagesCollection, {
        'id': messageId,
        'senderId': messageWithId.senderId,
        'recipientId': messageWithId.recipientId,
        'title': messageWithId.title,
        'message': messageWithId.message,
        'notificationType': messageWithId.notificationType,
        'status': messageWithId.status,
        'sentAt': messageWithId.sentAt.toIso8601String(),
        'readAt': messageWithId.readAt?.toIso8601String(),
        'isRead': messageWithId.isRead ? 1 : 0,
        'synced': _connectivity.isOnline ? 1 : 0,
        'pendingSync': _connectivity.isOnline ? 0 : 1,
      });

      if (_connectivity.isOnline) {
        await _firestore.collection(_messagesCollection).doc(messageId).set(messageWithId.toMap());
        
        // Mirror to notifications collection so user sees it in Notifications tab
        if (messageWithId.senderId == 'admin') {
          await _notificationRepo.createNotification(NotificationModel(
            id: '',
            userId: messageWithId.recipientId,
            type: 'admin_message',
            title: messageWithId.title,
            message: messageWithId.message,
            createdAt: messageWithId.sentAt,
            isRead: false,
            data: {
              'messageId': messageId,
              'senderId': messageWithId.senderId,
            },
          ));
        }
      } else {
        await _db.addToSyncQueue(
          entityType: 'message',
          entityId: messageId,
          operation: 'update',
          data: messageWithId.toMap(),
        );
      }

      return messageId;
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  // ==================== SEND BROADCAST MESSAGE ====================
  Future<String> sendBroadcastMessage(
    String senderId,
    String title,
    String message,
    String notificationType,
    List<String> selectedUserIds,
  ) async {
    try {
      final recipientType = selectedUserIds.isEmpty ? 'all' : 'selected';
      
      // Get all users if broadcasting to all
      List<String> recipientIds = selectedUserIds;
      
      if (recipientType == 'all') {
        if (_connectivity.isOnline) {
          final usersSnapshot = await _firestore.collection('users').get();
          recipientIds = usersSnapshot.docs.map((doc) => doc.id).toList();
        } else {
          final localUsers = await _db.query('users');
          recipientIds = localUsers.map((u) => u['id'] as String).toList();
        }
      }

      // Create individual messages for each recipient
      for (String recipientId in recipientIds) {
        await sendMessage(MessageModel(
          id: '', // Will be generated
          senderId: senderId,
          recipientId: recipientId,
          title: title,
          message: message,
          notificationType: notificationType,
          status: 'sent',
          sentAt: DateTime.now(),
          isRead: false,
        ));
      }

      // Save broadcast metadata
      final broadcastId = _firestore.collection(_broadcastMessagesCollection).doc().id;
      final broadcastData = {
        'id': broadcastId,
        'senderId': senderId,
        'title': title,
        'message': message,
        'recipientType': recipientType,
        'selectedUserIds': selectedUserIds.join(','),
        'notificationType': notificationType,
        'sentAt': DateTime.now().toIso8601String(),
        'readCount': 0,
        'totalRecipients': recipientIds.length,
      };

      await _db.insert(_broadcastMessagesCollection, {
        ...broadcastData,
        'synced': _connectivity.isOnline ? 1 : 0,
        'pendingSync': _connectivity.isOnline ? 0 : 1,
      });

      if (_connectivity.isOnline) {
        await _firestore.collection(_broadcastMessagesCollection).doc(broadcastId).set({
          'senderId': senderId,
          'title': title,
          'message': message,
          'recipientType': recipientType,
          'selectedUserIds': selectedUserIds,
          'notificationType': notificationType,
          'sentAt': DateTime.now(),
          'readCount': 0,
          'totalRecipients': recipientIds.length,
        });
      } else {
        await _db.addToSyncQueue(
          entityType: 'message',
          entityId: broadcastId,
          operation: 'create',
          data: broadcastData,
        );
      }

      return broadcastId;
    } catch (e) {
      print('❌ Error sending broadcast message: $e');
      rethrow;
    }
  }

  // ==================== MARK AS READ ====================
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final now = DateTime.now();

      await _db.update(_messagesCollection, {
        'isRead': 1,
        'status': 'read',
        'readAt': now.toIso8601String(),
        'synced': _connectivity.isOnline ? 1 : 0,
        'pendingSync': _connectivity.isOnline ? 0 : 1,
      }, where: 'id = ?', whereArgs: [messageId]);

      if (_connectivity.isOnline) {
        await _firestore.collection(_messagesCollection).doc(messageId).update({
          'isRead': true,
          'status': 'read',
          'readAt': now,
        });
      } else {
        await _db.addToSyncQueue(
          entityType: 'message',
          entityId: messageId,
          operation: 'update',
          data: {
            'isRead': true,
            'status': 'read',
            'readAt': now,
          },
        );
      }
    } catch (e) {
      print('❌ Error marking message as read: $e');
      rethrow;
    }
  }

  // ==================== DELETE MESSAGE ====================
  Future<void> deleteMessage(String messageId) async {
    try {
      if (_connectivity.isOnline) {
        await _firestore.collection(_messagesCollection).doc(messageId).delete();
        await _db.delete(_messagesCollection, where: 'id = ?', whereArgs: [messageId]);
      } else {
        await _db.update(_messagesCollection, {
          'pendingSync': 1,
          'synced': 0,
        }, where: 'id = ?', whereArgs: [messageId]);
        
        await _db.addToSyncQueue(
          entityType: 'message',
          entityId: messageId,
          operation: 'delete',
          data: {},
        );
      }
    } catch (e) {
      print('❌ Error deleting message: $e');
      rethrow;
    }
  }

  // ==================== GET UNREAD COUNT ====================
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      if (_connectivity.isOnline) {
        final snapshot = await _firestore
            .collection(_messagesCollection)
            .where('recipientId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();
        return snapshot.docs.length;
      } else {
        final localData = await _db.query(_messagesCollection,
          where: 'recipientId = ? AND isRead = ?',
          whereArgs: [userId, 0]);
        return localData.length;
      }
    } catch (e) {
      print('❌ Error getting unread messages count: $e');
      return 0;
    }
  }

  // ==================== GET BROADCAST MESSAGES ====================
  Stream<List<Map<String, dynamic>>> getBroadcastMessagesStream() {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_broadcastMessagesCollection)
          .snapshots()
          .asyncMap((snapshot) async {
            for (var doc in snapshot.docs) {
              final data = doc.data();
              await _db.insert(_broadcastMessagesCollection, {
                'id': doc.id,
                'senderId': data['senderId'],
                'title': data['title'],
                'message': data['message'],
                'recipientType': data['recipientType'],
                'selectedUserIds': (data['selectedUserIds'] as List).join(','),
                'notificationType': data['notificationType'],
                'sentAt': (data['sentAt'] as Timestamp).toDate().toIso8601String(),
                'readCount': data['readCount'],
                'totalRecipients': data['totalRecipients'],
                'synced': 1,
                'pendingSync': 0,
              });
            }
            
            final messages = snapshot.docs
                .map((doc) => {
                      ...doc.data(),
                      'id': doc.id,
                    })
                .toList();
            
            // Sort by sentAt descending
            messages.sort((a, b) {
              final dateA = (a['sentAt'] as Timestamp).toDate();
              final dateB = (b['sentAt'] as Timestamp).toDate();
              return dateB.compareTo(dateA);
            });
            
            return messages;
          });
    } else {
      return Stream.periodic(Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_broadcastMessagesCollection,
          orderBy: 'sentAt DESC');
        
        return localData
            .map((data) => {
                  ...data,
                  'sentAt': Timestamp.fromDate(DateTime.parse(data['sentAt'] as String)),
                  'selectedUserIds': (data['selectedUserIds'] as String).split(','),
                })
            .toList();
      });
    }
  }

  // ==================== SEARCH MESSAGES ====================
  Stream<List<MessageModel>> searchMessagesStream(String userId, String query) {
    return getUserMessagesStream(userId).map((messages) {
      return messages
          .where((msg) =>
              msg.title.toLowerCase().contains(query.toLowerCase()) ||
              msg.message.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // ==================== HELPER: SAVE TO LOCAL ====================
  Future<void> _saveToLocal(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    
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

    await _db.insert(_messagesCollection, {
      'id': doc.id,
      'senderId': data['senderId'] ?? '',
      'recipientId': data['recipientId'] ?? '',
      'title': data['title'] ?? '',
      'message': data['message'] ?? '',
      'notificationType': data['notificationType'] ?? 'notification',
      'status': data['status'] ?? 'sent',
      'sentAt': parseDate(data['sentAt']).toIso8601String(),
      'readAt': data['readAt'] != null 
        ? parseDate(data['readAt']).toIso8601String() 
        : null,
      'isRead': data['isRead'] == true ? 1 : 0,
      'synced': 1,
      'pendingSync': 0,
    });
  }
}