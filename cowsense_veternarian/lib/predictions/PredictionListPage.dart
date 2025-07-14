import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/PredictionService.dart';

class PredictionListPage extends StatelessWidget {
  PredictionListPage({Key? key}) : super(key: key);

  final AppointmentService appointmentService = AppointmentService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('User not signed in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Predictions')),
      body: StreamBuilder<List<Appointment>>(
        stream: appointmentService.getPendingAppointmentsForUser(uid),
        builder: (context, appointmentSnapshot) {
          if (appointmentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (appointmentSnapshot.hasError) {
            return Center(child: Text('Error: ${appointmentSnapshot.error}'));
          }
          final appointments = appointmentSnapshot.data ?? [];

          if (appointments.isEmpty) {
            return const Center(child: Text('No predictions available.'));
          }

          // Now nest the disease detection stream
          return StreamBuilder<List<DiseaseDetection>>(
            stream: appointmentService.getDiseaseDetections(
              appointments.map((a) => a.animalId).toList(),
            ),
            builder: (context, diseaseSnapshot) {
              if (diseaseSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (diseaseSnapshot.hasError) {
                return Center(child: Text('Error: ${diseaseSnapshot.error}'));
              }

              final diseaseDetections = diseaseSnapshot.data ?? [];

              // Map disease detections by animalId for quick lookup
              final Map<String, DiseaseDetection> diseaseMap = {
                for (var d in diseaseDetections) d.animalId: d
              };

              return ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  final disease = diseaseMap[appointment.animalId];

                  String dateText = 'Unknown Date';
                  if (appointment.appointmentDate != null) {
                    final dt = appointment.appointmentDate!;
                    dateText = "${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Card(
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          "${appointment.animalName}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Appointment Date: $dateText"),
                            if (disease != null) ...[
                              Text("Disease: ${disease.diseaseName}"),
                              Text("Confidence: ${(disease.confidence * 100).toStringAsFixed(1)}%"),
                            ] else
                              const Text("Disease data not available"),
                            if (appointment.rejectionReason != null)
                              Text("Rejection Reason: ${appointment.rejectionReason}"),
                          ],
                        ),
                        onTap: () {
                          // Pass appointment and disease data combined as a Map or custom object
                          Navigator.pushNamed(
                            context,
                            '/prediction-review',
                            arguments: {
                              'appointment': appointment,
                              'disease': disease,
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
