import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream appointments with only selected fields for a user with 'pending' status
  Stream<List<Appointment>> getPendingAppointmentsForUser(String userId) {
    return _firestore
        .collection('appointments')
        .where('veterinarianId', isEqualTo: userId)
        .where('status', isNotEqualTo: 'completed')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Stream disease detections from /disease_detections collection
  Stream<List<DiseaseDetection>> getDiseaseDetections(List<String> animalIds) {
    if (animalIds.isEmpty) {
      // Return empty stream immediately if no animalIds
      return Stream.value([]);
    }

    // Firestore whereIn supports max 10 elements; trim if more than 10
    final queryAnimalIds =
        animalIds.length > 10 ? animalIds.sublist(0, 10) : animalIds;

    return _firestore
        .collection('disease_detections')
        .where('animalId', whereIn: queryAnimalIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiseaseDetection.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}

/// Appointment model with only required fields
class Appointment {
  final String id;
  final String animalId;
  final String animalName;
  final DateTime? appointmentDate;
  final String? rejectionReason;
  final String status;
  final String veterinarianId;
  final String? reason;

  Appointment({
    required this.id,
    required this.animalId,
    required this.animalName,
    this.appointmentDate,
    this.rejectionReason,
    required this.status,
    required this.veterinarianId,
    this.reason,
  });

  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    final Timestamp? appointmentTimestamp = data['appointmentDate'];
    return Appointment(
      id: id,
      animalId: data['animalId'] ?? '',
      animalName: data['animalName'] ?? '',
      appointmentDate: appointmentTimestamp?.toDate(),
      rejectionReason: data['rejectionReason'],
      status: data['status'] ?? '',
      veterinarianId: data['veterinarianId'] ?? '',
      reason: data['reason'],
    );
  }
}

/// DiseaseDetection model for disease data
class DiseaseDetection {
  final String id;
  final String animalId;
  final String animalTagNumber;
  final String annotatedImageUrl;
  final double confidence;
  final String diseaseName;
  final DateTime? detectedAt;

  DiseaseDetection({
    required this.id,
    required this.animalId,
    required this.animalTagNumber,
    required this.annotatedImageUrl,
    required this.confidence,
    required this.diseaseName,
    this.detectedAt,
  });

  factory DiseaseDetection.fromFirestore(Map<String, dynamic> data, String id) {
    final Timestamp? detectedAtTimestamp = data['detectedAt'];
    return DiseaseDetection(
      id: id,
      animalId: data['animalId'] ?? '',
      animalTagNumber: data['animalTagNumber'] ?? '',
      annotatedImageUrl: data['annotatedImageUrl'] ?? '',
      confidence: (data['confidence'] ?? 0).toDouble(),
      diseaseName: data['diseaseName'] ?? '',
      detectedAt: detectedAtTimestamp?.toDate(),
    );
  }
}
