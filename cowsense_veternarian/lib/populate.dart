import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> populateSharedHealthReports() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw Exception('User not signed in');

  final sharedReports = [
    {
      'animalName': 'Daisy',
      'animalId': 'COW001',
      'reportType': 'Health Summary',
      'dateShared': 'May 8th, 2025',
      'status': 'New',
      'farmer': 'John Farmer',
    },
    {
      'animalName': 'Spirit',
      'animalId': 'HOR004',
      'reportType': 'Health Summary',
      'dateShared': 'May 7th, 2025',
      'status': 'New',
      'farmer': 'Alice Green',
    },
    {
      'animalName': 'Shaun',
      'animalId': 'SHE002',
      'reportType': 'Diagnosis Analysis',
      'dateShared': 'May 6th, 2025',
      'status': 'Viewed',
      'farmer': 'Bob White',
    },
    {
      'animalName': 'Wilbur',
      'animalId': 'PIG003',
      'reportType': 'Lab Results',
      'dateShared': 'May 4th, 2025',
      'status': 'Action Taken',
      'farmer': 'Tom Black',
    },
  ];

  final sharedReportsRef = FirebaseFirestore.instance
      .collection('users')
      .doc('veteran')
      .collection(uid)
      .doc('reports')
      .collection('sharedhealthreports');

  final batch = FirebaseFirestore.instance.batch();

  for (final report in sharedReports) {
    final docRef = sharedReportsRef.doc(); // Generate a new document reference for each report
    batch.set(docRef, report);  // Add report data to the batch
  }

  await batch.commit();  // Commit the batch write to Firestore
}
