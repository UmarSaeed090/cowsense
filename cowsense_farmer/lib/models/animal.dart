import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  final String? id;
  final String tagNumber;
  final String name;
  final String species;
  final int age;
  final double weight;
  final String? identificationMark;
  final String? imageUrl;
  final String userId;
  final DateTime createdAt;
  final String? healthStatus;

  Animal({
    this.id,
    required this.tagNumber,
    required this.name,
    required this.species,
    required this.age,
    required this.weight,
    this.identificationMark,
    this.imageUrl,
    required this.userId,
    required this.createdAt,
    this.healthStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'tagNumber': tagNumber,
      'name': name,
      'species': species,
      'age': age,
      'weight': weight,
      'identificationMark': identificationMark,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt,
      'healthStatus': healthStatus ?? 'Healthy',
    };
  }

  factory Animal.fromMap(Map<String, dynamic> map, String id) {
    return Animal(
      id: id,
      tagNumber: map['tagNumber'] ?? '',
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      age: map['age']?.toInt() ?? 0,
      weight: map['weight']?.toDouble() ?? 0.0,
      identificationMark: map['identificationMark'],
      imageUrl: map['imageUrl'],
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      healthStatus: map['healthStatus'] ?? 'Healthy',
    );
  }

  Animal copyWith({
    String? id,
    String? tagNumber,
    String? name,
    String? species,
    int? age,
    double? weight,
    String? identificationMark,
    String? imageUrl,
    String? userId,
    DateTime? createdAt,
  }) {
    return Animal(
      id: id ?? this.id,
      tagNumber: tagNumber ?? this.tagNumber,
      name: name ?? this.name,
      species: species ?? this.species,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      identificationMark: identificationMark ?? this.identificationMark,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      healthStatus: healthStatus ?? this.healthStatus,
    );
  }
} 

