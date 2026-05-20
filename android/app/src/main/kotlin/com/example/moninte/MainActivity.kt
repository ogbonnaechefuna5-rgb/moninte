package com.example.moninte

import android.database.Cursor
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.moninte/sms")
            .setMethodCallHandler { call, result ->
                if (call.method == "getSmsList") {
                    result.success(readBankSms())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun readBankSms(): List<Map<String, String>> {
        val messages = mutableListOf<Map<String, String>>()
        val bankKeywords = listOf(
            "gtbank", "gtb", "access bank", "zenith", "uba", "first bank",
            "firstbank", "kuda", "opay", "palmpay", "sterling", "fidelity",
            "union bank", "wema", "stanbic", "fcmb", "jaiz", "polaris",
            "debit", "credit", "transaction", "acct", "account", "balance",
            "ngn", "naira", "transfer", "payment", "pos", "atm", "ussd"
        )
        val cursor: Cursor? = contentResolver.query(
            Uri.parse("content://sms/inbox"),
            arrayOf("_id", "address", "body", "date"),
            null, null,
            "date DESC LIMIT 200"
        )
        cursor?.use {
            val bodyIdx = it.getColumnIndex("body")
            val addrIdx = it.getColumnIndex("address")
            val dateIdx = it.getColumnIndex("date")
            while (it.moveToNext()) {
                val body = it.getString(bodyIdx) ?: continue
                val lower = body.lowercase()
                if (bankKeywords.any { kw -> lower.contains(kw) }) {
                    messages.add(mapOf(
                        "body" to body,
                        "address" to (it.getString(addrIdx) ?: ""),
                        "date" to it.getLong(dateIdx).toString(),
                    ))
                }
            }
        }
        return messages
    }
}
