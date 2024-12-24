package com.example.my_sms

import io.flutter.embedding.android.FlutterActivity

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.telephony.SmsManager
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel
import java.lang.Exception

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yourpackage/sms"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Handle platform channel method calls
        flutterEngine?.dartExecutor?.binaryMessenger?.let {
            MethodChannel(it, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "sendSms" -> {
                            val phoneNumber = call.argument<String>("phoneNumber")
                            val message = call.argument<String>("message")
                            sendSms(phoneNumber, message, result)
                        }

                        else -> result.notImplemented()
                    }
                }
        }
    }

    private fun sendSms(phoneNumber: String?, message: String?, result: MethodChannel.Result) {
        // Check if phone number and message are valid
        if (phoneNumber == null || message == null || phoneNumber.isEmpty() || message.isEmpty()) {
            result.error("INVALID_INPUT", "Phone number or message is empty", null)
            return
        }

        // Check for permission
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
            // Request SMS permission if not granted
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.SEND_SMS), 1)
            result.error("PERMISSION_DENIED", "SMS permission denied", null)
            return
        }

        // Send SMS
        try {
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            result.success("SMS sent successfully")
            Toast.makeText(this, "SMS sent successfully", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            result.error("SEND_SMS_ERROR", "Failed to send SMS: ${e.message}", null)
        }
    }

    // Handle permission request results
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1 && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            Toast.makeText(this, "Permission granted", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(this, "Permission denied", Toast.LENGTH_SHORT).show()
        }
    }
}
