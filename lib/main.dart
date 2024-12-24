import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:my_sms/Api/routes.dart';
import 'package:my_sms/Api/server.dart';
import 'package:my_sms/TaskHandler.dart';
import 'package:my_sms/section.dart';

void main() {
  FlutterForegroundTask.initCommunicationPort();
  runApp(MyApp());
}

// The callback function should always be a top-level or static function.
@pragma('vm:entry-point')
void startCallback(String? id) {
  print("Stoping the server");
  // Handle the button press
  if (id == 'btn_hello') {
    // Stop the server and stop the service
    stopServer();
    FlutterForegroundTask.stopService();
  }
}

class MyApp extends StatefulWidget {
  static const platform = MethodChannel('com.yourpackage/sms');

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('com.yourpackage/sms');
  MyTaskHandler _taskHandler = MyTaskHandler();

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

  // Updated _startServer Method
  Future<void> _startServer() async {
    await _taskHandler.startServerHandler();
    _startService();
    setState(() {});
  }

  // Method to stop server
  Future<void> _stopServer() async {
    await _taskHandler.stopServerHandler();
    FlutterForegroundTask.stopService();
    setState(() {});
  }

  Future<void> _requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  void _initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<ServiceRequestResult> _startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'HTTP Server is running',
        notificationText: 'http://${_taskHandler.localIp}:${_taskHandler.port}',
        notificationIcon: null,
        // notificationButtons: [
        //   const NotificationButton(id: 'btn_hello', text: 'Stop Server'),
        // ],
        // callback: startCallback,
      );
    }
  }

  Future<ServiceRequestResult> _stopService() {
    return FlutterForegroundTask.stopService();
  }

  @override
  void initState() {
    _requestPermissions();
    _initService();
    DatabaseHelper().updateStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurpleAccent,
        scaffoldBackgroundColor: Color(0xFF0D0D2B), // Dark space theme color
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black.withOpacity(0.8),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('SMS Sender App'),
          automaticallyImplyLeading: false, // Remove the default back icon
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center the content
          children: [
            // Section: IP Information
            SectionTitle(title: "IP Information"),
            IPSection(widget: _taskHandler),
            Divider(),
            // Section: SMS Messages
            SectionTitle(title: "SMS Messages"),
            StreamBuilder<List<SMSMessage>>(
              stream: DatabaseHelper()
                  .smsStream, // Use a stream from DatabaseHelper
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Expanded(
                      child: Center(child: Text('No messages available.')));
                } else {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final message = snapshot.data![index];
                        return ListTile(
                          leading: Icon(
                            _getStatusIcon(message.status),
                            color: _getStatusColor(message.status),
                          ),
                          title: Text(
                            message.message,
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status: ${message.status}',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                'Number: ${message.number}', // Display the phone number here
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
            Divider(),
            ElevatedButton(
              onPressed: () {
                if (_taskHandler.localIp == "Not started") {
                  _startServer();
                } else {
                  _stopServer();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _taskHandler.localIp == "Not started"
                    ? "Start Server"
                    : "Stop Server",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Get icon based on the message status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return Icons.check_circle;
      case 'Pending':
        return Icons.access_time;
      case 'Failed':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

// Get color based on the message status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class IPSection extends StatelessWidget {
  const IPSection({
    super.key,
    required this.widget,
  });

  final MyTaskHandler widget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Local IP: ${widget.localIp}${widget.port != null ? ':${widget.port}' : ''}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'RobotoMono',
                ),
              ),
              if (widget.localIp != "Not started")
                TextButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                          text:
                              '${widget.localIp}${widget.port != null ? ':${widget.port}' : ''}'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        'Local IP copied to clipboard!',
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ));
                  },
                  child: Text(
                    "Copy Local IP",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              Text(
                "Public IP: ${widget.publicIp}:${widget.port != null ? widget.port : ''}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'RobotoMono',
                ),
              ),
              if (widget.publicIp != "Fetching..." &&
                  !widget.publicIp.startsWith("Error"))
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.publicIp));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        'Public IP copied to clipboard!',
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ));
                  },
                  child: Text(
                    "Copy Public IP",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
