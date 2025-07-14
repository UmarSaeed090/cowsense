import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/veterinarian.dart';
import '../models/appointment.dart';

class VeterinarianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _veterinariansCollection =>
      _firestore.collection('vet_profiles');
  CollectionReference get _appointmentsCollection =>
      _firestore.collection('appointments');

  // Get all veterinarians
  Stream<List<Veterinarian>> getVeterinarians() {
    return _veterinariansCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Veterinarian.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Get a single veterinarian
  Future<Veterinarian?> getVeterinarian(String veterinarianId) async {
    try {
      final doc = await _veterinariansCollection.doc(veterinarianId).get();

      if (doc.exists) {
        return Veterinarian.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get veterinarian: $e');
    }
  }

  // Create a new appointment
  Future<Appointment> createAppointment(Appointment appointment) async {
    try {
      // Create the appointment document
      final docRef = await _appointmentsCollection.add(appointment.toMap());

      // Update the veterinarian's appointments array
      await _veterinariansCollection.doc(appointment.veterinarianId).update({
        'appointments': FieldValue.arrayUnion([appointment.animalId])
      });

      return appointment;
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // Get appointments for a veterinarian
  Stream<List<Appointment>> getFarmerAppointments(String userId) {
    return _appointmentsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
      String appointmentId, AppointmentStatus status,
      {String? rejectionReason}) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };
      await _appointmentsCollection.doc(appointmentId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Delete appointment
  Future<void> deleteAppointment(
      String appointmentId, String veterinarianId, String animalId) async {
    try {
      // Delete the appointment document
      await _appointmentsCollection.doc(appointmentId).delete();

      // Update the veterinarian's appointments array
      await _veterinariansCollection.doc(veterinarianId).update({
        'appointments': FieldValue.arrayRemove([animalId])
      });
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }
}
