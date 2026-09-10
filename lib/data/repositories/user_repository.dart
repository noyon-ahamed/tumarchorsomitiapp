import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'deposit_repository.dart';
import '../../services/local/database_helper.dart';
import '../../services/local/connectivity_service.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _db = DatabaseHelper();
  final ConnectivityService _connectivity = ConnectivityService();
  static const String _collectionName = 'users';
  final DepositRepository _depositRepo = DepositRepository();

  // ✅ Get all users stream (Real-time updates for admin dashboard) - WITH OFFLINE SUPPORT
  Stream<List<UserModel>> getAllUsersStream() {
    debugPrint(
        '📊 UserRepository: Getting all users stream (Online: ${_connectivity.isOnline})');

    if (_connectivity.isOnline) {
      return _firestore
          .collection(_collectionName)
          .snapshots()
          .asyncMap((snapshot) async {
        debugPrint('📊 Received ${snapshot.docs.length} users from Firestore');

        // Save to local database
        for (var doc in snapshot.docs) {
          await _saveToLocal(doc);
        }

        final users = snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            final userId = doc.id;

            // Firestore 'balance' is now the net balance (Available Cash)
            // We no longer subtract debt here to avoid double-subtraction
            return UserModel.fromMap({
              ...data,
              'id': userId,
            });
          } catch (e) {
            debugPrint('❌ Error parsing user ${doc.id}: $e');
            rethrow;
          }
        }).toList();

        // Sort by createdAt descending
        users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return users;
      });
    } else {
      // Return data from local database when offline
      return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
        final localData =
            await _db.query(_collectionName, orderBy: 'createdAt DESC');

        return localData.map((data) {
          return UserModel.fromMap({
            ...data,
            'createdAt':
                Timestamp.fromDate(DateTime.parse(data['createdAt'] as String)),
            'updatedAt':
                Timestamp.fromDate(DateTime.parse(data['updatedAt'] as String)),
          });
        }).toList();
      });
    }
  }

  ///dshajkhdshjdfsahkldfsasdsashjdfhjdfs
  // ✅ Get single user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      debugPrint('🔍 UserRepository: Getting user $userId');

      final doc =
          await _firestore.collection(_collectionName).doc(userId).get();

      if (doc.exists) {
        final user = UserModel.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
        debugPrint('✅ User found: ${user.name}');
        return user;
      }

      debugPrint('⚠️ User not found: $userId');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user: $e');
      return null;
    }
  }

  // ✅ Stream of single user (Real-time updates)
  Stream<UserModel?> getUserStream(String userId) {
    debugPrint('📊 UserRepository: Getting user stream for $userId');

    return _firestore
        .collection(_collectionName)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    });
  }

  // ✅ Create or update user
  Future<void> saveUser(UserModel user) async {
    try {
      debugPrint('💾 UserRepository: Saving user ${user.name}');

      await _firestore
          .collection(_collectionName)
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true));

      debugPrint('✅ User saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving user: $e');
      rethrow;
    }
  }

  // ✅ Helper: Save user to local database
  Future<void> _saveToLocal(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final Map<String, dynamic> localData = {
        'id': doc.id,
        'createdAt':
            (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
                DateTime.now().toIso8601String(),
        'updatedAt':
            (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ??
                DateTime.now().toIso8601String(),
        'synced': 1,
        'pendingSync': 0,
      };

      // List of valid columns in local users table to prevent errors from Firestore typos (like 'blance')
      final validColumns = {
        'id',
        'uid',
        'name',
        'email',
        'phone',
        'photoUrl',
        'role',
        'status',
        'balance',
        'totalDeposits',
        'totalWithdrawals',
        'createdAt',
        'updatedAt',
        'lastLoginAt',
        'approvedBy',
        'approvedAt',
        'rejectedBy',
        'rejectedAt',
        'blockedBy',
        'blockedAt',
        'fcmToken',
        'fcmTokenUpdatedAt',
        'synced',
        'pendingSync'
      };

      // Add other fields, converting Timestamp types
      data.forEach((key, value) {
        if (validColumns.contains(key) &&
            key != 'id' &&
            key != 'createdAt' &&
            key != 'updatedAt') {
          if (value is Timestamp) {
            localData[key] = value.toDate().toIso8601String();
          } else {
            localData[key] = value;
          }
        }
      });

      await _db.insert(_collectionName, localData);
    } catch (e) {
      debugPrint('❌ Error saving user to local DB: $e');
    }
  }

  // ✅ Update user status (Admin action) - WITH OFFLINE SUPPORT
  Future<void> updateUserStatus(
    String userId,
    String status, {
    String? adminNotes,
  }) async {
    try {
      debugPrint(
          '🔄 UserRepository: Updating user $userId status to $status (Online: ${_connectivity.isOnline})');

      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add approval/rejection/block metadata
      if (status == 'Active') {
        updateData['approvedBy'] = _auth.currentUser?.uid;
        updateData['approvedAt'] = DateTime.now().toIso8601String();
      } else if (status == 'Rejected') {
        updateData['rejectedBy'] = _auth.currentUser?.uid;
        updateData['rejectedAt'] = DateTime.now().toIso8601String();
      } else if (status == 'Blocked') {
        updateData['blockedBy'] = _auth.currentUser?.uid;
        updateData['blockedAt'] = DateTime.now().toIso8601String();
      }

      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      // Save to local database first
      await _db.update(
        _collectionName,
        {
          ...updateData,
          'synced': _connectivity.isOnline ? 1 : 0,
          'pendingSync': _connectivity.isOnline ? 0 : 1,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Sync to Firebase if online
      if (_connectivity.isOnline) {
        final firestoreData = <String, dynamic>{
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (status == 'Active') {
          firestoreData['approvedBy'] = _auth.currentUser?.uid;
          firestoreData['approvedAt'] = FieldValue.serverTimestamp();
        } else if (status == 'Rejected') {
          firestoreData['rejectedBy'] = _auth.currentUser?.uid;
          firestoreData['rejectedAt'] = FieldValue.serverTimestamp();
        } else if (status == 'Blocked') {
          firestoreData['blockedBy'] = _auth.currentUser?.uid;
          firestoreData['blockedAt'] = FieldValue.serverTimestamp();
        }

        if (adminNotes != null) {
          firestoreData['adminNotes'] = adminNotes;
        }

        await _firestore
            .collection(_collectionName)
            .doc(userId)
            .update(firestoreData);

        debugPrint('✅ User status updated in Firestore');
      } else {
        // Add to sync queue for later
        await _db.addToSyncQueue(
          entityType: 'user',
          entityId: userId,
          operation: 'update',
          data: updateData,
        );
        debugPrint('📝 User status update queued for sync');
      }

      debugPrint('✅ User status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user status: $e');
      rethrow;
    }
  }

  // ✅ Approve user (shortcut method) - WITH OFFLINE SUPPORT
  Future<void> approveUser(String userId) async {
    await updateUserStatus(userId, 'Active');
  }

  // ✅ Reject user (shortcut method) - WITH OFFLINE SUPPORT
  Future<void> rejectUser(String userId) async {
    await updateUserStatus(userId, 'Rejected');
  }

  // ✅ Block user (shortcut method) - WITH OFFLINE SUPPORT
  Future<void> blockUser(String userId) async {
    await updateUserStatus(userId, 'Blocked');
  }

  // ✅ Update user balance
  Future<void> updateUserBalance(String userId, double newBalance) async {
    try {
      debugPrint(
          '💰 UserRepository: Updating balance for $userId to $newBalance');

      await _firestore.collection(_collectionName).doc(userId).update({
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Balance updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user balance: $e');
      rethrow;
    }
  }

  // ✅ Update user total deposits and balance (Migration tool)
  Future<void> updateUserTotalDeposits(
      String userId, double newTotalDeposits) async {
    try {
      debugPrint(
          '💰 UserRepository: Migrating total deposits for $userId to $newTotalDeposits');

      // Fetch current balance to adjust it proportionally?
      // Actually, for migration, we usually want to set the total deposits and balance as provided.
      // But usually Balance = Total Deposits - Total Loaned + Total Paid.
      // For simplicity in migration, we can just update the totalDeposits and balance if specified.

      final doc =
          await _firestore.collection(_collectionName).doc(userId).get();
      if (!doc.exists) return;

      final newBalance = newTotalDeposits;

      await _firestore.collection(_collectionName).doc(userId).update({
        'totalDeposits': newTotalDeposits,
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Migration successful');
    } catch (e) {
      debugPrint('❌ Error migrating total deposits: $e');
      rethrow;
    }
  }

  // ✅ Get pending approval users
  Stream<List<UserModel>> getPendingUsersStream() {
    debugPrint('📊 UserRepository: Getting pending users stream');

    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 Found ${snapshot.docs.length} pending users');

      final users = snapshot.docs
          .map((doc) => UserModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  // ✅ Get users by status
  Stream<List<UserModel>> getUsersByStatusStream(String status) {
    debugPrint('📊 UserRepository: Getting users with status: $status');

    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  // ✅ Delete user
  Future<void> deleteUser(String userId) async {
    try {
      debugPrint('🗑️ UserRepository: Deleting user $userId');

      await _firestore.collection(_collectionName).doc(userId).delete();

      debugPrint('✅ User deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      rethrow;
    }
  }

  // ✅ Search users (local filtering from stream)
  Stream<List<UserModel>> searchUsersStream(String query) {
    debugPrint('🔍 UserRepository: Searching users with query: $query');

    return getAllUsersStream().map((users) {
      if (query.isEmpty) return users;

      final lowerQuery = query.toLowerCase();
      return users.where((user) {
        return user.name.toLowerCase().contains(lowerQuery) ||
            user.email.toLowerCase().contains(lowerQuery) ||
            user.phone.contains(query);
      }).toList();
    });
  }

  // ✅ Get user count by status
  Future<Map<String, int>> getUserCountsByStatus() async {
    try {
      debugPrint('📊 UserRepository: Getting user counts by status');

      final snapshot = await _firestore.collection(_collectionName).get();

      final counts = <String, int>{
        'All': snapshot.docs.length,
        'Active': 0,
        'Pending': 0,
        'Rejected': 0,
        'Blocked': 0,
      };

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'Pending';
        counts[status] = (counts[status] ?? 0) + 1;
      }

      debugPrint('📊 User counts: $counts');
      return counts;
    } catch (e) {
      debugPrint('❌ Error getting user counts: $e');
      return {'All': 0, 'Active': 0, 'Pending': 0, 'Rejected': 0, 'Blocked': 0};
    }
  }

  // ✅ Update user profile
  Future<void> updateUserProfile(
    String userId, {
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      debugPrint('📝 UserRepository: Updating profile for $userId');

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .update(updateData);

      debugPrint('✅ Profile updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLogin': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Error updating last login: $e');
    }
  }

  /// Get total foundation balance (sum of all user balances)
  Future<double> getTotalFoundationBalance() async {
    try {
      if (_connectivity.isOnline) {
        final snapshot = await _firestore.collection('users').get();

        double total = 0;
        for (var doc in snapshot.docs) {
          total += (doc.data()['balance'] as num?)?.toDouble() ?? 0;
        }
        return total;
      } else {
        final localData = await _db.query('users');

        double total = 0;
        for (var data in localData) {
          total += (data['balance'] as num?)?.toDouble() ?? 0;
        }
        return total;
      }
    } catch (e) {
      print('❌ Error getting total foundation balance: $e');
      return 0;
    }
  }

  /// Calculate foundation balance from total deposits
  Future<double> calculateFoundationBalance({
    required double totalDeposits,
  }) async {
    try {
      return totalDeposits;
    } catch (e) {
      print('❌ Error calculating foundation balance: $e');
      return 0;
    }
  }

  // ✅ GLOBAL RECONCILIATION: Fix all users in one click
  Future<void> reconcileAllUsersBalances() async {
    try {
      debugPrint('🔄 Starting Global Balance Reconciliation...');
      final usersSnapshot = await _firestore.collection(_collectionName).get();

      for (var doc in usersSnapshot.docs) {
        final userId = doc.id;

        // 1. Calculate actual total deposits
        final totalDeposits = await _depositRepo.getUserTotalDeposits(userId);
        final newBalance = totalDeposits;

        // 2. Update Firestore
        await _firestore.collection(_collectionName).doc(userId).update({
          'totalDeposits': totalDeposits,
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint(
            '✅ Reconciled User ($userId): Balance: $newBalance, Deposits: $totalDeposits');
      }
      debugPrint('🏁 Global Reconciliation Complete!');
    } catch (e) {
      debugPrint('❌ Error during global reconciliation: $e');
      rethrow;
    }
  }
}
