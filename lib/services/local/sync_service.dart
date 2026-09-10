import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helper.dart';
import 'connectivity_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = ConnectivityService();
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    debugPrint('🔄 Initializing SyncService...');
    
    // Listen to connectivity changes
    _connectivity.addListener(() {
      if (_connectivity.isOnline) {
        debugPrint('🌐 Online detected: Triggering sync...');
        processSyncQueue();
      }
    });

    // Initial check
    if (await _connectivity.checkConnection()) {
      processSyncQueue();
    }
  }

  // ==================== SYNC PROCESS ====================

  Future<void> processSyncQueue() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    notifyListeners();
    
    debugPrint('🔄 Starting sync process...');
    
    try {
      final pendingItems = await _db.getPendingSyncItems();
      
      if (pendingItems.isEmpty) {
        debugPrint('✅ No pending items to sync');
        _isSyncing = false;
        notifyListeners();
        return;
      }

      debugPrint('📥 Found ${pendingItems.length} items to sync');

      for (var item in pendingItems) {
        try {
          await _processItem(item);
          // Remove from queue on success
          await _db.removeSyncQueueItem(item['id'] as int);
        } catch (e) {
          debugPrint('❌ Error syncing item ${item['id']}: $e');
          // Update attempt count
          await _db.updateSyncQueueAttempt(item['id'] as int, e.toString());
        }
      }
      
      debugPrint('✅ Sync process completed');
    } catch (e) {
      debugPrint('❌ Sync process failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _processItem(Map<String, dynamic> item) async {
    final String entityType = item['entityType'];
    final String entityId = item['entityId'];
    final String operation = item['operation'];
    final Map<String, dynamic> data = jsonDecode(item['data']);
    
    debugPrint('🔄 Processing: $operation $entityType ($entityId)');

    switch (entityType) {
      case 'deposit':
        await _syncDeposit(entityId, operation, data);
        break;
      default:
        debugPrint('⚠️ Unknown entity type: $entityType');
    }
  }

  // ==================== DEPOSIT SYNC ====================

  Future<void> _syncDeposit(String id, String operation, Map<String, dynamic> data) async {
    final collection = _firestore.collection('deposits');
    
    switch (operation) {
      case 'create':
        await collection.doc(id).set(data);
        if (data['status']?.toString().toLowerCase() == 'completed') {
           await _updateUserBalance(data['userId'], (data['amount'] as num).toDouble());
        }
        break;
      case 'update':
        await collection.doc(id).update(data);
        break;
      case 'delete':
        await collection.doc(id).delete();
        break;
    }
  }
  
  // ==================== HELPER ====================
  
  Future<void> _updateUserBalance(String userId, double amount) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final currentBalance = (userDoc.data()?['balance'] ?? 0.0) as num;
        await _firestore.collection('users').doc(userId).update({
          'balance': currentBalance.toDouble() + amount,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error updating user balance during sync: $e');
    }
  }
}