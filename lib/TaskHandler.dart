import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/task_handler.dart';
import 'package:my_sms/Api/server.dart';

class MyTaskHandler extends TaskHandler {
  static const platform = MethodChannel('com.yourpackage/sms');
  HttpServer? _server;
  String _localIp = "Not started";
  String _publicIp = "Fetching...";
  int? _port;

  // Method to start the server
  Future<void> startServerHandler() async {
    _fetchPublicIp();
    try {
      final serverInfo =
          await startServer(); // Use startServer from server.dart
      _localIp = (serverInfo as Map<String, dynamic>)['ip'];
      _port = (serverInfo as Map<String, dynamic>)['port'];
      print('Server started on IP $_localIp and port $_port');
    } catch (e) {
      print("Error starting server: $e");
    }
  }

  // Method to fetch public IP
  Future<void> _fetchPublicIp() async {
    try {
      final result = await InternetAddress.lookup('api.ipify.org');
      final ipv4 = result
          .firstWhere((element) => element.type == InternetAddressType.IPv4);
      if (ipv4 != null) {
        _publicIp = result[0].address;
      }
    } catch (e) {
      _publicIp = "Error fetching public IP";
      print("Error fetching public IP: $e");
    }
  }

  // Method to stop the server
  Future<void> stopServerHandler() async {
    try {
      await stopServer(); // Use stopServer from server.dart
      _localIp = "Not started";
      _port = null;
      _publicIp = "Fetching...";
    } catch (e) {
      print("Error stopping server: $e");
    }
  }

  // Getter methods to retrieve values
  String get localIp => _localIp;
  String get publicIp => _publicIp;
  int? get port => _port;

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Clean up resources here when the foreground task is destroyed.
    print("Foreground task is being destroyed at $timestamp");

    // Stop the server
    await stopServerHandler();

    // Perform other clean-up tasks if necessary
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // This is called at regular intervals (e.g., every few minutes).
    // You can fetch a new public IP, check server status, or send periodic updates.

    print("Repeat event triggered at $timestamp");

    // Example: Fetch a new public IP periodically
    _fetchPublicIp();

    // Optionally, restart the server if needed
    // startServer();
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize resources when the task starts.
    print("Foreground task started at $timestamp");

    // Start the server and fetch public IP
    await startServerHandler();

    // Optionally, perform other setup tasks here, like setting up a periodic event.
  }
}
