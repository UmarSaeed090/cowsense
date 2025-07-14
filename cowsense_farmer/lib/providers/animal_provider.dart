import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/animal.dart';
import '../models/disease_detection.dart';
import '../services/animal_service.dart';
import '../providers/sensor_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalProvider with ChangeNotifier {
  final AnimalService _animalService = AnimalService();
  final SensorProvider _sensorProvider;
  List<Animal> _animals = [];
  bool _isLoading = false;
  String? _error;
  List<Animal> _criticalHealthAnimals = [];
  List<Animal> _checkupDueAnimals = [];

  AnimalProvider(this._sensorProvider) {
    // Listen to sensor data changes
    _sensorProvider.addListener(_onSensorDataChanged);
  }

  void _onSensorDataChanged() {
    if (_animals.isNotEmpty) {
      _updateHealthStatuses();
    }
  }

  @override
  void dispose() {
    _sensorProvider.removeListener(_onSensorDataChanged);
    super.dispose();
  }

  List<Animal> get animals => _animals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Animal> get criticalHealthAnimals => _criticalHealthAnimals;
  List<Animal> get checkupDueAnimals => _checkupDueAnimals;

  // Initialize provider with user data
  Future<void> initialize(String userId) async {
    await loadUserAnimals(userId);
  }

  // Load user's animals
  Future<void> loadUserAnimals(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _animalService.getUserAnimals(userId).listen((animals) {
        _animals = animals;
        _updateHealthStatuses();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update health statuses based on sensor data and alerts
  void _updateHealthStatuses() {
    _criticalHealthAnimals = _animals.where((animal) {
      final sensorData = _sensorProvider.getAnimalData(animal.tagNumber);
      final alerts = _sensorProvider.getAlertsForAnimal(animal.tagNumber);
      final unreadAlerts = alerts.where((alert) => !alert.read).length;

      // Check for critical sensor readings
      final hasCriticalSensorData = sensorData != null &&
          (_sensorProvider
                      .getTemperatureStatus(sensorData.ds18b20.temperature) ==
                  'HIGH' ||
              _sensorProvider
                      .getHeartRateStatus(sensorData.max30100.heartRate) ==
                  'HIGH' ||
              _sensorProvider.getSpO2Status(sensorData.max30100.spo2) == 'LOW');

      // Animal is critical if it has critical sensor data or unread alerts
      return hasCriticalSensorData || unreadAlerts > 0;
    }).toList();

    _checkupDueAnimals = _animals.where((animal) {
      return animal.healthStatus == 'Diseased';
    }).toList();

    notifyListeners();
  }

  // Add a new animal
  Future<void> addAnimal(Animal animal, {File? imageFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _animalService.createAnimal(animal, imageFile);
      // Refresh sensor subscriptions with updated cow IDs
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(animal.userId)
          .get();
      if (userDoc.exists) {
        final cowIds = List<String>.from(userDoc.data()!['cows'] ?? []);
        _sensorProvider.updateSubscriptions(cowIds);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an animal
  Future<void> updateAnimal(Animal animal, {File? newImageFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _animalService.updateAnimal(animal, newImageFile: newImageFile);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(animal.userId)
          .get();
      if (userDoc.exists) {
        final cowIds = List<String>.from(userDoc.data()!['cows'] ?? []);
        _sensorProvider.updateSubscriptions(cowIds);
      }
      final index = _animals.indexWhere((a) => a.id == animal.id);
      if (index != -1) {
        _animals[index] = animal;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete an animal
  Future<void> deleteAnimal(String animalId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _animalService.deleteAnimal(animalId, userId);
      _animals.removeWhere((animal) => animal.id == animalId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Store disease detection result
  Future<void> storeDiseaseDetection({
    required String animalId,
    required String animalTagNumber,
    required String diseaseName,
    required double confidence,
    required String annotatedImageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _animalService.storeDiseaseDetection(
        animalId: animalId,
        animalTagNumber: animalTagNumber,
        diseaseName: diseaseName,
        confidence: confidence,
        annotatedImageUrl: annotatedImageUrl,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Store annotated image in Firebase Storage
  Future<String> storeAnnotatedImage(String imageUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storedUrl = await _animalService.storeAnnotatedImage(imageUrl);
      _isLoading = false;
      notifyListeners();
      return storedUrl;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Get disease history for an animal
  Stream<List<DiseaseDetection>> getDiseaseHistory(String animalId) {
    return _animalService.getDiseaseHistory(animalId);
  }

  // Delete disease detection record
  Future<void> deleteDiseaseDetection(
      String detectionId, String imageUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _animalService.deleteDiseaseDetection(detectionId, imageUrl);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
