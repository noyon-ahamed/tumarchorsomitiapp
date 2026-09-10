import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String userName;
  final String type; // 'deposit', 'loan_disbursement', 'loan_payment', 'investment'
  final double amount;
  final double? principalAmount; // For loans, principal portion
  final double? interestAmount; // For loans, interest portion
  final DateTime transactionDate;
  final String status; // 'completed', 'pending', 'failed'
  final String? referenceId; // Link to deposit/loan/investment ID
  final String? description;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.amount,
    this.principalAmount,
    this.interestAmount,
    required this.transactionDate,
    required this.status,
    this.referenceId,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'type': type,
      'amount': amount,
      'principalAmount': principalAmount,
      'interestAmount': interestAmount,
      'transactionDate': transactionDate,
      'status': status,
      'referenceId': referenceId,
      'description': description,
      'metadata': metadata,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      principalAmount: map['principalAmount'] != null 
          ? (map['principalAmount'] as num).toDouble() 
          : null,
      interestAmount: map['interestAmount'] != null 
          ? (map['interestAmount'] as num).toDouble() 
          : null,
      transactionDate: map['transactionDate'] is DateTime
          ? map['transactionDate']
          : (map['transactionDate'] is Timestamp
              ? (map['transactionDate'] as Timestamp).toDate()
              : DateTime.now()),
      status: map['status'] ?? 'completed',
      referenceId: map['referenceId'],
      description: map['description'],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata']) 
          : null,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? type,
    double? amount,
    double? principalAmount,
    double? interestAmount,
    DateTime? transactionDate,
    String? status,
    String? referenceId,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      principalAmount: principalAmount ?? this.principalAmount,
      interestAmount: interestAmount ?? this.interestAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      status: status ?? this.status,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }
}
