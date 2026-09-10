import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deposit_model.dart';
import '../models/transaction_model.dart';
import '../models/notification_model.dart';
import 'transaction_repository.dart';
import 'notification_repository.dart';
import '../../services/local/database_helper.dart';
import '../../services/local/connectivity_service.dart';

class DepositRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _db = DatabaseHelper();
  final ConnectivityService _connectivity = ConnectivityService();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();
  
  static const String _collectionName = 'deposits';

  // ==================== GET ALL DEPOSITS (ADMIN) ====================
  Stream<List<DepositModel>> getAllDepositsStream() {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_collectionName)
          .snapshots()
          .asyncMap((snapshot) async {
            for (var doc in snapshot.docs) {
              await _saveToLocal(doc);
            }
            
            final deposits = snapshot.docs
                .map((doc) => DepositModel.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .toList();
            
            // Sort by date descending
            deposits.sort((a, b) => b.date.compareTo(a.date));
            
            return deposits;
          });
    } else {
      return Stream.periodic(Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_collectionName, 
          orderBy: 'date DESC');
        
        return localData
            .map((data) => DepositModel.fromMap({
                  ...data,
                  'date': Timestamp.fromDate(DateTime.parse(data['date'] as String)),
                  'createdAt': Timestamp.fromDate(DateTime.parse(data['createdAt'] as String)),
                }))
            .toList();
      });
    }
  }

  // ==================== GET USER DEPOSITS ====================
  Stream<List<DepositModel>> getUserDepositsStream(String userId) {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .asyncMap((snapshot) async {
            for (var doc in snapshot.docs) {
              await _saveToLocal(doc);
            }
            
            // Convert to list and sort client-side
            final deposits = snapshot.docs
                .map((doc) => DepositModel.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .toList();
            
            // Sort by date descending
            deposits.sort((a, b) => b.date.compareTo(a.date));
            
            return deposits;
          });
    } else {
      return Stream.periodic(Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_collectionName,
          where: 'userId = ?',
          whereArgs: [userId],
          orderBy: 'date DESC');
        
        return localData
            .map((data) => DepositModel.fromMap({
                  ...data,
                  'date': Timestamp.fromDate(DateTime.parse(data['date'] as String)),
                  'createdAt': Timestamp.fromDate(DateTime.parse(data['createdAt'] as String)),
                }))
            .toList();
      });
    }
  }

  // ==================== ADD DEPOSIT ====================
  Future<String> addDeposit(DepositModel deposit) async {
    try {
      final depositId = deposit.id.isEmpty 
        ? _firestore.collection(_collectionName).doc().id 
        : deposit.id;

      final depositWithId = DepositModel(
        id: depositId,
        userId: deposit.userId,
        userName: deposit.userName,
        amount: deposit.amount,
        method: deposit.method,
        reference: deposit.reference,
        status: deposit.status,
        addedBy: deposit.addedBy,
        date: deposit.date,
        createdAt: deposit.createdAt,
        description: deposit.description,
        receiptUrl: deposit.receiptUrl,
      );

      // Save to local DB
      await _db.insert(_collectionName, {
        'id': depositId,
        'userId': depositWithId.userId,
        'userName': depositWithId.userName,
        'amount': depositWithId.amount,
        'method': depositWithId.method,
        'reference': depositWithId.reference,
        'status': depositWithId.status,
        'addedBy': depositWithId.addedBy,
        'date': depositWithId.date.toIso8601String(),
        'createdAt': depositWithId.createdAt.toIso8601String(),
        'description': depositWithId.description,
        'receiptUrl': depositWithId.receiptUrl,
        'synced': _connectivity.isOnline ? 1 : 0,
        'pendingSync': _connectivity.isOnline ? 0 : 1,
      });

        if (_connectivity.isOnline) {
        await _firestore.collection(_collectionName).doc(depositId).set(depositWithId.toMap());
        
        // Update user balance if adding a completed deposit
        if (depositWithId.status.toLowerCase() == 'completed') {
          await _updateUserBalance(depositWithId.userId, depositWithId.amount);
        }
        
        // Notification: Deposit Added
        try {
          await _notificationRepo.createNotification(NotificationModel(
            id: '',
            userId: depositWithId.userId,
            type: 'deposit_added',
            title: 'টাকা জমা হয়েছে (Deposit Received)',
            message: 'আপনার অ্যাকাউন্টে ৳${depositWithId.amount.toStringAsFixed(0)} জমা হয়েছে।',
            createdAt: DateTime.now(),
            data: {'depositId': depositId, 'amount': depositWithId.amount},
            isRead: false,
          ));
        } catch (e) {
          print('⚠️ Error creating notification: $e');
        }
      } else {
        await _db.addToSyncQueue(
          entityType: 'deposit',
          entityId: depositId,
          operation: 'create',
          data: depositWithId.toMap(),
        );
      }

      // Create transaction record
      await _transactionRepo.createTransaction(TransactionModel(
        id: '',
        userId: depositWithId.userId,
        userName: depositWithId.userName,
        type: 'deposit',
        amount: depositWithId.amount,
        transactionDate: depositWithId.date,
        status: depositWithId.status.toLowerCase() == 'completed' ? 'completed' : 'pending',
        referenceId: depositId,
        description: depositWithId.description ?? 'Deposit via ${depositWithId.method}',
        metadata: {
          'method': depositWithId.method,
          'reference': depositWithId.reference,
        },
      ));

      return depositId;
    } catch (e) {
      print('❌ Error adding deposit: $e');
      rethrow;
    }
  }

  // ==================== UPDATE DEPOSIT ====================
  Future<void> updateDeposit(String depositId, DepositModel deposit) async {
    try {
      await _db.update(_collectionName, {
        'userId': deposit.userId,
        'userName': deposit.userName,
        'amount': deposit.amount,
        'method': deposit.method,
        'reference': deposit.reference,
        'status': deposit.status,
        'addedBy': deposit.addedBy,
        'date': deposit.date.toIso8601String(),
        'description': deposit.description,
        'receiptUrl': deposit.receiptUrl,
        'synced': _connectivity.isOnline ? 1 : 0,
        'pendingSync': _connectivity.isOnline ? 0 : 1,
      }, where: 'id = ?', whereArgs: [depositId]);

      if (_connectivity.isOnline) {
        await _firestore.collection(_collectionName).doc(depositId).update(deposit.toMap());
        
        // Sync transaction status
        try {
          await _transactionRepo.updateTransactionStatusByReference(
            depositId, 
            deposit.status.toLowerCase() == 'completed' ? 'completed' : 'pending'
          );
        } catch (e) {
          print('⚠️ Error syncing transaction status: $e');
        }
      } else {
        await _db.addToSyncQueue(
          entityType: 'deposit',
          entityId: depositId,
          operation: 'update',
          data: deposit.toMap(),
        );
      }
    } catch (e) {
      print('❌ Error updating deposit: $e');
      rethrow;
    }
  }

  // ==================== DELETE DEPOSIT ====================
  Future<void> deleteDeposit(String depositId) async {
    try {
      if (_connectivity.isOnline) {
        // ✅ FETCH BEFORE DELETE: To decrement user balance
        final docSnapshot = await _firestore.collection(_collectionName).doc(depositId).get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          if (data['status']?.toString().toLowerCase() == 'completed') {
             final userId = data['userId'] as String;
             final amount = (data['amount'] as num).toDouble();
             // Decrement balance
             await _updateUserBalance(userId, -amount);
          }
           await _firestore.collection(_collectionName).doc(depositId).delete();
        }
       
        await _db.delete(_collectionName, where: 'id = ?', whereArgs: [depositId]);
      } else {
        await _db.update(_collectionName, {
          'pendingSync': 1,
          'synced': 0,
        }, where: 'id = ?', whereArgs: [depositId]);
        
        await _db.addToSyncQueue(
          entityType: 'deposit',
          entityId: depositId,
          operation: 'delete',
          data: {},
        );
      }
    } catch (e) {
      print('❌ Error deleting deposit: $e');
      rethrow;
    }
  }

  // ==================== UPDATE STATUS ====================
  Future<void> updateDepositStatus(String depositId, String status) async {
    try {
      await _db.update(_collectionName, {
        'status': status,
        'synced': _connectivity.isOnline ? 1 : 0,
        'pendingSync': _connectivity.isOnline ? 0 : 1,
      }, where: 'id = ?', whereArgs: [depositId]);

      if (_connectivity.isOnline) {
        await _firestore.collection(_collectionName).doc(depositId).update({'status': status});
        
        // Notify user about status change
        final depositData = await _db.query(_collectionName, where: 'id = ?', whereArgs: [depositId]);
        if (depositData.isNotEmpty) {
           final userId = depositData.first['userId'] as String;
           try {
              await _notificationRepo.createNotification(NotificationModel(
              id: '',
              userId: userId,
              type: 'deposit_status_update',
              title: 'Deposit ${status[0].toUpperCase()}${status.substring(1)}',
              message: 'Your deposit status has been updated to $status.',
              createdAt: DateTime.now(),
              data: {'depositId': depositId, 'status': status},
              isRead: false,
            ));
           } catch (e) {
             print('⚠️ Error creating notification: $e');
           }
        }
        
        // Update user balance if deposit is approved/completed
        if (status.toLowerCase() == 'completed') {
          final depositData = await _db.query(_collectionName, 
            where: 'id = ?', whereArgs: [depositId]);
          if (depositData.isNotEmpty) {
            final userId = depositData.first['userId'] as String;
            final amount = (depositData.first['amount'] as num).toDouble();
            await _updateUserBalance(userId, amount);
          }
        }
      } else {
        await _db.addToSyncQueue(
          entityType: 'deposit',
          entityId: depositId,
          operation: 'update',
          data: {'status': status},
        );
      }
      
      // Update transaction status
      // If completed, it will be marked completed. If it was pending, now completed.
      // If rejected, it will be marked rejected (we might need 'failed' or 'rejected' status mapping)
      String transactionStatus = status.toLowerCase() == 'completed' ? 'completed' : 
                               (status.toLowerCase() == 'rejected' ? 'failed' : 'pending');
                               
      await _transactionRepo.updateTransactionStatusByReference(depositId, transactionStatus);
      
    } catch (e) {
      print('❌ Error updating deposit status: $e');
      rethrow;
    }
  }

  // ==================== GET TOTAL DEPOSITS ====================
  Future<double> getUserTotalDeposits(String userId) async {
    try {
      if (_connectivity.isOnline) {
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'completed')
            .get();

        double total = 0;
        for (var doc in snapshot.docs) {
          total += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        }
        return total;
      } else {
        final localData = await _db.query(_collectionName,
          where: 'userId = ? AND status = ?',
          whereArgs: [userId, 'completed']);
        
        double total = 0;
        for (var data in localData) {
          total += (data['amount'] as num?)?.toDouble() ?? 0;
        }
        return total;
      }
    } catch (e) {
      print('❌ Error getting user total deposits: $e');
      return 0;
    }
  }

  // ==================== GET ALL DEPOSITS TOTAL (FOUNDATION-WIDE) ====================
  Future<double> getAllDepositsTotal() async {
    try {
      if (_connectivity.isOnline) {
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('status', isEqualTo: 'completed')
            .get();

        double total = 0;
        for (var doc in snapshot.docs) {
          total += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        }
        return total;
      } else {
        final localData = await _db.query(_collectionName,
          where: 'status = ?',
          whereArgs: ['completed']);
        
        double total = 0;
        for (var data in localData) {
          total += (data['amount'] as num?)?.toDouble() ?? 0;
        }
        return total;
      }
    } catch (e) {
      print('❌ Error getting all deposits total: $e');
      return 0;
    }
  }


  // ==================== SEARCH DEPOSITS ====================
  Stream<List<DepositModel>> searchDepositsStream(String query) {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_collectionName)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => DepositModel.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .where((deposit) =>
                    deposit.userName.toLowerCase().contains(query.toLowerCase()) ||
                    deposit.reference.toLowerCase().contains(query.toLowerCase()) ||
                    deposit.id.contains(query))
                .toList();
          });
    } else {
      return Stream.periodic(Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_collectionName);
        
        return localData
            .map((data) => DepositModel.fromMap({
                  ...data,
                  'date': Timestamp.fromDate(DateTime.parse(data['date'] as String)),
                  'createdAt': Timestamp.fromDate(DateTime.parse(data['createdAt'] as String)),
                }))
            .where((deposit) =>
                deposit.userName.toLowerCase().contains(query.toLowerCase()) ||
                deposit.reference.toLowerCase().contains(query.toLowerCase()) ||
                deposit.id.contains(query))
            .toList();
      });
    }
  }

  // ==================== GET BY STATUS ====================
  Stream<List<DepositModel>> getDepositsByStatusStream(String status) {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: status)
          .snapshots()
          .asyncMap((snapshot) async {
            for (var doc in snapshot.docs) {
              await _saveToLocal(doc);
            }
            
            final deposits = snapshot.docs
                .map((doc) => DepositModel.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .toList();
            
            // Sort by date descending
            deposits.sort((a, b) => b.date.compareTo(a.date));
            
            return deposits;
          });
    } else {
      return Stream.periodic(Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_collectionName,
          where: 'status = ?',
          whereArgs: [status],
          orderBy: 'date DESC');
        
        return localData
            .map((data) => DepositModel.fromMap({
                  ...data,
                  'date': Timestamp.fromDate(DateTime.parse(data['date'] as String)),
                  'createdAt': Timestamp.fromDate(DateTime.parse(data['createdAt'] as String)),
                }))
            .toList();
      });
    }
  }

  // ✅ Helper: Save deposit to local database
  Future<void> _saveToLocal(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      await _db.insert(
        _collectionName,
        {
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? '',
          'amount': data['amount'] ?? 0,
          'method': data['method'] ?? '',
          'reference': data['reference'] ?? '',
          'status': data['status'] ?? 'pending',
          'addedBy': data['addedBy'] ?? 'admin',
          'date': data['date'] is String 
              ? data['date'] 
              : (data['date'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
          'createdAt': data['createdAt'] is String 
              ? data['createdAt'] 
              : (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
          'description': data['description'],
          'receiptUrl': data['receiptUrl'],
          'synced': 1,
          'pendingSync': 0,
        },
      );
    } catch (e) {
      print('❌ Error saving deposit to local DB: $e');
    }
  }

  // ==================== UPDATE USER BALANCE ====================
  Future<void> _updateUserBalance(String userId, double depositAmount) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('⚠️ User $userId not found');
        return;
      }
      
      final userData = userDoc.data()!;
      final currentBalance = (userData['balance'] ?? 0.0) as num;
      final currentDeposits = (userData['totalDeposits'] ?? 0.0) as num;
      
      // Update both balance and totalDeposits
      // When deleting, depositAmount will be negative
      await _firestore.collection('users').doc(userId).update({
        'balance': currentBalance.toDouble() + depositAmount,
        'totalDeposits': currentDeposits.toDouble() + depositAmount,
        'updatedAt': Timestamp.now(),
      });
      
      print('✅ Updated balance for user $userId: ${depositAmount > 0 ? '+' : ''}৳$depositAmount');
    } catch (e) {
      print('❌ Error updating user balance: $e');
    }
  }
}