import 'package:flutter/material.dart';

/// A bank account linked to the user's profile.
class LinkedAccount {
  final String id;
  final String bank;
  final String fullName;
  final String accountType;
  final String maskedNum;
  final Color color;
  final String initials;
  final String balance;
  final String lastSynced;
  final String status; // 'synced' | 'error'

  const LinkedAccount({
    required this.id,
    required this.bank,
    required this.fullName,
    required this.accountType,
    required this.maskedNum,
    required this.color,
    required this.initials,
    required this.balance,
    required this.lastSynced,
    required this.status,
  });

  LinkedAccount copyWith({String? status, String? lastSynced}) => LinkedAccount(
        id: id,
        bank: bank,
        fullName: fullName,
        accountType: accountType,
        maskedNum: maskedNum,
        color: color,
        initials: initials,
        balance: balance,
        lastSynced: lastSynced ?? this.lastSynced,
        status: status ?? this.status,
      );
}
