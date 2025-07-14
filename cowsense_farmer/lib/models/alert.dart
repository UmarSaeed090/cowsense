import 'package:hive/hive.dart';

part 'alert.g.dart';

@HiveType(typeId: 0)
class Alert {
  @HiveField(0)
  final String type;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final String value;

  @HiveField(3)
  final DateTime time;

  @HiveField(4)
  final bool isCritical;

  @HiveField(5)
  bool read;

  @HiveField(6)
  final String tagNumber;

  Alert({
    required this.type,
    required this.message,
    required this.value,
    required this.time,
    required this.isCritical,
    required this.read,
    required this.tagNumber,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      type: json['type'] as String,
      message: json['message'] as String,
      value: json['value'] as String,
      time: DateTime.parse(json['time'] as String),
      isCritical: json['isCritical'] as bool,
      read: json['read'] as bool,
      tagNumber: json['tagNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        'value': value,
        'time': time.toIso8601String(),
        'isCritical': isCritical,
        'read': read,
        'tagNumber': tagNumber,
      };
}
