import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/sensor_data.dart';

class SensorService {
  static const String baseUrl = 'https://sensors-backend-k6qw.onrender.com';
  static const String socketUrl = 'https://sensors-backend-k6qw.onrender.com';
  //   static const String baseUrl = 'http://10.7.233.95:3000';
  // static const String socketUrl = 'http://10.7.233.95:3000';
  late IO.Socket socket;
  bool _isInitialized = false;

  SensorService() {
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Connected to Socket.IO server');
      _isInitialized = true;
    });

    socket.onDisconnect((_) {
      print('Disconnected from Socket.IO server');
      _isInitialized = false;
    });

    socket.onError((error) {
      print('Socket.IO error: $error');
      _isInitialized = false;
    });
  }

  void subscribeToCows(List<String> cowIds) {
    if (!_isInitialized) {
      print('Socket not initialized yet. Will subscribe when connected.');
      socket.onConnect((_) {
        socket.emit('subscribe-cows', cowIds);
        print('Subscribed to cows: $cowIds');
      });
    } else {
      socket.emit('subscribe-cows', cowIds);
      print('Subscribed to cows: $cowIds');
    }
  }

  Future<List<SensorData>> getHistoricalData(DateTime date) async {
    try {
      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$baseUrl/api/sensors/all?date=$formattedDate'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SensorData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load historical data');
      }
    } catch (e) {
      print('Error fetching historical data: $e');
      rethrow;
    }
  }

  void subscribeToRealTimeData(Function(SensorData) onDataReceived) {
    socket.on('sensor-update', (payload) {
      print('Received sensor-update: $payload');
      final sensorData = SensorData.fromJson(payload['data']);
      onDataReceived(sensorData);
    });
  }

  void dispose() {
    socket.disconnect();
  }
}
