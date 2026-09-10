import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // UPDATED: Google Sign-in configuration
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
      rethrow;
    }
  }

  // ==================== AUTH GETTERS ====================
  
  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static String? get userId => _auth.currentUser?.uid;

  // ==================== GOOGLE SIGN IN (FIXED VERSION) ====================

  static Future<UserCredential?> signInWithGoogleOnly() async {
    UserCredential? userCredential;
    
    try {
      debugPrint('🔐 Starting Google Sign-In...');
      
      // Ensure clean state
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
      } catch (e) {
        debugPrint('⚠️ Sign out warning: $e');
      }
      
      // Trigger Google Sign-In with better error handling
      debugPrint('📱 Opening Google Sign-In dialog...');
      GoogleSignInAccount? googleUser;
      
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (error) {
        debugPrint('❌ Google Sign-In dialog error: $error');
        debugPrint('   Error type: ${error.runtimeType}');
        // Re-throw as a more friendly error
        throw Exception('Google Sign-In failed. Please try again.');
      }
      
      if (googleUser == null) {
        debugPrint('❌ Google Sign-In cancelled by user');
        return null;
      }

      debugPrint('✅ Google account selected: ${googleUser.email}');

      // Get authentication tokens
      debugPrint('🔑 Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Failed to get authentication tokens');
        throw Exception('Failed to get Google authentication tokens');
      }

      debugPrint('✅ Got authentication tokens');

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('✅ Created Firebase credential');

      // Sign in to Firebase
      debugPrint('🔥 Signing in to Firebase...');
      userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('✅ Google Sign-In successful!');
      debugPrint('   UID: ${userCredential.user!.uid}');
      debugPrint('   Email: ${userCredential.user!.email}');
      debugPrint('   Name: ${userCredential.user!.displayName}');
      
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      
      // Sign out on error
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
      } catch (_) {}
      
      rethrow;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error during Google Sign-In');
      debugPrint('   Error: $e');
      debugPrint('   Type: ${e.runtimeType}');
      debugPrint('   Stack trace: $stackTrace');
      
      // Sign out on error
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
      } catch (_) {}
      
      rethrow;
    }
  }

  // Get user data with real-time updates
  static Stream<DocumentSnapshot> getUserDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Get user data error: $e');
      return null;
    }
  }

  static Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] ?? 'user';
    } catch (e) {
      debugPrint('❌ Get role error: $e');
      return 'user';
    }
  }

  static Future<String> getUserStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['status'] ?? 'Pending';
    } catch (e) {
      debugPrint('❌ Get status error: $e');
      return 'Pending';
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('✅ User signed out');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  // ==================== USER MANAGEMENT (ADMIN) ====================

  static Stream<QuerySnapshot> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> approveUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': 'Active',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ User approved');
    } catch (e) {
      debugPrint('❌ Approve user error: $e');
      rethrow;
    }
  }

  static Future<void> rejectUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': 'Rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ User rejected');
    } catch (e) {
      debugPrint('❌ Reject user error: $e');
      rethrow;
    }
  }

  static Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ User data updated');
    } catch (e) {
      debugPrint('❌ Update user data error: $e');
      rethrow;
    }
  }

  // ==================== DEPOSIT METHODS ====================

  static Future<void> addDeposit({
    required String userId,
    required double amount,
    required String method,
    required String reference,
    required DateTime date,
  }) async {
    try {
      final batch = _firestore.batch();

      final depositRef = _firestore.collection('deposits').doc();
      batch.set(depositRef, {
        'id': depositRef.id,
        'userId': userId,
        'amount': amount,
        'method': method,
        'reference': reference,
        'date': Timestamp.fromDate(date),
        'status': 'Completed',
        'addedBy': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'balance': FieldValue.increment(amount),
        'totalDeposits': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint('✅ Deposit added: $amount');
    } catch (e) {
      debugPrint('❌ Add deposit error: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getUserDeposits(String userId) {
    return _firestore
        .collection('deposits')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getAllDeposits() {
    return _firestore
        .collection('deposits')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== LOAN METHODS ====================

  static Future<void> createLoan({
    required String borrowerName,
    required String borrowerPhone,
    required double loanAmount,
    required double interestRate,
    required int totalInstallments,
    required DateTime startDate,
  }) async {
    try {
      final totalAmount = loanAmount + (loanAmount * interestRate / 100);
      final installmentAmount = totalAmount / totalInstallments;
      final dueDate = startDate.add(Duration(days: totalInstallments * 30));

      await _firestore.collection('loans').add({
        'borrowerName': borrowerName,
        'borrowerPhone': borrowerPhone,
        'loanAmount': loanAmount,
        'interestRate': interestRate,
        'totalAmount': totalAmount,
        'paidAmount': 0.0,
        'remainingAmount': totalAmount,
        'installmentAmount': installmentAmount,
        'totalInstallments': totalInstallments,
        'paidInstallments': 0,
        'startDate': Timestamp.fromDate(startDate),
        'dueDate': Timestamp.fromDate(dueDate),
        'status': 'Active',
        'createdBy': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Loan created');
    } catch (e) {
      debugPrint('❌ Create loan error: $e');
      rethrow;
    }
  }

  static Future<void> updateLoanPayment(String loanId, double amount) async {
    try {
      final loanRef = _firestore.collection('loans').doc(loanId);
      final doc = await loanRef.get();
      final data = doc.data()!;

      final newPaidAmount = data['paidAmount'] + amount;
      final newRemainingAmount = data['totalAmount'] - newPaidAmount;
      final newPaidInstallments = data['paidInstallments'] + 1;
      final newStatus = newRemainingAmount <= 0 ? 'Paid' : 'Active';

      await loanRef.update({
        'paidAmount': newPaidAmount,
        'remainingAmount': newRemainingAmount,
        'paidInstallments': newPaidInstallments,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Loan payment updated');
    } catch (e) {
      debugPrint('❌ Update loan payment error: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getAllLoans() {
    return _firestore
        .collection('loans')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== INVESTMENT METHODS ====================

  static Future<void> createInvestment({
    required String title,
    required String category,
    required double amount,
    required double expectedReturn,
    required String duration,
    required DateTime startDate,
    required String description,
  }) async {
    try {
      final months = int.parse(duration.split(' ')[0]);
      final endDate = DateTime(startDate.year, startDate.month + months, startDate.day);

      await _firestore.collection('investments').add({
        'title': title,
        'category': category,
        'amount': amount,
        'expectedReturn': expectedReturn,
        'duration': duration,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'Active',
        'progress': 0.0,
        'description': description,
        'createdBy': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Investment created');
    } catch (e) {
      debugPrint('❌ Create investment error: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getAllInvestments() {
    return _firestore
        .collection('investments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== MESSAGE METHODS ====================

  static Future<void> sendMessage({
    required String recipientType,
    String? recipientId,
    required String title,
    required String message,
    required String notificationType,
  }) async {
    try {
      await _firestore.collection('messages').add({
        'recipientType': recipientType,
        'recipientId': recipientId,
        'title': title,
        'message': message,
        'notificationType': notificationType,
        'readCount': 0,
        'totalRecipients': recipientType == 'all' ? 0 : 1,
        'sentBy': currentUser!.uid,
        'sentAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Message sent');
    } catch (e) {
      debugPrint('❌ Send message error: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getAllMessages() {
    return _firestore
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  // ==================== PAYMENT SUBMISSION (USER) ====================

  static Future<void> submitPayment({
    required double amount,
    required DateTime date,
    required String paymentMethod,
    required String accountNumber,
    required String imagePath,
  }) async {
    try {
      final fileName = 'payments/${currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(File(imagePath));
      final imageUrl = await ref.getDownloadURL();

      await _firestore.collection('payment_submissions').add({
        'userId': currentUser!.uid,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'paymentMethod': paymentMethod,
        'accountNumber': accountNumber,
        'imageUrl': imageUrl,
        'status': 'Pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Payment submitted');
    } catch (e) {
      debugPrint('❌ Submit payment error: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getUserPaymentSubmissions(String userId) {
    return _firestore
        .collection('payment_submissions')
        .where('userId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getAllPaymentSubmissions() {
    return _firestore
        .collection('payment_submissions')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  static Future<void> approvePayment(String paymentId) async {
    try {
      await _firestore.collection('payment_submissions').doc(paymentId).update({
        'status': 'Approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': currentUser!.uid,
      });

      debugPrint('✅ Payment approved');
    } catch (e) {
      debugPrint('❌ Approve payment error: $e');
      rethrow;
    }
  }
}