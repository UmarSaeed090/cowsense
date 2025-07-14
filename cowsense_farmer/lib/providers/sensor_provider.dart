import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../services/sensor_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/movement_analysis_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/alert.dart';

class SensorProvider with ChangeNotifier {
  final SensorService _sensorService;
  final NotificationService _notificationService;
  final StorageService _storageService = StorageService();
  Map<String, List<SensorData>> _historicalDataByAnimal = {};
  Map<String, SensorData> _currentDataByAnimal = {};
  Map<String, List<GPSData>> _movementDataByAnimal = {};
  Map<String, List<MovementData>> _movementAnalysisByAnimal = {};
  Map<String, MovementSummary> _dailyMovementSummaryByAnimal = {};
  Map<String, MovementState> _currentMovementStateByAnimal = {};
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  Map<String, List<Alert>> _alertsByAnimal = {};
  bool _hasUnreadAlert = false;
  List<String> _subscribedCowIds = [];

  SensorProvider(this._sensorService, this._notificationService) {
    _initialize();
  }

  List<SensorData> getHistoricalDataForAnimal(String tagNumber) =>
      _historicalDataByAnimal[tagNumber] ?? [];
  SensorData? getAnimalData(String tagNumber) =>
      _currentDataByAnimal[tagNumber];
  List<GPSData> getMovementDataForAnimal(String tagNumber) =>
      _movementDataByAnimal[tagNumber] ?? [];

  // Get the most recent location data for an animal
  GPSData getLocationDataForAnimal(String tagNumber) {
    final currentData = _currentDataByAnimal[tagNumber];
    if (currentData?.gps != null) {
      return currentData!.gps;
    }

    // Fallback to the last known location from movement data
    final movementData = _movementDataByAnimal[tagNumber];
    if (movementData != null && movementData.isNotEmpty) {
      return movementData.last;
    }

    // Default location if no GPS data available
    return GPSData(
      latitude: 0.0,
      longitude: 0.0,
    );
  }

  List<MovementData> getMovementAnalysisForAnimal(String tagNumber) =>
      _movementAnalysisByAnimal[tagNumber] ?? [];
  MovementSummary? getDailyMovementSummary(String tagNumber) =>
      _dailyMovementSummaryByAnimal[tagNumber];
  MovementState? getCurrentMovementState(String tagNumber) =>
      _currentMovementStateByAnimal[tagNumber];

  /// Get behavior assessment for an animal based on daily movement summary
  String getBehaviorAssessment(String tagNumber) {
    final summary = getDailyMovementSummary(tagNumber);
    if (summary == null) {
      return 'No behavior data available';
    }
    return MovementAnalysisService.getBehaviorAssessment(summary);
  }

  /// Get behavior status color for an animal
  Color getBehaviorStatusColor(String tagNumber) {
    final summary = getDailyMovementSummary(tagNumber);
    if (summary == null) {
      return Colors.grey;
    }
    return MovementAnalysisService.getBehaviorStatusColor(summary);
  }

  /// Check if animal has normal behavior patterns
  bool hasNormalBehavior(String tagNumber) {
    final summary = getDailyMovementSummary(tagNumber);
    if (summary == null) {
      return false;
    }
    return MovementAnalysisService.isNormalDailyBehavior(summary);
  }

  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  List<Alert> getAlertsForAnimal(String tagNumber) =>
      _alertsByAnimal[tagNumber] ?? [];
  bool get hasUnreadAlert => _hasUnreadAlert;

  // Check if user is subscribed to a specific tag number
  bool isSubscribedToTag(String tagNumber) {
    return _subscribedCowIds.contains(tagNumber);
  }

  Future<void> _initialize() async {
    await _loadHistoricalData();
    await _loadAlertsFromStorage();
    _subscribeToRealTimeData();
  }

  Future<void> _loadAlertsFromStorage() async {
    try {
      final alertsMap = await _storageService.getAlerts();

      // Group alerts by animal tag number
      _alertsByAnimal = alertsMap;
      _hasUnreadAlert =
          alertsMap.values.expand((alerts) => alerts).any((a) => !a.read);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }
  }

  Future<void> _saveAlertsToPrefs() async {
    try {
      // Store each alert using the storage service
      for (var entry in _alertsByAnimal.entries) {
        for (var alert in entry.value) {
          await _storageService.storeAlert(entry.key, alert);
        }
      }
      debugPrint('Saved alerts to Hive');
    } catch (e) {
      debugPrint('Error saving alerts: $e');
    }
  }

  Future<void> _fetchLatestData([String? cowId]) async {
    try {
      final url = cowId != null
          ? '${SensorService.baseUrl}/api/sensors/latest?tagNumber=$cowId'
          : '${SensorService.baseUrl}/api/sensors/latest';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> sensorData = json.decode(response.body);
        final tagNumber =
            sensorData['tagNumber'] ?? sensorData['cowId'] ?? '123';
        _currentDataByAnimal[tagNumber] = SensorData.fromJson(sensorData);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching latest data: $e');
    }
  }

  Future<void> _loadHistoricalData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allData = await _sensorService.getHistoricalData(_selectedDate);
      // Group data by animal tag number
      _historicalDataByAnimal = {};
      for (var data in allData) {
        final tagNumber = data.tagNumber;
        if (!_historicalDataByAnimal.containsKey(tagNumber)) {
          _historicalDataByAnimal[tagNumber] = [];
        }
        _historicalDataByAnimal[tagNumber]!.add(data);
      }
      _processMovementData();
      _processMovementAnalysis();
    } catch (e) {
      debugPrint('Error loading historical data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setDate(DateTime date) async {
    _selectedDate = date;
    await _loadHistoricalData();
  }

  void _subscribeToRealTimeData() {
    _sensorService.subscribeToRealTimeData((data) {
      final tagNumber = data.tagNumber;
      _currentDataByAnimal[tagNumber] = data;
      _updateMovementData(tagNumber, data.gps);
      _updateMovementAnalysis(tagNumber, data);
      notifyListeners();
    });
  }

  void _processMovementData() {
    _movementDataByAnimal = {};
    _historicalDataByAnimal.forEach((tagNumber, data) {
      _movementDataByAnimal[tagNumber] = data
          .map((d) => d.gps)
          .where((gps) => _isSignificantMovement(tagNumber, gps))
          .toList();
    });
  }

  void _updateMovementData(String tagNumber, GPSData newGps) {
    if (!_movementDataByAnimal.containsKey(tagNumber)) {
      _movementDataByAnimal[tagNumber] = [];
    }

    if (_isSignificantMovement(tagNumber, newGps)) {
      _movementDataByAnimal[tagNumber]!.add(newGps);
      notifyListeners();
    }
  }

  bool _isSignificantMovement(String tagNumber, GPSData gps) {
    final animalMovementData = _movementDataByAnimal[tagNumber] ?? [];
    if (animalMovementData.isEmpty) return true;

    final lastGps = animalMovementData.last;
    final latDiff = (gps.latitude - lastGps.latitude).abs();
    final lonDiff = (gps.longitude - lastGps.longitude).abs();

    return latDiff > 0.0001 || lonDiff > 0.0001;
  }

  // Status helpers for dashboard
  String getTemperatureStatus(double temp) {
    if (temp < 38.0) return 'LOW';
    if (temp > 40.0) return 'HIGH';
    return 'NORMAL';
  }

  Color getTemperatureColor(double temp) {
    if (temp < 38.0 || temp > 40.0) return Color(0xFFCB2213);
    return Colors.green;
  }

  String getHeartRateStatus(int hr) {
    if (hr < 60) return 'LOW';
    if (hr > 80) return 'HIGH';
    return 'NORMAL';
  }

  Color getHeartRateColor(int hr) {
    if (hr < 60 || hr > 80) return Color(0xFFCB2213);
    return Colors.green;
  }

  String getSpO2Status(int spo2) {
    if (spo2 < 95) return 'LOW';
    return 'NORMAL';
  }

  Color getSpO2Color(int spo2) {
    if (spo2 < 95) return Color(0xFFCB2213);
    return Colors.green;
  }

  String getHumidityStatus(double h) {
    if (h < 40) return 'LOW';
    if (h > 80) return 'HIGH';
    return 'NORMAL';
  }

  Color getHumidityColor(double h) {
    if (h < 40 || h > 80) return Color(0xFFCB2213);
    return Colors.green;
  }

  void addAlert(Alert alert) {
    final tagNumber = alert.tagNumber;

    // Only add alerts for subscribed tag numbers
    if (!_subscribedCowIds.contains(tagNumber)) {
      debugPrint('Ignoring alert for unsubscribed tag: $tagNumber');
      return;
    }

    if (!_alertsByAnimal.containsKey(tagNumber)) {
      _alertsByAnimal[tagNumber] = [];
    }
    _alertsByAnimal[tagNumber]!.insert(0, alert);
    _hasUnreadAlert = true;
    _saveAlertsToPrefs();
    notifyListeners();
  }

  void markAllAlertsRead(String tagNumber) {
    if (_alertsByAnimal.containsKey(tagNumber)) {
      for (var a in _alertsByAnimal[tagNumber]!) {
        a.read = true;
      }
      _hasUnreadAlert =
          _alertsByAnimal.values.expand((alerts) => alerts).any((a) => !a.read);
      _saveAlertsToPrefs();
      notifyListeners();
    }
  }

  void removeAlert(Alert alert) {
    final tagNumber = alert.tagNumber;
    if (_alertsByAnimal.containsKey(tagNumber)) {
      _alertsByAnimal[tagNumber]!.remove(alert);
      _hasUnreadAlert =
          _alertsByAnimal.values.expand((alerts) => alerts).any((a) => !a.read);
      _saveAlertsToPrefs();
      notifyListeners();
    }
  }

  void clearAllAlerts(String tagNumber) {
    if (_alertsByAnimal.containsKey(tagNumber)) {
      _alertsByAnimal[tagNumber]!.clear();
      _hasUnreadAlert =
          _alertsByAnimal.values.expand((alerts) => alerts).any((a) => !a.read);
      _saveAlertsToPrefs();
      notifyListeners();
    }
  }

  void addAlertFromNotification(String title, String body, String tagNumber) {
    // Only store alerts for subscribed tag numbers
    if (!_subscribedCowIds.contains(tagNumber)) {
      debugPrint('Ignoring alert for unsubscribed tag: $tagNumber');
      return;
    }

    addAlert(Alert(
      type: 'Notification',
      message: title,
      value: body,
      time: DateTime.now(),
      isCritical: true,
      read: false,
      tagNumber: tagNumber,
    ));
  }

  void dispose() {
    _sensorService.dispose();
    super.dispose();
  }

  Future<void> fetchLatestDataForCow(String cowId) async {
    await _fetchLatestData(cowId);
  }

  Future<void> updateSubscriptions(List<String> cowIds) async {
    _subscribedCowIds = cowIds;
    debugPrint('Updated subscriptions for cow IDs: $_subscribedCowIds');
    _sensorService.subscribeToCows(cowIds);
    // Fetch latest data for all subscribed cows
    for (final cowId in cowIds) {
      await _fetchLatestData(cowId);
    }
    notifyListeners();
  }

  // Initialize provider with user data
  Future<void> initialize(String userId) async {
    await _loadHistoricalData();
    await _loadAlertsFromStorage();
    _subscribeToRealTimeData();
  }

  // Movement Analysis Methods
  void _processMovementAnalysis() {
    for (final entry in _historicalDataByAnimal.entries) {
      final tagNumber = entry.key;
      final sensorDataList = entry.value;

      if (sensorDataList.isEmpty) continue;

      // Process each sensor reading into movement data
      final movementDataList = <MovementData>[];
      for (int i = 0; i < sensorDataList.length; i++) {
        final sensorData = sensorDataList[i];

        // Skip if MPU6050 data is invalid
        final accel = sensorData.mpu6050.accel;
        final gyro = sensorData.mpu6050.gyro;
        if (accel.x.isNaN ||
            accel.y.isNaN ||
            accel.z.isNaN ||
            gyro.x.isNaN ||
            gyro.y.isNaN ||
            gyro.z.isNaN) {
          continue;
        }

        final recentMovementData = movementDataList.length > 10
            ? movementDataList.sublist(movementDataList.length - 10)
            : movementDataList;

        try {
          final movementData = MovementAnalysisService.processSensorReading(
            sensorData,
            recentMovementData,
          );
          movementDataList.add(movementData);
        } catch (e) {
          debugPrint('Error processing movement data for $tagNumber: $e');
          continue;
        }
      }

      _movementAnalysisByAnimal[tagNumber] = movementDataList;

      // Update current movement state
      if (movementDataList.isNotEmpty) {
        _currentMovementStateByAnimal[tagNumber] = movementDataList.last.state;
      }

      // Generate daily summary
      final dailySummary = MovementAnalysisService.generateDailySummary(
        movementDataList,
        _selectedDate,
      );
      _dailyMovementSummaryByAnimal[tagNumber] = dailySummary;

      // Check for abnormal movement patterns and generate alerts
      _checkForMovementAlerts(tagNumber, movementDataList);
    }
  }

  void _updateMovementAnalysis(String tagNumber, SensorData newData) {
    // Validate MPU6050 data first
    final accel = newData.mpu6050.accel;
    final gyro = newData.mpu6050.gyro;
    if (accel.x.isNaN ||
        accel.y.isNaN ||
        accel.z.isNaN ||
        gyro.x.isNaN ||
        gyro.y.isNaN ||
        gyro.z.isNaN) {
      return; // Skip invalid data
    }

    // Get recent movement data for context
    final recentMovementData = _movementAnalysisByAnimal[tagNumber] ?? [];
    final recentContext = recentMovementData.length > 10
        ? recentMovementData.sublist(recentMovementData.length - 10)
        : recentMovementData;

    // Process the new sensor reading
    try {
      final movementData = MovementAnalysisService.processSensorReading(
        newData,
        recentContext,
      );

      // Add to movement analysis list
      if (!_movementAnalysisByAnimal.containsKey(tagNumber)) {
        _movementAnalysisByAnimal[tagNumber] = [];
      }
      _movementAnalysisByAnimal[tagNumber]!.add(movementData);

      // Keep only last 24 hours of data (assuming 1 reading per minute)
      if (_movementAnalysisByAnimal[tagNumber]!.length > 1440) {
        _movementAnalysisByAnimal[tagNumber]!.removeAt(0);
      }

      // Update current movement state
      _currentMovementStateByAnimal[tagNumber] = movementData.state;

      // Check for alerts
      if (movementData.isAbnormal) {
        _addMovementAlert(tagNumber, movementData);
      }
    } catch (e) {
      debugPrint('Error updating movement analysis for $tagNumber: $e');
    }
  }

  void _checkForMovementAlerts(
      String tagNumber, List<MovementData> movementData) {
    final abnormalMovements = movementData.where((d) => d.isAbnormal).toList();

    for (final abnormalMovement in abnormalMovements) {
      _addMovementAlert(tagNumber, abnormalMovement);
    }

    // Check for prolonged inactivity (more than 4 hours)
    final now = DateTime.now();
    final recentData = movementData
        .where((d) => now.difference(d.timestamp).inHours < 4)
        .toList();

    if (recentData.isNotEmpty) {
      final allStationary = recentData.every((d) =>
          d.state == MovementState.idle || d.state == MovementState.lying);

      if (allStationary && recentData.length > 60) {
        // More than 1 hour of data
        final alert = Alert(
          type: 'movement',
          message: 'Prolonged Inactivity',
          value: 'Animal has been inactive for ${recentData.length} minutes',
          time: now,
          isCritical: false,
          read: false,
          tagNumber: tagNumber,
        );
        _addAlert(tagNumber, alert);
      }
    }
  }

  void _addMovementAlert(String tagNumber, MovementData movementData) {
    final alert = Alert(
      type: 'movement',
      message: 'Abnormal Movement Detected',
      value:
          'Magnitude: ${movementData.magnitude.toStringAsFixed(2)}, State: ${MovementAnalysisService.getMovementStateDisplayName(movementData.state)}',
      time: movementData.timestamp,
      isCritical: true,
      read: false,
      tagNumber: tagNumber,
    );
    _addAlert(tagNumber, alert);
  }

  void _addAlert(String tagNumber, Alert alert) {
    // Only add alerts for subscribed tag numbers
    if (!_subscribedCowIds.contains(tagNumber)) {
      debugPrint(
          'Ignoring internally generated alert for unsubscribed tag: $tagNumber');
      return;
    }

    if (!_alertsByAnimal.containsKey(tagNumber)) {
      _alertsByAnimal[tagNumber] = [];
    }
    _alertsByAnimal[tagNumber]!.add(alert);
    _hasUnreadAlert = true;
    _saveAlertsToPrefs();
    notifyListeners();
  }

  String getMovementStateStatus(MovementState? state) {
    try {
      if (state == null) return 'Unknown';
      return MovementAnalysisService.getMovementStateDisplayName(state);
    } catch (e) {
      debugPrint('Error getting movement state status: $e');
      return 'Unknown';
    }
  }

  String getMovementIntensityForAnimal(String tagNumber) {
    try {
      final recentData = _movementAnalysisByAnimal[tagNumber];
      if (recentData == null || recentData.isEmpty) return 'No Data';

      final recent = recentData.takeLast(10).toList();
      if (recent.isEmpty) return 'No Data';

      final averageAccelIntensity =
          recent.map((d) => d.magnitude).reduce((a, b) => a + b) /
              recent.length;

      final averageGyroIntensity =
          recent.map((d) => d.gyroMagnitude).reduce((a, b) => a + b) /
              recent.length;

      if (averageAccelIntensity.isNaN ||
          averageAccelIntensity.isInfinite ||
          averageGyroIntensity.isNaN ||
          averageGyroIntensity.isInfinite) return 'No Data';

      final intensity = MovementAnalysisService.analyzeMovementIntensity(
          averageAccelIntensity, averageGyroIntensity);
      return MovementAnalysisService.getMovementIntensityDisplayName(intensity);
    } catch (e) {
      debugPrint('Error calculating movement intensity for $tagNumber: $e');
      return 'No Data';
    }
  }

  double getActivityPercentageForAnimal(String tagNumber) {
    try {
      final summary = _dailyMovementSummaryByAnimal[tagNumber];
      if (summary == null) return 0.0;

      final totalTime = summary.activeTime + summary.restingTime;
      if (totalTime.inMinutes == 0) return 0.0;

      final percentage =
          (summary.activeTime.inMinutes / totalTime.inMinutes) * 100;
      return percentage.isNaN || percentage.isInfinite ? 0.0 : percentage;
    } catch (e) {
      debugPrint('Error calculating activity percentage for $tagNumber: $e');
      return 0.0;
    }
  }
}
