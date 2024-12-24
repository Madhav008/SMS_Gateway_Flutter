import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_sms/Api/routes.dart';
import 'package:my_sms/Api/server.dart';
import 'package:my_sms/section.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  static const platform = MethodChannel('com.yourpackage/sms');
  HttpServer? _server;
  String _localIp = "Not started";
  String _publicIp = "Fetching...";
  int? _port;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('com.yourpackage/sms');

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
    _fetchPublicIp();
    try {
      final serverInfo =
          await startServer(); // Use startServer from server.dart
      setState(() {
        widget._localIp = (serverInfo as Map<String, dynamic>)['ip'];
        widget._port = (serverInfo as Map<String, dynamic>)['port'];
      });
      print('Server started on IP ${widget._localIp} and port ${widget._port}');
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
        setState(() {
          widget._publicIp = result[0].address;
        });
      }
    } catch (e) {
      setState(() {
        widget._publicIp = "Error fetching public IP";
      });
      print("Error fetching public IP: $e");
    }
  }

  // Method to stop server
  Future<void> _stopServer() async {
    try {
      await stopServer(); // Use stopServer from server.dart
      setState(() {
        widget._localIp = "Not started";
        widget._port = null;
        widget._publicIp = "Fetching...";
      });
    } catch (e) {
      print("Error stopping server: $e");
    }
  }


  @override
  void initState() {
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
            IPSection(widget: widget),
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
                if (widget._localIp == "Not started") {
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
                widget._localIp == "Not started"
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

  final MyApp widget;

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
                "Local IP: ${widget._localIp}${widget._port != null ? ':${widget._port}' : ''}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'RobotoMono',
                ),
              ),
              if (widget._localIp != "Not started")
                TextButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                          text:
                              '${widget._localIp}${widget._port != null ? ':${widget._port}' : ''}'),
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
                "Public IP: ${widget._publicIp}:${widget._port != null ? widget._port : ''}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'RobotoMono',
                ),
              ),
              if (widget._publicIp != "Fetching..." &&
                  !widget._publicIp.startsWith("Error"))
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget._publicIp));
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
