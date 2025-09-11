package com.example.seniorapp

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.telephony.SmsManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.call/audio"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "makeDirectCall" -> {
                    val number = call.arguments as String
                    makeDirectPhoneCall(number)
                    result.success(null)
                } // ✅ <--- Close the block properly here
                "sendSMS" -> {
                    val arguments = call.arguments as Map<String, String>
                    val phoneNumber = arguments["phone"] ?: ""
                    val message = arguments["message"] ?: ""
                    sendSms(phoneNumber, message)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun makeDirectPhoneCall(phoneNumber: String) {
        val intent = Intent(Intent.ACTION_CALL)
        intent.data = Uri.parse("tel:$phoneNumber")
        startActivity(intent)
    }

    private fun sendSms(phoneNumber: String, message: String) {
        val smsManager = SmsManager.getDefault()
        smsManager.sendTextMessage(phoneNumber, null, message, null, null)
    }
}
