import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { pending, accepted, rejected, completed, cancelled }

class Appointment {
  final String? id;
  final String animalId;
  final String animalName;
  final String veterinarianId;
  final String veterinarianName;
  final DateTime appointmentDate;
  final String reason;
  final AppointmentStatus status;
  final DateTime createdAt;
  final String? notes;
  final String? rejectionReason;
  final String userId;

  Appointment({
    this.id,
    required this.animalId,
    required this.animalName,
    required this.veterinarianId,
    required this.veterinarianName,
    required this.appointmentDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.notes,
    this.rejectionReason,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'animalId': animalId,
      'animalName': animalName,
      'veterinarianId': veterinarianId,
      'veterinarianName': veterinarianName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'reason': reason,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
      'rejectionReason': rejectionReason,
      'userId': userId,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map, String id) {
    return Appointment(
      id: id,
      animalId: map['animalId'] ?? '',
      animalName: map['animalName'] ?? '',
      veterinarianId: map['veterinarianId'] ?? '',
      veterinarianName: map['veterinarianName'] ?? '',
      appointmentDate: (map['appointmentDate'] as Timestamp).toDate(),
      reason: map['reason'] ?? '',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      notes: map['notes'],
      rejectionReason: map['rejectionReason'],
      userId: map['userId'] ?? '',
    );
  }
}
