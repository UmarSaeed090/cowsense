class SensorData {
  final DHT22Data dht22;
  final MAX30100Data max30100;
  final DS18B20Data ds18b20;
  final GPSData gps;
  final String id;
  final String tagNumber;
  final DateTime timestamp;

  SensorData({
    required this.dht22,
    required this.max30100,
    required this.ds18b20,
    required this.gps,
    required this.id,
    required this.tagNumber,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      dht22: json['dht22'] != null ? DHT22Data.fromJson(json['dht22']) : DHT22Data(temperature: 0, humidity: 0),
      max30100: json['max30100'] != null ? MAX30100Data.fromJson(json['max30100']) : MAX30100Data(heartRate: 0, spo2: 0),
      ds18b20: json['ds18b20'] != null ? DS18B20Data.fromJson(json['ds18b20']) : DS18B20Data(temperature: 0),
      gps: json['gps'] != null ? GPSData.fromJson(json['gps']) : GPSData(latitude: 0, longitude: 0),
      id: json['_id'] ?? '',
      tagNumber: json['tagNumber'] ?? json['cowId'] ?? '123',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }
}

class DHT22Data {
  final double temperature;
  final double humidity;

  DHT22Data({required this.temperature, required this.humidity});

  factory DHT22Data.fromJson(Map<String, dynamic> json) {
    return DHT22Data(
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
    );
  }
}

class MAX30100Data {
  final int heartRate;
  final int spo2;

  MAX30100Data({required this.heartRate, required this.spo2});

  factory MAX30100Data.fromJson(Map<String, dynamic> json) {
    return MAX30100Data(
      heartRate: json['heartRate'],
      spo2: json['spo2'],
    );
  }
}

class DS18B20Data {
  final double temperature;

  DS18B20Data({required this.temperature});

  factory DS18B20Data.fromJson(Map<String, dynamic> json) {
    return DS18B20Data(
      temperature: json['temperature'].toDouble(),
    );
  }
}

class GPSData {
  final double latitude;
  final double longitude;

  GPSData({required this.latitude, required this.longitude});

  factory GPSData.fromJson(Map<String, dynamic> json) {
    return GPSData(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
} 