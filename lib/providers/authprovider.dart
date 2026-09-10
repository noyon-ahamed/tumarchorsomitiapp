import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase/firebase_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _userRole;
  String? _userStatus;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;

  bool _needsProfileCompletion = false;

  User? get user => _user;
  String? get userRole => _userRole;
  String? get userStatus => _userStatus;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _userRole == 'admin';
  bool get isApproved => _userStatus == 'Active';
  bool get isPending => _userStatus == 'Pending';
  bool get isRejected => _userStatus == 'Rejected';
  bool get needsProfileCompletion => _needsProfileCompletion;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    debugPrint('AuthProvider._init() starting...');
    _isLoading = true;
    notifyListeners();

    // Add a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 5), () {
      if (_isLoading && _userData == null && _user != null) {
        debugPrint(
            'Timeout: User data not loaded in 5 seconds, using fallback');
        _userData = {
          'id': _user!.uid,
          'name': _user!.displayName ?? 'User',
          'email': _user!.email ?? '',
          'phone': _user!.phoneNumber ?? '',
          'role': 'user',
          'status': 'Active',
          'balance': 0.0,
        };
        _userRole = 'user';
        _userStatus = 'Active';
        _isLoading = false;
        notifyListeners();
      }
    });

    try {
      _user = FirebaseService.currentUser;
      debugPrint('Current user: ${_user?.uid}');
      if (_user != null) {
        await _checkUserProfileStatus().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('User profile check timeout');
          },
        );
      } else {
        debugPrint('No current user');
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
    } finally {
      debugPrint('AuthProvider._init() completed. isLoading now false');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkUserProfileStatus() async {
    if (_user == null) return;

    try {
      debugPrint('Checking user profile status for ${_user!.uid}...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get()
          .timeout(const Duration(seconds: 3));

      if (!userDoc.exists) {
        debugPrint('User document does not exist - needs profile completion');
        _needsProfileCompletion = true;
      } else {
        debugPrint('User document exists - setting up listener');
        _needsProfileCompletion = false;
        await _setupUserDataListener();
      }
    } catch (e) {
      debugPrint('Error checking user profile: $e');
      _needsProfileCompletion = false;
    }
  }

  Future<void> _setupUserDataListener() async {
    if (_user == null) return;

    try {
      await _userDataSubscription?.cancel();

      _userDataSubscription =
          FirebaseService.getUserDataStream(_user!.uid).listen(
        (snapshot) {
          debugPrint('User data snapshot received: ${snapshot.exists}');
          if (snapshot.exists) {
            final fetchedData = snapshot.data() as Map<String, dynamic>?;
            debugPrint('Fetched user data: $fetchedData');
            if (fetchedData != null) {
              _userData = fetchedData;
              _userRole = fetchedData['role'] ?? 'user';
              _userStatus = fetchedData['status'] ?? 'Active';
              debugPrint('User role: $_userRole, status: $_userStatus');
              notifyListeners();
            }
          } else {
            // Create default profile if not found
            debugPrint('User document not found - creating default profile');
            _createDefaultProfile();
          }
        },
        onError: (error) {
          debugPrint('User data stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error setting up user data listener: $e');
    }
  }

  Future<void> _createDefaultProfile() async {
    if (_user == null) return;

    try {
      // Check if this is an admin account (should already exist in Firestore)
      // If not found, create as regular user
      final existingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      // If document exists, use existing data (don't override)
      if (existingDoc.exists) {
        final data = existingDoc.data();
        if (data != null) {
          _userData = data;
          _userRole = data['role'] ?? 'user';
          _userStatus = data['status'] ?? 'Active';
          _needsProfileCompletion = false;
          debugPrint(
              'Profile already exists: role=$_userRole, status=$_userStatus');
          notifyListeners();
          return;
        }
      }

      // Create new profile as regular user (not admin)
      // Admin accounts must be manually created in Firebase Console
      final defaultData = {
        'id': _user!.uid,
        'name': _user!.displayName ?? 'User',
        'email': _user!.email ?? '',
        'phone': _user!.phoneNumber ?? '',
        'photoUrl': _user!.photoURL ?? '',
        'role': 'user', // Default role is user, not admin
        'status': 'Active',
        'balance': 0.0,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      debugPrint('Creating default user profile: $defaultData');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set(defaultData, SetOptions(merge: true));

      _userData = defaultData;
      _userRole = 'user';
      _userStatus = 'Active';
      _needsProfileCompletion = false;

      debugPrint('Default user profile created successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating default profile: $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await FirebaseService.signInWithGoogleOnly();

      if (credential != null) {
        _user = credential.user;
        await _checkUserProfileStatus();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeUserProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    if (_user == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'uid': _user!.uid,
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'photoUrl': _user!.photoURL ?? '',
        'role': 'user',
        'status': 'Pending',
        'balance': 0.0,
        'totalDeposits': 0.0,
        'totalWithdrawals': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      _needsProfileCompletion = false;
      await _setupUserDataListener();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create profile: $e';
      notifyListeners();
      return false;
    }
  }

  // Added for user login with username or email
  Future<bool> signInWithUsernamePassword({
    required String username,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final cleanInput = username.trim();
      debugPrint('🔐 Starting login for: $cleanInput');

      // If user provided an email directly, use direct email/password login
      if (cleanInput.contains('@')) {
        return await signInWithEmailPassword(
          email: cleanInput,
          password: password,
        );
      }

      // 1. Lookup the email associated with this username from Firestore
      QuerySnapshot<Map<String, dynamic>> querySnapshot;
      try {
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: cleanInput)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          // Try lowercase lookup as fallback
          querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: cleanInput.toLowerCase())
              .limit(1)
              .get();
        }
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied') {
          debugPrint('❌ Firestore permission denied on username query: ${fe.message}');
          _errorMessage =
              'Firestore Rules error: unauthenticated read blocked. Please update Firestore Rules or log in with your email.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        rethrow;
      }

      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ Username not found in Firestore: $cleanInput');
        _errorMessage = 'Username not found. Please check your username or try your email.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userData = querySnapshot.docs.first.data();
      final String? email = userData['email'];

      if (email == null || email.isEmpty) {
        debugPrint('❌ Email not found in user document');
        _errorMessage = 'Account configuration error: No email found. Please contact admin.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint('✅ Found email for username: $email');

      // 2. Sign in with Firebase Auth using the resolved email
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = credential.user;
      debugPrint('✅ Firebase Auth successful. UID: ${_user!.uid}');

      // 3. Set user data
      _userData = userData;
      _userRole = userData['role'] ?? 'user';
      _userStatus = userData['status'] ?? 'Active';

      debugPrint('✅ User role: $_userRole, status: $_userStatus');

      // Setup real-time listener for future updates
      await _setupUserDataListener();

      _isLoading = false;
      notifyListeners();

      // Get and save FCM token
      _saveFCMToken();

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error during username login: $e');
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  // Replace the signInWithEmailPassword method in your AuthProvider class with this:

  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🔐 Starting email/password sign in...');

      // Sign in with Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = credential.user;
      debugPrint('✅ Firebase Auth successful. UID: ${_user!.uid}');

      // CRITICAL: Wait for Firestore data to load
      debugPrint('📊 Fetching user data from Firestore...');

      // Try multiple times to get user data (with retries)
      Map<String, dynamic>? userData;
      int retries = 0;
      const maxRetries = 3;

      while (userData == null && retries < maxRetries) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .get()
              .timeout(const Duration(seconds: 5));

          if (userDoc.exists) {
            userData = userDoc.data();
            debugPrint('✅ User data fetched: $userData');
          } else {
            debugPrint('⚠️ User document not found in Firestore');
            // Break loop to allow migration check or error handling
            retries = maxRetries;
          }
        } catch (e) {
          retries++;
          debugPrint('⚠️ Retry $retries/$maxRetries - Error: $e');
          if (retries < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * retries));
          }
        }
      }

      // --- MIGRATION LOGIC START ---
      if (userData == null) {
        debugPrint(
            '⚠️ User not found in "users" collection. Checking "admin" collection for migration...');
        final migrated = await _checkAndMigrateAdmin(email);
        if (migrated) {
          // Retry fetching user data after migration
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .get();
          if (userDoc.exists) {
            userData = userDoc.data();
            debugPrint('✅ User data fetched after migration: $userData');
          }
        }
      }
      // --- MIGRATION LOGIC END ---

      if (userData != null) {
        // Set user data from Firestore
        _userData = userData;
        _userRole = userData['role'] ?? 'user';
        _userStatus = userData['status'] ?? 'Pending';

        debugPrint('✅ User role: $_userRole');
        debugPrint('✅ User status: $_userStatus');

        // Setup real-time listener for future updates
        await _setupUserDataListener();
      } else {
        // No Firestore data found - this should not happen for admin accounts
        debugPrint('❌ No Firestore data found for user');
        _errorMessage = 'Account data not found. Please contact admin.';
        await FirebaseAuth.instance.signOut();
        _user = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();

      // Get and save FCM token
      _saveFCMToken();

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _checkAndMigrateAdmin(String email) async {
    try {
      debugPrint('🕵️‍♀️ Checking for admin in "admin" collection...');
      // Note: This query might fail if the user didn't create an index, but let's try.
      // Alternatively, we can try to find by ID if the ID matches auth UID, but here we only have email.
      // If the admin manually created the doc, the ID might be anything.
      // Let's assume they might have used the Auth UID as doc ID, or we search by email field if it exists.

      // Strategy 1: Check if a doc exists in 'admin' with the same ID as Auth UID
      var adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(_user!.uid)
          .get();

      if (!adminDoc.exists) {
        // Strategy 2: Search by email in 'admin' collection
        final querySnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('email', isEqualTo: email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          adminDoc = querySnapshot.docs.first;
        }
      }

      if (adminDoc.exists) {
        debugPrint(
            '✅ Found admin data in "admin" collection: ${adminDoc.data()}');
        final adminData = adminDoc.data()!;

        // Prepare data for "users" collection
        // Fix typo: "blance" -> "balance"
        double balance = 0.0;
        if (adminData.containsKey('balance')) {
          balance = (adminData['balance'] as num?)?.toDouble() ?? 0.0;
        }

        final newUserData = {
          'uid': _user!.uid,
          'email': email,
          'name': adminData['name'] ?? 'Admin',
          'role': 'admin', // Enforce admin role
          'status': 'Active', // Enforce active status
          'balance': balance,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'migratedFromAdminCollection': true,
        };

        debugPrint('🚀 Migrating admin to "users" collection: $newUserData');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set(newUserData, SetOptions(merge: true));

        debugPrint('✅ Migration successful!');
        return true;
      } else {
        debugPrint('❌ No admin found in "admin" collection for $email');
      }
    } catch (e) {
      debugPrint('❌ Error during admin migration: $e');
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      await _userDataSubscription?.cancel();
      _userDataSubscription = null;

      await FirebaseService.signOut();

      _user = null;
      _userRole = null;
      _userStatus = null;
      _userData = null;
      _needsProfileCompletion = false;

      notifyListeners();
    } catch (e) {}
  }

  Future<void> reloadUserData() async {
    if (_user != null) {
      final data = await FirebaseService.getUserData(_user!.uid);
      if (data != null) {
        _userData = data;
        _userRole = data['role'] ?? 'user';
        _userStatus = data['status'] ?? 'Pending';
        notifyListeners();
      }
    }
  }

  // Save FCM token for push notifications
  Future<void> _saveFCMToken() async {
    if (_user == null) {
      debugPrint('❌ Cannot save FCM token: User is null');
      return;
    }

    try {
      debugPrint('🔄 Getting FCM token for user ${_user!.uid}...');
      final notificationService = NotificationService();
      final token = await notificationService.getFCMToken(_user!.uid);

      if (token != null) {
        debugPrint(
            '✅ FCM Token saved successfully: ${token.substring(0, 10)}...');
        notificationService.listenToTokenRefresh(_user!.uid);
      } else {
        debugPrint('⚠️ Failed to get FCM token (returned null)');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email';
        case 'invalid-credential':
        case 'wrong-password':
          return 'Invalid email or password';
        case 'user-not-found':
          return 'No admin account found with this email';
        case 'operation-not-allowed':
          return 'Sign-in method is not enabled';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'network-request-failed':
          return 'Network error. Check your connection';
        case 'too-many-requests':
          return 'Too many attempts. Try again later';
        default:
          return 'Sign-in failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred: $error';
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }
}
