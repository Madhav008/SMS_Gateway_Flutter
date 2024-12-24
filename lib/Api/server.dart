import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:my_sms/Api/routes.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

HttpServer? _server; // Keep a reference to the server instance
String? wifiName,
    wifiBSSID,
    wifiIPv4,
    wifiIPv6,
    wifiGatewayIP,
    wifiBroadcast,
    wifiSubmask;

Future<void> _initNetworkInfo() async {
  final NetworkInfo _networkInfo = NetworkInfo();

  try {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Request permissions as recommended by the plugin documentation
      if (await Permission.locationWhenInUse.request().isGranted) {
        wifiName = await _networkInfo.getWifiName();
      } else {
        wifiName = 'Unauthorized to get Wifi Name';
      }
    } else {
      wifiName = await _networkInfo.getWifiName();
    }
  } on PlatformException catch (e) {
    wifiName = 'Failed to get Wifi Name: ${e.message}';
  }

  try {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Request permissions as recommended by the plugin documentation
      if (await Permission.locationWhenInUse.request().isGranted) {
        wifiBSSID = await _networkInfo.getWifiBSSID();
      } else {
        wifiBSSID = 'Unauthorized to get Wifi BSSID';
      }
    } else {
      wifiBSSID = await _networkInfo.getWifiBSSID();
    }
  } on PlatformException catch (e) {
    wifiBSSID = 'Failed to get Wifi BSSID: ${e.message}';
  }

  try {
    wifiIPv4 = await _networkInfo.getWifiIP();
  } on PlatformException catch (e) {
    wifiIPv4 = 'Failed to get Wifi IPv4: ${e.message}';
  }

  try {
    wifiIPv6 = await _networkInfo.getWifiIPv6();
  } on PlatformException catch (e) {
    wifiIPv6 = 'Failed to get Wifi IPv6: ${e.message}';
  }

  try {
    wifiSubmask = await _networkInfo.getWifiSubmask();
  } on PlatformException catch (e) {
    wifiSubmask = 'Failed to get Wifi submask address: ${e.message}';
  }

  try {
    wifiBroadcast = await _networkInfo.getWifiBroadcast();
  } on PlatformException catch (e) {
    wifiBroadcast = 'Failed to get Wifi broadcast: ${e.message}';
  }

  try {
    wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
  } on PlatformException catch (e) {
    wifiGatewayIP = 'Failed to get Wifi gateway address: ${e.message}';
  }
}

Future<Map<String, dynamic>> startServer() async {
  if (_server != null) {
    print("Server is already running!");
    return {'ip': _server!.address.address, 'port': _server!.port};
  }

  // Bind the server to any IPv4 interface and a specific port
  _server = await HttpServer.bind(
    InternetAddress.anyIPv4,
    8080,
  );

  // Initialize the network info to get local IP details
  await _initNetworkInfo();

  // Get the local IP address (use the wifiIPv4 if available, or the server's own address)
  String? localIp = wifiIPv4 ?? _server!.address.address.toString();

  print("Local IP: ${localIp}");
  print('HTTP Server is running on http://${localIp}:${_server!.port}');

  // Listen for incoming requests
  _server!.listen((HttpRequest request) {
    handleRequest(request); // Delegate request handling to `routes.dart`
  });

  return {'ip': localIp, 'port': _server!.port};
}

Future<void> stopServer() async {
  if (_server == null) {
    print("Server is not running.");
    return;
  }

  await _server!.close(force: true); // Close the server gracefully
  print('HTTP Server has been stopped.');
  _server = null; // Reset the server reference
}
