import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// SMSMessage model
class SMSMessage {
  int? id;
  final String number;
  final String message;
  String status; // New status field

  SMSMessage({
    this.id,
    required this.number,
    required this.message,
    this.status = 'Pending', // Default status is 'Pending'
  });

  // Convert SMSMessage to a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'message': message,
      'status': status, // Include status in map
    };
  }

  // Convert SQLite map to an SMSMessage object
  factory SMSMessage.fromMap(Map<String, dynamic> map) {
    return SMSMessage(
      id: map['id'],
      number: map['number'],
      message: map['message'],
      status: map['status'] ??
          'Pending', // Default to 'Pending' if no status is provided
    );
  }
}

// Database helper class
class DatabaseHelper {
  static Database? _database;
  static final StreamController<List<SMSMessage>> _smsStreamController =
      StreamController<List<SMSMessage>>.broadcast();

  // Singleton pattern: Get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize the SQLite database
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sms_messages.db');
    return openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE sms_messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          number TEXT,
          message TEXT,
          status TEXT
        )
      ''');
    });
  }

  // Update the stream with the latest SMS messages
  void updateStream() {
    print("Updating the stream with the messages");
    _updateStream();
  }

  Future<void> _updateStream() async {
    final smsList = await getAllSMS();
    _smsStreamController.sink.add(smsList);
  }

  // Stream to listen for SMS updates
  Stream<List<SMSMessage>> get smsStream => _smsStreamController.stream;

  // Close the stream controller when no longer needed
  void closeStream() {
    _smsStreamController.close();
  }

  // Insert a new SMS message into the database
  Future<int> insertSMS(SMSMessage message) async {
    final db = await database;
    var id = await db.insert('sms_messages', message.toMap());
    _updateStream(); // Trigger stream update after deletion
    return id;
  }

  // Get all SMS messages from the database
  Future<List<SMSMessage>> getAllSMS() async {
    final db = await database;
    final result = await db.query('sms_messages');
    return result.map((e) => SMSMessage.fromMap(e)).toList();
  }

  // Get a specific SMS message by ID
  Future<SMSMessage?> getSMSById(int id) async {
    final db = await database;
    final result = await db.query(
      'sms_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return SMSMessage.fromMap(result.first);
    }
    return null;
  }

  // Update the status of an SMS message
  Future<int> updateSMSStatus(int id, String status) async {
    final db = await database;
    var count = await db.update(
      'sms_messages',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
    _updateStream(); // Trigger stream update after deletion
    return count;
  }

  // Delete an SMS message by ID
  Future<int> deleteSMS(int id) async {
    final db = await database;
    var count = await db.delete(
      'sms_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
    _updateStream(); // Trigger stream update after deletion
    return count;
  }
}

// Handle incoming HTTP requests
Future<void> handlePostSMS(HttpRequest request) async {
  try {
    final content = await utf8.decoder.bind(request).join();
    final data = jsonDecode(content) as Map<String, dynamic>;

    if (data.containsKey('number') &&
        data['number'] is String &&
        data.containsKey('message') &&
        data['message'] is String) {
      final dbHelper = DatabaseHelper();
      final newMessage = SMSMessage(
        number: data['number'],
        message: data['message'],
        status: 'Pending',
      );

      final id = await dbHelper.insertSMS(newMessage);
      newMessage.id = id;

      // Simulate sending the SMS (Replace with actual logic)
      print('Sending SMS to ${data['number']}: ${data['message']}');

      // Simulate delivery status update (for example, after 5 seconds)
      Future.delayed(Duration(seconds: 5), () async {
        await dbHelper.updateSMSStatus(id, 'Delivered');
      });

      request.response
        ..statusCode = HttpStatus.created
        ..write(jsonEncode({'message': 'SMS sent', 'sms': newMessage.toMap()}))
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': 'Invalid data'}))
        ..close();
    }
  } catch (e) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'error': 'Failed to process request'}))
      ..close();
  }
}

Future<void> handleGetSMS(HttpRequest request) async {
  final dbHelper = DatabaseHelper();
  final messages = await dbHelper.getAllSMS();
  request.response
    ..statusCode = HttpStatus.ok
    ..write(jsonEncode(messages.map((msg) => msg.toMap()).toList()))
    ..close();
}

Future<void> handleGetSMSById(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  if (segments.length == 2) {
    final id = int.tryParse(segments[1]);
    if (id == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': 'Invalid ID'}))
        ..close();
      return;
    }

    final dbHelper = DatabaseHelper();
    final message = await dbHelper.getSMSById(id);
    if (message == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode({'error': 'Message not found'}))
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode(message.toMap()))
        ..close();
    }
  } else {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write(jsonEncode({'error': 'Invalid endpoint'}))
      ..close();
  }
}

Future<void> handleDeleteSMS(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  if (segments.length == 2) {
    final id = int.tryParse(segments[1]);
    if (id == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': 'Invalid ID'}))
        ..close();
      return;
    }

    final dbHelper = DatabaseHelper();
    final deletedCount = await dbHelper.deleteSMS(id);
    if (deletedCount == 0) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode({'error': 'Message not found'}))
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({'message': 'SMS deleted'}))
        ..close();
    }
  } else {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write(jsonEncode({'error': 'Invalid endpoint'}))
      ..close();
  }
}

// Function to handle the routing logic
void handleRequest(HttpRequest request) async {
  final path = request.uri.path;
  final method = request.method;

  if (path == '/sms' && method == 'POST') {
    await handlePostSMS(request);
  } else if (path == '/sms' && method == 'GET') {
    await handleGetSMS(request);
  } else if (path.startsWith('/sms/') && method == 'GET') {
    await handleGetSMSById(request);
  } else if (path.startsWith('/sms/') && method == 'DELETE') {
    await handleDeleteSMS(request);
  } else {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write(jsonEncode({'error': 'Endpoint not found'}))
      ..close();
  }
}

void main() async {
  // Start the HTTP server
  final port = 8080;
  HttpServer.bind(InternetAddress.anyIPv4, port).then((server) {
    print('Server running on http://localhost:$port');
    server.listen(handleRequest);
  }).catchError((e) {
    print('Failed to start server: $e');
  });
}
