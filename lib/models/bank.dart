import 'package:flutter/material.dart';

/// Represents a bank option shown during onboarding and account linking.
class Bank {
  final String name;
  final Color color;
  final String initials;

  const Bank(this.name, this.color, this.initials);
}

/// The list of supported Nigerian banks used across onboarding and linked accounts.
const List<Bank> kSupportedBanks = [
  Bank('GTBank', Color(0xFF006B3C), 'GT'),
  Bank('Kuda', Color(0xFF6231AF), 'KB'),
  Bank('OPay', Color(0xFF00B140), 'OP'),
  Bank('Access Bank', Color(0xFFE5501E), 'AB'),
  Bank('First Bank', Color(0xFF003087), 'FB'),
  Bank('UBA', Color(0xFFC8102E), 'UB'),
  Bank('Zenith Bank', Color(0xFFE31E24), 'ZB'),
  Bank('Moniepoint', Color(0xFF0066FF), 'MP'),
  Bank('Stanbic IBTC', Color(0xFF0033A0), 'SI'),
];
