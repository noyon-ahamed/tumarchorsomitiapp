import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../../services/local/database_helper.dart';
import '../../services/local/connectivity_service.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _db = DatabaseHelper();
  final ConnectivityService _connectivity = ConnectivityService();
  
  static const String _collectionName = 'transactions';

  // ==================== CREATE TRANSACTION ====================
  Future<String> createTransaction(TransactionModel transaction) async {
    try {
      final transactionId = transaction.id.isEmpty 
        ? _firestore.collection(_collectionName).doc().id 
        : transaction.id;

      final transactionWithId = transaction.copyWith(id: transactionId);

      // Always save to local DB first
      await _db.insert(_collectionName, {
        'id': transactionId,
        'userId': transactionWithId.userId,
        'userName': transactionWithId.userName,
        'type': transactionWithId.type,
        'amount': transactionWithId.amount,
        'principalAmount': transactionWithId.principalAmount,
        'interestAmount': transactionWithId.interestAmount,
        'transactionDate': transactionWithId.transactionDate.toIso8601String(),
        'status': transactionWithId.status,
        'referenceId': transactionWithId.referenceId,
        'description': transactionWithId.description,
        'metadata': transactionWithId.metadata?.toString(),
        'synced': _connectivity.isOnline ? 1 : 0,
        'pendingSync': _connectivity.isOnline ? 0 : 1,
      });

      if (_connectivity.isOnline) {
        // Save to Firebase
        await _firestore.collection(_collectionName).doc(transactionId).set(transactionWithId.toMap());
      } else {
        // Queue for sync
        await _db.addToSyncQueue(
          entityType: 'transaction',
          entityId: transactionId,
          operation: 'create',
          data: transactionWithId.toMap(),
        );
      }

      return transactionId;
    } catch (e) {
      print('❌ Error creating transaction: $e');
      rethrow;
    }
  }

  // ==================== GET ALL TRANSACTIONS (ADMIN) ====================
  Stream<List<TransactionModel>> getAllTransactionsStream() {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_collectionName)
          .orderBy('transactionDate', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            // Save to local DB for offline access
            for (var doc in snapshot.docs) {
              await _saveToLocal(doc);
            }
            
            return snapshot.docs
                .map((doc) => TransactionModel.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .toList();
          });
    } else {
      // Offline: Read from local database
      return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_collectionName, 
          orderBy: 'transactionDate DESC');
        
        return localData
            .map((data) => TransactionModel.fromMap({
                  ...data,
                  'transactionDate': DateTime.parse(data['transactionDate'] as String),
                }))
            .toList();
      });
    }
  }

  // ==================== GET USER TRANSACTIONS ====================
  Stream<List<TransactionModel>> getUserTransactionsStream(String userId) {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('transactionDate', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            for (var doc in snapshot.docs) {
              await _saveToLocal(doc);
            }
            
            return snapshot.docs
                .map((doc) => TransactionModel.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .toList();
          });
    } else {
      return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_collectionName,
          where: 'userId = ?',
          whereArgs: [userId],
          orderBy: 'transactionDate DESC');
        
        return localData
            .map((data) => TransactionModel.fromMap({
                  ...data,
                  'transactionDate': DateTime.parse(data['transactionDate'] as String),
                }))
            .toList();
      });
    }
  }

  // ==================== GET TRANSACTIONS BY TYPE ====================
  Stream<List<TransactionModel>> getTransactionsByTypeStream(String type) {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_collectionName)
          .where('type', isEqualTo: type)
          .orderBy('transactionDate', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            for (var doc in snapshot.docs) {
              await _saveToLocal(doc);
            }
            
            return snapshot.docs
                .map((doc) => TransactionModel.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .toList();
          });
    } else {
      return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_collectionName,
          where: 'type = ?',
          whereArgs: [type],
          orderBy: 'transactionDate DESC');
        
        return localData
            .map((data) => TransactionModel.fromMap({
                  ...data,
                  'transactionDate': DateTime.parse(data['transactionDate'] as String),
                }))
            .toList();
      });
    }
  }

  // ==================== GET TRANSACTIONS BY DATE RANGE ====================
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (_connectivity.isOnline) {
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('transactionDate', isGreaterThanOrEqualTo: startDate)
            .where('transactionDate', isLessThanOrEqualTo: endDate)
            .orderBy('transactionDate', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => TransactionModel.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList();
      } else {
        final localData = await _db.query(_collectionName,
          orderBy: 'transactionDate DESC');
        
        return localData
            .map((data) => TransactionModel.fromMap({
                  ...data,
                  'transactionDate': DateTime.parse(data['transactionDate'] as String),
                }))
            .where((transaction) =>
                transaction.transactionDate.isAfter(startDate) &&
                transaction.transactionDate.isBefore(endDate))
            .toList();
      }
    } catch (e) {
      print('❌ Error getting transactions by date range: $e');
      return [];
    }
  }

  // ==================== SEARCH TRANSACTIONS ====================
  Stream<List<TransactionModel>> searchTransactions(String query) {
    if (_connectivity.isOnline) {
      return _firestore
          .collection(_collectionName)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => TransactionModel.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }))
                .where((transaction) =>
                    transaction.userName.toLowerCase().contains(query.toLowerCase()) ||
                    transaction.type.toLowerCase().contains(query.toLowerCase()) ||
                    transaction.amount.toString().contains(query) ||
                    (transaction.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
                .toList();
          });
    } else {
      return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
        final localData = await _db.query(_collectionName);
        
        return localData
            .map((data) => TransactionModel.fromMap({
                  ...data,
                  'transactionDate': DateTime.parse(data['transactionDate'] as String),
                }))
            .where((transaction) =>
                transaction.userName.toLowerCase().contains(query.toLowerCase()) ||
                transaction.type.toLowerCase().contains(query.toLowerCase()) ||
                transaction.amount.toString().contains(query) ||
                (transaction.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      });
    }
  }

  // ==================== DELETE TRANSACTION ====================
  Future<void> deleteTransaction(String transactionId) async {
    try {
      if (_connectivity.isOnline) {
        await _firestore.collection(_collectionName).doc(transactionId).delete();
        await _db.delete(_collectionName, where: 'id = ?', whereArgs: [transactionId]);
      } else {
        await _db.update(_collectionName, {
          'pendingSync': 1,
          'synced': 0,
        }, where: 'id = ?', whereArgs: [transactionId]);
        
        await _db.addToSyncQueue(
          entityType: 'transaction',
          entityId: transactionId,
          operation: 'delete',
          data: {},
        );
      }
    } catch (e) {
      print('❌ Error deleting transaction: $e');
      rethrow;
    }
  }

  // ==================== UPDATE TRANSACTION STATUS BY REFERENCE ====================
  Future<void> updateTransactionStatusByReference(String referenceId, String status) async {
    try {
      if (_connectivity.isOnline) {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where('referenceId', isEqualTo: referenceId)
            .get();

        for (var doc in querySnapshot.docs) {
          await _firestore.collection(_collectionName).doc(doc.id).update({
            'status': status,
            'transactionDate': Timestamp.now(), // Update date to approval time
          });
          
          await _db.update(_collectionName, {
            'status': status,
            'transactionDate': DateTime.now().toIso8601String(),
          }, where: 'id = ?', whereArgs: [doc.id]);
        }
      } else {
        // Offline support for status update... requires complex sync logic
        // For now, only updating local DB
        await _db.update(_collectionName, {
          'status': status,
          'transactionDate': DateTime.now().toIso8601String(),
        }, where: 'referenceId = ?', whereArgs: [referenceId]);
      }
    } catch (e) {
      print('❌ Error updating transaction status: $e');
    }
  }

  // ==================== HELPER: SAVE TO LOCAL ====================
  Future<void> _saveToLocal(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    
    await _db.insert(_collectionName, {
      'id': doc.id,
      'userId': data['userId'] ?? '',
      'userName': data['userName'] ?? '',
      'type': data['type'] ?? '',
      'amount': data['amount'] ?? 0,
      'principalAmount': data['principalAmount'],
      'interestAmount': data['interestAmount'],
      'transactionDate': data['transactionDate'] is String 
          ? data['transactionDate'] 
          : (data['transactionDate'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      'status': data['status'] ?? 'completed',
      'referenceId': data['referenceId'],
      'description': data['description'],
      'metadata': data['metadata']?.toString(),
      'synced': 1,
      'pendingSync': 0,
    });
  }
}
