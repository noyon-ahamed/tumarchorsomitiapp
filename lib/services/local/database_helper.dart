import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'foundation_app.db');

    return await openDatabase(
      path,
      version: 13, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🗄️ Creating database tables...');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        uid TEXT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        photoUrl TEXT,
        role TEXT DEFAULT 'user',
        status TEXT DEFAULT 'Pending',
        balance REAL DEFAULT 0,
        totalDeposits REAL DEFAULT 0,
        totalWithdrawals REAL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        lastLoginAt TEXT,
        approvedBy TEXT,
        approvedAt TEXT,
        rejectedBy TEXT,
        rejectedAt TEXT,
        blockedBy TEXT,
        blockedAt TEXT,
        fcmToken TEXT,
        fcmTokenUpdatedAt TEXT,
        synced INTEGER DEFAULT 0,
        pendingSync INTEGER DEFAULT 0
      )
    ''');

    // Loans table
    await db.execute('''
      CREATE TABLE loans (
        id TEXT PRIMARY KEY,
        borrowerId TEXT NOT NULL,
        borrowerName TEXT NOT NULL,
        borrowerPhone TEXT NOT NULL,
        loanAmount REAL NOT NULL,
        interestRate REAL NOT NULL,
        totalAmount REAL NOT NULL,
        paidAmount REAL DEFAULT 0,
        remainingAmount REAL NOT NULL,
        installmentAmount REAL NOT NULL,
        totalInstallments INTEGER NOT NULL,
        paidInstallments INTEGER DEFAULT 0,
        startDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        createdAt TEXT NOT NULL,
        description TEXT,
        installmentPeriodMonths INTEGER DEFAULT 12,
        monthlyDueAmount REAL DEFAULT 0,
        installmentSchedule TEXT,
        synced INTEGER DEFAULT 0,
        pendingSync INTEGER DEFAULT 0
      )
    ''');

    // Deposits table
    await db.execute('''
      CREATE TABLE deposits (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL,
        reference TEXT NOT NULL,
        status TEXT DEFAULT 'completed',
        addedBy TEXT,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        description TEXT,
        receiptUrl TEXT,
        synced INTEGER DEFAULT 0,
        pendingSync INTEGER DEFAULT 0
      )
    ''');

    // Investments table
    await db.execute('''
      CREATE TABLE investments (
        id TEXT PRIMARY KEY,
        investorId TEXT NOT NULL,
        investorName TEXT NOT NULL,
        projectName TEXT NOT NULL,
        description TEXT,
        investmentAmount REAL NOT NULL,
        expectedReturn REAL NOT NULL,
        actualReturn REAL DEFAULT 0,
        status TEXT DEFAULT 'active',
        startDate TEXT NOT NULL,
        expectedEndDate TEXT NOT NULL,
        actualEndDate TEXT,
        createdAt TEXT NOT NULL,
        sector TEXT,
        riskLevel TEXT,
        synced INTEGER DEFAULT 0,
        pendingSync INTEGER DEFAULT 0
      )
    ''');

    // Transactions table - NEW
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        principalAmount REAL,
        interestAmount REAL,
        transactionDate TEXT NOT NULL,
        status TEXT DEFAULT 'completed',
        referenceId TEXT,
        description TEXT,
        metadata TEXT,
        synced INTEGER DEFAULT 0,
        pendingSync INTEGER DEFAULT 0
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        senderId TEXT NOT NULL,
        recipientId TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        notificationType TEXT DEFAULT 'notification',
        status TEXT DEFAULT 'sent',
        sentAt TEXT NOT NULL,
        readAt TEXT,
        isRead INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0,
        pendingSync INTEGER DEFAULT 0
      )
    ''');

    // ✅ NEW: Broadcast Messages table
    await db.execute('''
      CREATE TABLE broadcast_messages (
        id TEXT PRIMARY KEY,
        senderId TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        recipientType TEXT NOT NULL,
        selectedUserIds TEXT,
        notificationType TEXT DEFAULT 'notification',
        sentAt TEXT NOT NULL,
        readCount INTEGER DEFAULT 0,
        totalRecipients INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0,
        pendingSync INTEGER DEFAULT 0
      )
    ''');

    // Sync Queue table - tracks pending operations
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        attempts INTEGER DEFAULT 0,
        lastAttempt TEXT,
        error TEXT
      )
    ''');

    debugPrint('✅ Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('📊 Upgrading database from v$oldVersion to v$newVersion');
    
    // Version 2 upgrades
    if (oldVersion < 2) {
      // Add broadcast_messages table for existing databases
      await db.execute('''
        CREATE TABLE IF NOT EXISTS broadcast_messages (
          id TEXT PRIMARY KEY,
          senderId TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          recipientType TEXT NOT NULL,
          selectedUserIds TEXT,
          notificationType TEXT DEFAULT 'notification',
          sentAt TEXT NOT NULL,
          readCount INTEGER DEFAULT 0,
          totalRecipients INTEGER DEFAULT 0,
          synced INTEGER DEFAULT 0,
          pendingSync INTEGER DEFAULT 0
        )
      ''');
      debugPrint('✅ Added broadcast_messages table');
    }

    // Version 3 upgrades (Fixing missing columns)
    if (oldVersion < 3) {
      debugPrint('🔧 Applying V3 fixes...');
      
      // Add addedBy to deposits
      try {
        await db.execute('ALTER TABLE deposits ADD COLUMN addedBy TEXT');
        debugPrint('✅ Added addedBy column to deposits');
      } catch (e) {
        debugPrint('⚠️ Column addedBy might already exist: $e');
      }

      // Ensure pendingSync exists in all tables (fix for existing users)
      final tables = ['users', 'loans', 'deposits', 'investments', 'messages', 'broadcast_messages'];
      for (var table in tables) {
        try {
          await db.execute('ALTER TABLE $table ADD COLUMN pendingSync INTEGER DEFAULT 0');
          debugPrint('✅ Added pendingSync to $table');
        } catch (e) {
          // Ignore if column exists
        }
      }
    }
    
    // Version 4 Check (Force fix for any missed migrations)
    if (oldVersion < 4) {
       debugPrint('🔧 Applying V4 fixes (Retrying missing columns)...');
       
       // Retry addedBy
       try {
        var columns = await db.rawQuery('PRAGMA table_info(deposits)');
        bool hasAddedBy = columns.any((c) => c['name'] == 'addedBy');
        if (!hasAddedBy) {
           await db.execute('ALTER TABLE deposits ADD COLUMN addedBy TEXT');
           debugPrint('✅ (Retry) Added addedBy column to deposits');
        }
      } catch (e) {/* Ignore */}
      
      // Retry pendingSync
      final tables = ['users', 'loans', 'deposits', 'investments', 'messages', 'broadcast_messages'];
      for (var table in tables) {
        try {
          var columns = await db.rawQuery('PRAGMA table_info($table)');
          bool hasPendingSync = columns.any((c) => c['name'] == 'pendingSync');
          if (!hasPendingSync) {
            await db.execute('ALTER TABLE $table ADD COLUMN pendingSync INTEGER DEFAULT 0');
            debugPrint('✅ (Retry) Added pendingSync to $table');
          }
        } catch (e) {/* Ignore */}
      }
    }

    // Version 5 Check (Fixing missing user columns)
    if (oldVersion < 5) {
      debugPrint('🔧 Applying V5 fixes (Adding missing user columns)...');
      
      try {
        await db.execute('ALTER TABLE users ADD COLUMN uid TEXT');
        debugPrint('✅ Added uid column to users');
      } catch (e) { debugPrint('⚠️ uid column error: $e'); }

      try {
        await db.execute('ALTER TABLE users ADD COLUMN approvedBy TEXT');
        debugPrint('✅ Added approvedBy column to users');
      } catch (e) { debugPrint('⚠️ approvedBy column error: $e'); }

      try {
      print('✅ Added approvedAt column to users');
      } catch (e) { print('⚠️ approvedAt column error: $e'); }
    }

    // Version 6 Check (Adding missing rejection/blocking columns)
    if (oldVersion < 6) {
      debugPrint('🔧 Applying V6 fixes (Adding missing rejection/blocking columns)...');
      
      try {
        await db.execute('ALTER TABLE users ADD COLUMN rejectedBy TEXT');
        debugPrint('✅ Added rejectedBy column to users');
      } catch (e) { debugPrint('⚠️ rejectedBy column error: $e'); }

      try {
        await db.execute('ALTER TABLE users ADD COLUMN rejectedAt TEXT');
        debugPrint('✅ Added rejectedAt column to users');
      } catch (e) { debugPrint('⚠️ rejectedAt column error: $e'); }

      try {
        await db.execute('ALTER TABLE users ADD COLUMN blockedBy TEXT');
        debugPrint('✅ Added blockedBy column to users');
      } catch (e) { debugPrint('⚠️ blockedBy column error: $e'); }

      try {
        await db.execute('ALTER TABLE users ADD COLUMN blockedAt TEXT');
        debugPrint('✅ Added blockedAt column to users');
      } catch (e) { debugPrint('⚠️ blockedAt column error: $e'); }
    }

    // Version 7 Check (Adding missing investment columns)
    if (oldVersion < 7) {
      debugPrint('🔧 Applying V7 fixes (Adding missing investment columns)...');
      
      try {
        await db.execute('ALTER TABLE investments ADD COLUMN sector TEXT');
        debugPrint('✅ Added sector column to investments');
      } catch (e) { debugPrint('⚠️ sector column error: $e'); }

      try {
        await db.execute('ALTER TABLE investments ADD COLUMN riskLevel TEXT');
        debugPrint('✅ Added riskLevel column to investments');
      } catch (e) { debugPrint('⚠️ riskLevel column error: $e'); }
    }

    // Version 8 Check (Adding transactions table)
    if (oldVersion < 8) {
      debugPrint('🔧 Applying V8 fixes (Adding transactions table)...');
      
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transactions (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            userName TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            principalAmount REAL,
            interestAmount REAL,
            transactionDate TEXT NOT NULL,
            status TEXT DEFAULT 'completed',
            referenceId TEXT,
            description TEXT,
            metadata TEXT,
            synced INTEGER DEFAULT 0,
            pendingSync INTEGER DEFAULT 0
          )
        ''');
        debugPrint('✅ Added transactions table');
      } catch (e) { debugPrint('⚠️ transactions table error: $e'); }
    }

    // Version 9 Check (Adding loan installment columns)
    if (oldVersion < 9) {
      debugPrint('🔧 Applying V9 fixes (Adding loan installment columns)...');
      
      try {
        await db.execute('ALTER TABLE loans ADD COLUMN installmentPeriodMonths INTEGER DEFAULT 12');
        debugPrint('✅ Added installmentPeriodMonths column to loans');
      } catch (e) { debugPrint('⚠️ installmentPeriodMonths column error: $e'); }

      try {
        await db.execute('ALTER TABLE loans ADD COLUMN monthlyDueAmount REAL DEFAULT 0');
        debugPrint('✅ Added monthlyDueAmount column to loans');
      } catch (e) { debugPrint('⚠️ monthlyDueAmount column error: $e'); }
    }

    // Version 10 Check (Adding installmentSchedule column)
    if (oldVersion < 10) {
      debugPrint('🔧 Applying V10 fixes (Adding installmentSchedule column)...');
      
      try {
        await db.execute('ALTER TABLE loans ADD COLUMN installmentSchedule TEXT');
        debugPrint('✅ Added installmentSchedule column to loans');
      } catch (e) { debugPrint('⚠️ installmentSchedule column error: $e'); }
    }

    // Version 12 Check (Adding FCM Token columns & Fix approvedAt)
    if (oldVersion < 12) {
      debugPrint('🔧 Applying V12 fixes (Adding FCM token columns)...');
      
      try {
        await db.execute('ALTER TABLE users ADD COLUMN fcmToken TEXT');
        debugPrint('✅ Added fcmToken column to users');
      } catch (e) { debugPrint('⚠️ fcmToken column error: $e'); }

      try {
        await db.execute('ALTER TABLE users ADD COLUMN fcmTokenUpdatedAt TEXT');
        debugPrint('✅ Added fcmTokenUpdatedAt column to users');
      } catch (e) { debugPrint('⚠️ fcmTokenUpdatedAt column error: $e'); }

      // Fix for potentially missing approvedAt from V5
      try {
        var columns = await db.rawQuery('PRAGMA table_info(users)');
        bool hasApprovedAt = columns.any((c) => c['name'] == 'approvedAt');
        if (!hasApprovedAt) {
           await db.execute('ALTER TABLE users ADD COLUMN approvedAt TEXT');
           debugPrint('✅ (Retry) Added approvedAt column to users');
        }
      } catch (e) {/* Ignore */}
    }

    // Version 13 Check (Fixing missing installmentSchedule in loans from _onCreate)
    if (oldVersion < 13) {
      debugPrint('🔧 Applying V13 fixes (Ensuring installmentSchedule exists)...');
      
      try {
        await db.execute('ALTER TABLE loans ADD COLUMN installmentSchedule TEXT');
        debugPrint('✅ Added installmentSchedule column to loans');
      } catch (e) { 
        // Likely already exists for users who upgraded through v10, but missing for fresh v12 installs
        debugPrint('⚠️ installmentSchedule column might already exist: $e'); 
      }
    }
  }

  // ==================== GENERIC CRUD OPERATIONS ====================

  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      final result = await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Inserted into $table: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Insert error in $table: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );
    } catch (e) {
      debugPrint('❌ Query error in $table: $e');
      return [];
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    try {
      final db = await database;
      final result = await db.update(
        table,
        data,
        where: where,
        whereArgs: whereArgs,
      );
      debugPrint('✅ Updated $table: $result rows');
      return result;
    } catch (e) {
      debugPrint('❌ Update error in $table: $e');
      rethrow;
    }
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      final result = await db.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
      debugPrint('✅ Deleted from $table: $result rows');
      return result;
    } catch (e) {
      debugPrint('❌ Delete error in $table: $e');
      rethrow;
    }
  }

  // ==================== SYNC QUEUE OPERATIONS ====================

  Future<void> addToSyncQueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    try {
      final db = await database;
      await db.insert('sync_queue', {
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation,
        'data': data.toString(),
        'createdAt': DateTime.now().toIso8601String(),
        'attempts': 0,
      });
      debugPrint('📝 Added to sync queue: $entityType - $operation');
    } catch (e) {
      debugPrint('❌ Add to sync queue error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    try {
      final db = await database;
      return await db.query(
        'sync_queue',
        orderBy: 'createdAt ASC',
      );
    } catch (e) {
      debugPrint('❌ Get pending sync items error: $e');
      return [];
    }
  }

  Future<void> removeSyncQueueItem(int id) async {
    try {
      final db = await database;
      await db.delete(
        'sync_queue',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('✅ Removed sync queue item: $id');
    } catch (e) {
      debugPrint('❌ Remove sync queue item error: $e');
    }
  }

  Future<void> updateSyncQueueAttempt(int id, String error) async {
    try {
      final db = await database;
      await db.rawUpdate('''
        UPDATE sync_queue 
        SET attempts = attempts + 1,
            lastAttempt = ?,
            error = ?
        WHERE id = ?
      ''', [DateTime.now().toIso8601String(), error, id]);
    } catch (e) {
      debugPrint('❌ Update sync queue attempt error: $e');
    }
  }

  // ==================== CLEAR DATA ====================

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('users');
      await db.delete('loans');
      await db.delete('deposits');
      await db.delete('investments');
      await db.delete('transactions');
      await db.delete('messages');
      await db.delete('broadcast_messages');
      await db.delete('sync_queue');
      debugPrint('🗑️ All local data cleared');
    } catch (e) {
      debugPrint('❌ Clear data error: $e');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}