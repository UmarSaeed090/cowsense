import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../models/animal.dart';
import 'package:http/http.dart' as http;
import '../models/disease_detection.dart';

class AnimalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _animalsCollection =>
      _firestore.collection('animals');
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _diseaseDetectionsCollection =>
      _firestore.collection('disease_detections');

  // Create a new animal
  Future<Animal> createAnimal(Animal animal, File? imageFile) async {
    try {
      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
        final ref = _storage.ref().child('animal_images/$fileName');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      // Create animal document
      final animalData = animal
          .copyWith(
            imageUrl: imageUrl,
            createdAt: DateTime.now(),
          )
          .toMap();

      final docRef = await _animalsCollection.add(animalData);

      // Add animal reference to user's cows array
      await _usersCollection.doc(animal.userId).update({
        'cows': FieldValue.arrayUnion([animal.tagNumber])
      });

      return animal.copyWith(
        id: docRef.id,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to create animal: $e');
    }
  }

  // Get all animals for a user
  Stream<List<Animal>> getUserAnimals(String userId) {
    return _animalsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Animal.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Get a single animal
  Future<Animal?> getAnimal(String animalId) async {
    try {
      final doc = await _animalsCollection.doc(animalId).get();
      if (doc.exists) {
        return Animal.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get animal: $e');
    }
  }

  // Update an animal
  Future<void> updateAnimal(Animal animal, {File? newImageFile}) async {
    try {
      String? imageUrl = animal.imageUrl;

      // Upload new image if provided
      if (newImageFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}${path.extension(newImageFile.path)}';
        final ref = _storage.ref().child('animal_images/$fileName');
        await ref.putFile(newImageFile);
        imageUrl = await ref.getDownloadURL();
      }

      await _animalsCollection.doc(animal.id).update(
            animal.copyWith(imageUrl: imageUrl).toMap(),
          );
    } catch (e) {
      throw Exception('Failed to update animal: $e');
    }
  }

  // Delete an animal
  Future<void> deleteAnimal(String animalId, String userId) async {
    try {
      // Remove animal reference from user's cows array
      await _usersCollection.doc(userId).update({
        'cows': FieldValue.arrayRemove([animalId])
      });

      // Delete animal document
      await _animalsCollection.doc(animalId).delete();
    } catch (e) {
      throw Exception('Failed to delete animal: $e');
    }
  }

  // Store disease detection result
  Future<void> storeDiseaseDetection({
    required String animalId,
    required String animalTagNumber,
    required String diseaseName,
    required double confidence,
    required String annotatedImageUrl,
  }) async {
    try {
      // Create disease detection record
      final diseaseDetection = DiseaseDetection(
        animalId: animalId,
        animalTagNumber: animalTagNumber,
        diseaseName: diseaseName,
        confidence: confidence,
        annotatedImageUrl: annotatedImageUrl,
        detectedAt: DateTime.now(),
      );

      // Add to disease_detections collection
      await _diseaseDetectionsCollection.add(diseaseDetection.toMap());

      // Update animal's health status
      await _animalsCollection.doc(animalId).update({
        'healthStatus': 'Diseased',
        'lastDiseaseDetection': Timestamp.now(),
        'currentDisease': diseaseName,
      });
    } catch (e) {
      throw Exception('Failed to store disease detection: $e');
    }
  }

  // Store annotated image in Firebase Storage
  Future<String> storeAnnotatedImage(String imageUrl) async {
    try {
      // Download the image from the URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Generate a unique filename
      final fileName =
          'disease_detections/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);

      // Upload to Firebase Storage
      await ref.putData(response.bodyBytes);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to store annotated image: $e');
    }
  }

  // Get disease history for an animal
  Stream<List<DiseaseDetection>> getDiseaseHistory(String animalId) {
    return _diseaseDetectionsCollection
        .where('animalId', isEqualTo: animalId)
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DiseaseDetection.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Delete disease detection record and its image
  Future<void> deleteDiseaseDetection(
      String detectionId, String imageUrl) async {
    try {
      // Delete the document from Firestore
      await _diseaseDetectionsCollection.doc(detectionId).delete();

      // Delete the image from Storage
      if (imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete disease detection: $e');
    }
  }
}
