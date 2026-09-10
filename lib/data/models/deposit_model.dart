import 'package:cloud_firestore/cloud_firestore.dart';

class DepositModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String method; 
  final String reference;
  final String status; 
  final String addedBy;
  final DateTime date;
  final DateTime createdAt;
  final String? description;
  final String? receiptUrl;

  DepositModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.method,
    required this.reference,
    required this.status,
    required this.addedBy,
    required this.date,
    required this.createdAt,
    this.description,
    this.receiptUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'method': method,
      'reference': reference,
      'status': status,
      'addedBy': addedBy,
      'date': date,
      'createdAt': createdAt,
      'description': description,
      'receiptUrl': receiptUrl,
    };
  }

  factory DepositModel.fromMap(Map<String, dynamic> map) {
    return DepositModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      method: map['method'] ?? '',
      reference: map['reference'] ?? '',
      status: map['status'] ?? 'pending',
      addedBy: map['addedBy'] ?? '',
      date: map['date'] is DateTime 
          ? map['date'] 
          : (map['date'] is Timestamp 
              ? (map['date'] as Timestamp).toDate()
              : _parseDate(map['date'])),
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate()
              : _parseDate(map['createdAt'])),
      description: map['description'],
      receiptUrl: map['receiptUrl'],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      print('⚠️ Invalid date format: $value, using current time');
      return DateTime.now();
    }
  }

  DepositModel copyWith({
    String? id,
    String? userId,
    String? userName,
    double? amount,
    String? method,
    String? reference,
    String? status,
    String? addedBy,
    DateTime? date,
    DateTime? createdAt,
    String? description,
    String? receiptUrl,
  }) {
    return DepositModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      addedBy: addedBy ?? this.addedBy,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
}
