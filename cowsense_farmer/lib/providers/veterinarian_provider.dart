import 'package:flutter/foundation.dart';
import '../models/veterinarian.dart';
import '../models/appointment.dart';
import '../services/veterinarian_service.dart';
import '../services/chat_service.dart';

class VeterinarianProvider with ChangeNotifier {
  final VeterinarianService _service = VeterinarianService();
  final ChatService _chatService = ChatService();
  List<Veterinarian> _veterinarians = [];
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;

  // Getters
  List<Veterinarian> get veterinarians => _veterinarians;
  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;
  int get dueCheckups => _appointments
      .where((appointment) => appointment.status == AppointmentStatus.pending)
      .length;

  // Initialize provider
  VeterinarianProvider() {
    _loadVeterinarians();
  }
  // Set user ID
  void setUserId(String userId) {
    _userId = userId;
    // Don't call loadAnimalAppointments directly to avoid triggering notifyListeners during build
  }

  // Initialize provider with user ID and load data
  Future<void> initialize(String userId) async {
    _userId = userId;
    if (userId.isNotEmpty) {
      await loadAnimalAppointments(userId);
    }
  }

  // Load veterinarians
  Future<void> _loadVeterinarians() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _service.getVeterinarians().listen(
        (veterinarians) {
          _veterinarians = veterinarians;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load appointments for an animal
  Future<void> loadAnimalAppointments(String animalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _service.getFarmerAppointments(animalId).listen(
        (appointments) {
          _appointments = appointments;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create appointment
  Future<void> createAppointment(Appointment appointment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.createAppointment(appointment);
      await _chatService.createOrGetChatRoom(
        appointment.userId,
        appointment.veterinarianId,
        serviceId: appointment.animalId,
      );
      await loadAnimalAppointments(appointment.userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
      String appointmentId, AppointmentStatus status,
      {String? rejectionReason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateAppointmentStatus(appointmentId, status,
          rejectionReason: rejectionReason);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete appointment
  Future<void> deleteAppointment(
      String appointmentId, String veterinarianId, String animalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteAppointment(appointmentId, veterinarianId, animalId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
