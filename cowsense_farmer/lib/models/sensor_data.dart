class SensorData {
  final DHT22Data dht22;
  final MAX30100Data max30100;
  final DS18B20Data ds18b20;
  final MPU6050Data mpu6050;
  final GPSData gps;
  final String id;
  final String tagNumber;
  final DateTime timestamp;

  SensorData({
    required this.dht22,
    required this.max30100,
    required this.ds18b20,
    required this.mpu6050,
    required this.gps,
    required this.id,
    required this.tagNumber,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      dht22: json['dht22'] != null
          ? DHT22Data.fromJson(json['dht22'])
          : DHT22Data(temperature: 0, humidity: 0),
      max30100: json['max30100'] != null
          ? MAX30100Data.fromJson(json['max30100'])
          : MAX30100Data(heartRate: 0, spo2: 0),
      ds18b20: json['ds18b20'] != null
          ? DS18B20Data.fromJson(json['ds18b20'])
          : DS18B20Data(temperature: 0),
      mpu6050: json['mpu6050'] != null
          ? MPU6050Data.fromJson(json['mpu6050'])
          : MPU6050Data(
              accel: AccelData(x: 0, y: 0, z: 0),
              gyro: GyroData(x: 0, y: 0, z: 0),
            ),
      gps: json['gps'] != null
          ? GPSData.fromJson(json['gps'])
          : GPSData(latitude: 0, longitude: 0),
      id: json['_id'] ?? '',
      tagNumber: json['tagNumber'] ?? json['cowId'] ?? '123',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
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
      heartRate: (json['heartRate'] as num).toInt(),
      spo2: (json['spo2'] as num).toInt(),
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

class MPU6050Data {
  final AccelData accel;
  final GyroData gyro;

  MPU6050Data({required this.accel, required this.gyro});

  factory MPU6050Data.fromJson(Map<String, dynamic> json) {
    return MPU6050Data(
      accel: AccelData.fromJson(json['accel']),
      gyro: GyroData.fromJson(json['gyro']),
    );
  }
}

class AccelData {
  final double x;
  final double y;
  final double z;

  AccelData({required this.x, required this.y, required this.z});

  factory AccelData.fromJson(Map<String, dynamic> json) {
    return AccelData(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      z: json['z'].toDouble(),
    );
  }
}

class GyroData {
  final double x;
  final double y;
  final double z;

  GyroData({required this.x, required this.y, required this.z});

  factory GyroData.fromJson(Map<String, dynamic> json) {
    return GyroData(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      z: json['z'].toDouble(),
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
