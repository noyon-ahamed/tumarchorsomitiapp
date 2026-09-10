import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Create a notification
  Future<void> createNotification(NotificationModel notification) async {
    try {
      // Save notification to Firestore
      await _firestore.collection(_collection).add(notification.toMap());
      
      // Send FCM push notification
      await _sendFCMNotification(notification);
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  // Send FCM push notification to user's device
  Future<void> _sendFCMNotification(NotificationModel notification) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(notification.userId).get();
      if (!userDoc.exists) return;
      
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ No FCM token found for user ${notification.userId}');
        return;
      }

      // Note: For production, you should use Firebase Admin SDK or Cloud Functions
      // This is a simplified version that requires FCM server key
      // For now, we'll just log that we would send the notification
      print('📱 Would send FCM notification to token: ${fcmToken.substring(0, 20)}...');
      print('   Title: ${notification.title}');
      print('   Body: ${notification.message}');
      
      // TODO: Implement actual FCM sending using:
      // 1. Firebase Admin SDK (recommended for production)
      // 2. Cloud Functions (recommended for security)
      // 3. HTTP API with server key (requires backend)
      
    } catch (e) {
      print('⚠️ Error sending FCM notification: $e');
      // Don't throw - notification is already saved to Firestore
    }
  }

  // Get user notifications stream
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get unread count
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  // Mark all as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadDocs = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error marking all as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final userDocs = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in userDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error deleting all notifications: $e');
    }
  }

  // Create notification for loan payment reminder
  Future<void> sendLoanReminder(
    String userId,
    String userName,
    double amount,
    DateTime dueDate,
    String loanId,
  ) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'loan_reminder',
      title: 'Loan Payment Reminder',
      message: 'Your loan payment of ৳${amount.toStringAsFixed(0)} is due soon',
      createdAt: DateTime.now(),
      data: {
        'loanId': loanId,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
      },
    );

    await createNotification(notification);
  }

  // Create notification for overdue payment
  Future<void> sendOverdueNotification(
    String userId,
    String userName,
    double amount,
    String loanId,
  ) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'payment_overdue',
      title: 'Payment Overdue',
      message: 'Your loan payment of ৳${amount.toStringAsFixed(0)} is overdue',
      createdAt: DateTime.now(),
      data: {
        'loanId': loanId,
        'amount': amount,
      },
    );

    await createNotification(notification);
  }

  // Create notification for deposit approval
  Future<void> sendDepositApproved(
    String userId,
    double amount,
    String depositId,
  ) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'deposit_approved',
      title: 'Deposit Approved',
      message: 'Your deposit of ৳${amount.toStringAsFixed(0)} has been approved',
      createdAt: DateTime.now(),
      data: {
        'depositId': depositId,
        'amount': amount,
      },
    );

    await createNotification(notification);
  }

  // Create notification for deposit rejection
  Future<void> sendDepositRejected(
    String userId,
    double amount,
    String depositId,
    String? reason,
  ) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'deposit_rejected',
      title: 'Deposit Rejected',
      message: reason ?? 'Your deposit of ৳${amount.toStringAsFixed(0)} was not approved',
      createdAt: DateTime.now(),
      data: {
        'depositId': depositId,
        'amount': amount,
        'reason': reason,
      },
    );

    await createNotification(notification);
  }
}
