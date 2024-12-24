// Method to send SMS
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_sms/main.dart';

const platform = MethodChannel('com.yourpackage/sms');

// Method to send SMS
Future<void> sendSms(String phoneNumber, String message) async {
  try {
    final result = await MyApp.platform.invokeMethod('sendSms', {
      'phoneNumber': phoneNumber,
      'message': message,
    });
    print(result); // SMS sent successfully message from Kotlin
  } on PlatformException catch (e) {
    print("Failed to send SMS: ${e.message}");
  }
}
