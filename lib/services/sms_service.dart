import 'package:flutter/services.dart';

class SmsMessage {
  final String body;
  final String address;
  final DateTime date;
  const SmsMessage({required this.body, required this.address, required this.date});
}

class SmsService {
  static const _channel = MethodChannel('com.moninte/sms');

  static Future<List<SmsMessage>> getBankMessages() async {
    try {
      final raw = await _channel.invokeListMethod<Map>('getSmsList') ?? [];
      return raw.map((m) => SmsMessage(
        body: m['body'] as String,
        address: m['address'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(int.parse(m['date'] as String)),
      )).toList();
    } on PlatformException {
      return [];
    }
  }
}
