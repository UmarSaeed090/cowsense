import 'package:cloud_firestore/cloud_firestore.dart';

class DiseaseDetection {
  final String? id;
  final String animalId;
  final String animalTagNumber;
  final String diseaseName;
  final double confidence;
  final String annotatedImageUrl;
  final DateTime detectedAt;

  DiseaseDetection({
    this.id,
    required this.animalId,
    required this.animalTagNumber,
    required this.diseaseName,
    required this.confidence,
    required this.annotatedImageUrl,
    required this.detectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'animalId': animalId,
      'animalTagNumber': animalTagNumber,
      'diseaseName': diseaseName,
      'confidence': confidence,
      'annotatedImageUrl': annotatedImageUrl,
      'detectedAt': Timestamp.fromDate(detectedAt),
    };
  }

  factory DiseaseDetection.fromMap(Map<String, dynamic> map, String id) {
    return DiseaseDetection(
      id: id,
      animalId: map['animalId'] ?? '',
      animalTagNumber: map['animalTagNumber'] ?? '',
      diseaseName: map['diseaseName'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      annotatedImageUrl: map['annotatedImageUrl'] ?? '',
      detectedAt: (map['detectedAt'] as Timestamp).toDate(),
    );
  }
}
