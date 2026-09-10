import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String role;
  final String status; // 'Pending', 'Active', 'Rejected', 'Blocked'
  final double balance;
  final double totalDeposits;
  final double totalWithdrawals;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String? adminNotes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? blockedBy;
  final DateTime? blockedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
    this.role = 'user',
    this.status = 'Pending',
    this.balance = 0.0,
    this.totalDeposits = 0.0,
    this.totalWithdrawals = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.adminNotes,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.blockedBy,
    this.blockedAt,
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      role: map['role'] ?? 'user',
      status: map['status'] ?? 'Pending',
      balance: (map['balance'] ?? 0).toDouble(),
      totalDeposits: (map['totalDeposits'] ?? 0).toDouble(),
      totalWithdrawals: (map['totalWithdrawals'] ?? 0).toDouble(),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      lastLoginAt: map['lastLoginAt'] != null 
          ? _parseTimestamp(map['lastLoginAt']) 
          : null,
      adminNotes: map['adminNotes'],
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null 
          ? _parseTimestamp(map['approvedAt']) 
          : null,
      rejectedBy: map['rejectedBy'],
      rejectedAt: map['rejectedAt'] != null 
          ? _parseTimestamp(map['rejectedAt']) 
          : null,
      blockedBy: map['blockedBy'],
      blockedAt: map['blockedAt'] != null 
          ? _parseTimestamp(map['blockedAt']) 
          : null,
    );
  }

  // Helper method to parse Timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': id, // Keep both for compatibility
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role,
      'status': status,
      'balance': balance,
      'totalDeposits': totalDeposits,
      'totalWithdrawals': totalWithdrawals,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null 
          ? Timestamp.fromDate(lastLoginAt!) 
          : null,
      'adminNotes': adminNotes,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null 
          ? Timestamp.fromDate(approvedAt!) 
          : null,
      'rejectedBy': rejectedBy,
      'rejectedAt': rejectedAt != null 
          ? Timestamp.fromDate(rejectedAt!) 
          : null,
      'blockedBy': blockedBy,
      'blockedAt': blockedAt != null 
          ? Timestamp.fromDate(blockedAt!) 
          : null,
    };
  }

  // Create a copy with modified fields
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
    String? status,
    double? balance,
    double? totalDeposits,
    double? totalWithdrawals,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? adminNotes,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedBy,
    DateTime? rejectedAt,
    String? blockedBy,
    DateTime? blockedAt,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      balance: balance ?? this.balance,
      totalDeposits: totalDeposits ?? this.totalDeposits,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      adminNotes: adminNotes ?? this.adminNotes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      blockedBy: blockedBy ?? this.blockedBy,
      blockedAt: blockedAt ?? this.blockedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, status: $status, role: $role)';
  }
}