import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

enum MovementState { idle, walking, lying, grazing, standing }

enum MovementIntensity { none, low, moderate, high, veryHigh }

class MovementData {
  final DateTime timestamp;
  final double magnitude;
  final double gyroMagnitude;
  final MovementState state;
  final MovementIntensity intensity;
  final AccelData accel;
  final GyroData gyro;
  final bool isAbnormal;

  MovementData({
    required this.timestamp,
    required this.magnitude,
    required this.gyroMagnitude,
    required this.state,
    required this.intensity,
    required this.accel,
    required this.gyro,
    required this.isAbnormal,
  });
}

class MovementSummary {
  final DateTime date;
  final Duration activeTime;
  final Duration restingTime;
  final int stepCount;
  final double averageActivity;
  final Map<MovementState, Duration> stateDurations;
  final List<DateTime> abnormalMovementTimes;

  MovementSummary({
    required this.date,
    required this.activeTime,
    required this.restingTime,
    required this.stepCount,
    required this.averageActivity,
    required this.stateDurations,
    required this.abnormalMovementTimes,
  });
}

class MovementAnalysisService {
  // Thresholds for movement detection (calibrated for cattle)
  static const double _stationaryThreshold = 0.5;
  static const double _walkingThreshold = 2.0;
  static const double _lyingThreshold = 0.3;

  // Gyroscope thresholds for orientation changes
  static const double _abnormalGyroThreshold = 10.0;

  // Activity intensity thresholds
  static const double _lowActivityThreshold = 1.0;
  static const double _moderateActivityThreshold = 3.0;
  static const double _highActivityThreshold = 6.0;

  /// Normal behavior thresholds for cattle (in hours)
  static const double _normalMinIdleHours = 10.0;
  static const double _normalMaxIdleHours = 14.0;
  static const double _normalMinMovementHours = 8.0;
  static const double _normalMaxMovementHours = 10.0;

  /// Calculate the magnitude of acceleration vector
  static double calculateAccelMagnitude(AccelData accel) {
    return sqrt(pow(accel.x, 2) + pow(accel.y, 2) + pow(accel.z, 2));
  }

  /// Calculate the magnitude of gyroscope vector
  static double calculateGyroMagnitude(GyroData gyro) {
    return sqrt(pow(gyro.x, 2) + pow(gyro.y, 2) + pow(gyro.z, 2));
  }

  /// Determine movement state based on accelerometer and gyroscope data
  static MovementState analyzeMovementState(
    double accelMagnitude,
    double gyroMagnitude,
    AccelData accel,
  ) {
    // Check if lying down (low Z-axis acceleration indicating horizontal position)
    // Use absolute value since Z can be negative depending on orientation
    if (accel.z.abs() < 2.0 && accelMagnitude < _lyingThreshold) {
      return MovementState.lying;
    }

    // Check for grazing pattern (moderate movement with periodic up/down motion)
    // Grazing involves head movements which create gyroscope activity
    if (accelMagnitude >= _stationaryThreshold &&
        accelMagnitude < _walkingThreshold &&
        gyroMagnitude > 0.5 &&
        gyroMagnitude < 3.0) {
      return MovementState.grazing;
    }

    // High gyroscope activity with moderate acceleration indicates head movements while standing
    if (accelMagnitude < _walkingThreshold && gyroMagnitude > 1.0) {
      return MovementState.standing;
    }

    // Classify based on acceleration magnitude and gyroscope activity
    if (accelMagnitude < _stationaryThreshold && gyroMagnitude < 0.5) {
      return MovementState.idle;
    } else if (accelMagnitude < _walkingThreshold) {
      return MovementState.standing;
    } else {
      // Combined walking and running into single walking state
      return MovementState.walking;
    }
  }

  /// Determine movement intensity based on both accelerometer and gyroscope data
  static MovementIntensity analyzeMovementIntensity(
      double accelMagnitude, double gyroMagnitude) {
    // Combine acceleration and rotation for overall movement intensity
    final combinedIntensity = (accelMagnitude * 0.7) + (gyroMagnitude * 0.3);

    if (combinedIntensity < _lowActivityThreshold) {
      return MovementIntensity.none;
    } else if (combinedIntensity < _moderateActivityThreshold) {
      return MovementIntensity.low;
    } else if (combinedIntensity < _highActivityThreshold) {
      return MovementIntensity.moderate;
    } else if (combinedIntensity < _highActivityThreshold * 1.5) {
      return MovementIntensity.high;
    } else {
      return MovementIntensity.veryHigh;
    }
  }

  /// Check for abnormal movement patterns using both accelerometer and gyroscope data
  static bool detectAbnormalMovement(
    double accelMagnitude,
    double gyroMagnitude,
    List<MovementData> recentData,
  ) {
    // Sudden high acceleration (possible distress or impact)
    if (accelMagnitude > 8.0) return true;

    // Excessive gyroscope activity (possible seizure, distress, or violent shaking)
    if (gyroMagnitude > _abnormalGyroThreshold) return true;

    // Unusual combination of high rotation with low movement (possible seizure)
    if (gyroMagnitude > 5.0 && accelMagnitude < 1.0) return true;

    // Very high acceleration with high rotation (possible violent movement or distress)
    if (accelMagnitude > 6.0 && gyroMagnitude > 5.0) return true;

    // Rapid state changes (analyze recent data)
    if (recentData.length >= 5) {
      final recentStates = recentData.takeLast(5).map((d) => d.state).toList();
      final uniqueStates = recentStates.toSet().length;
      if (uniqueStates >= 4) return true; // Too many state changes
    }

    // Check for erratic gyroscope patterns (sudden changes in rotation)
    if (recentData.length >= 3) {
      final recentGyro =
          recentData.takeLast(3).map((d) => d.gyroMagnitude).toList();
      final gyroVariance = _calculateVariance(recentGyro);
      if (gyroVariance > 25.0) return true; // High variance in rotation
    }

    return false;
  }

  /// Calculate variance for detecting erratic patterns
  static double _calculateVariance(List<double> values) {
    if (values.length < 2) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDifferences = values.map((value) => pow(value - mean, 2));
    return squaredDifferences.reduce((a, b) => a + b) / values.length;
  }

  /// Process a single sensor reading into movement data
  static MovementData processSensorReading(
    SensorData sensorData,
    List<MovementData> recentData,
  ) {
    final accelMagnitude = calculateAccelMagnitude(sensorData.mpu6050.accel);
    final gyroMagnitude = calculateGyroMagnitude(sensorData.mpu6050.gyro);

    // Use enhanced analysis that incorporates cattle-specific behaviors
    final state = enhancedMovementAnalysis(
      sensorData.mpu6050.accel,
      sensorData.mpu6050.gyro,
      accelMagnitude,
      gyroMagnitude,
      recentData,
    );

    final intensity = analyzeMovementIntensity(accelMagnitude, gyroMagnitude);

    final isAbnormal = detectAbnormalMovement(
      accelMagnitude,
      gyroMagnitude,
      recentData,
    );

    return MovementData(
      timestamp: sensorData.timestamp,
      magnitude: accelMagnitude,
      gyroMagnitude: gyroMagnitude,
      state: state,
      intensity: intensity,
      accel: sensorData.mpu6050.accel,
      gyro: sensorData.mpu6050.gyro,
      isAbnormal: isAbnormal,
    );
  }

  /// Calculate step count from movement data using both accelerometer and gyroscope
  static int calculateStepCount(List<MovementData> movementData) {
    if (movementData.length < 3) return 0;

    int stepCount = 0;
    double lastPeak = 0;
    bool lastWasPeak = false;

    // Filter data to only include walking states
    final walkingData =
        movementData.where((d) => d.state == MovementState.walking).toList();

    if (walkingData.isEmpty) return 0;

    for (int i = 1; i < walkingData.length - 1; i++) {
      final current = walkingData[i];
      final previous = walkingData[i - 1];
      final next = walkingData[i + 1];

      // Combine acceleration and gyroscope for better step detection
      final currentCombined =
          (current.magnitude * 0.8) + (current.gyroMagnitude * 0.2);
      final previousCombined =
          (previous.magnitude * 0.8) + (previous.gyroMagnitude * 0.2);
      final nextCombined = (next.magnitude * 0.8) + (next.gyroMagnitude * 0.2);

      // Detect peaks that could indicate steps (accounting for animal gait)
      if (currentCombined > previousCombined &&
          currentCombined > nextCombined &&
          currentCombined > 2.0) {
        // Higher threshold for cattle

        if (!lastWasPeak && (currentCombined - lastPeak).abs() > 0.8) {
          // Check if this follows a reasonable step pattern
          final timeDiff = current.timestamp
              .difference(stepCount > 0
                  ? walkingData[i - 1].timestamp
                  : current.timestamp)
              .inMilliseconds;

          // Reasonable step timing for cattle (300ms to 2000ms between steps)
          if (stepCount == 0 || (timeDiff >= 300 && timeDiff <= 2000)) {
            stepCount++;
            lastPeak = currentCombined;
            lastWasPeak = true;
          }
        }
      } else {
        lastWasPeak = false;
      }
    }

    return stepCount;
  }

  /// Generate daily movement summary
  static MovementSummary generateDailySummary(
    List<MovementData> dayData,
    DateTime date,
  ) {
    if (dayData.isEmpty) {
      return MovementSummary(
        date: date,
        activeTime: Duration.zero,
        restingTime: Duration.zero,
        stepCount: 0,
        averageActivity: 0.0,
        stateDurations: {},
        abnormalMovementTimes: [],
      );
    }

    // Calculate state durations
    final stateDurations = <MovementState, Duration>{};
    Duration activeTime = Duration.zero;
    Duration restingTime = Duration.zero;

    for (int i = 0; i < dayData.length - 1; i++) {
      final current = dayData[i];
      final next = dayData[i + 1];
      final duration = next.timestamp.difference(current.timestamp);

      stateDurations[current.state] =
          (stateDurations[current.state] ?? Duration.zero) + duration;

      // Categorize based on cattle behavior patterns
      if (current.state == MovementState.walking ||
          current.state == MovementState.grazing ||
          current.state == MovementState.standing) {
        activeTime += duration; // Standing is considered active time for cattle
      } else {
        restingTime += duration; // Only idle and lying are true rest
      }
    }

    // Calculate average activity
    final averageActivity = dayData.isEmpty
        ? 0.0
        : dayData.map((d) => d.magnitude).reduce((a, b) => a + b) /
            dayData.length;

    // Find abnormal movement times
    final abnormalMovementTimes =
        dayData.where((d) => d.isAbnormal).map((d) => d.timestamp).toList();

    // Calculate step count
    final stepCount = calculateStepCount(dayData);

    return MovementSummary(
      date: date,
      activeTime: activeTime,
      restingTime: restingTime,
      stepCount: stepCount,
      averageActivity: averageActivity,
      stateDurations: stateDurations,
      abnormalMovementTimes: abnormalMovementTimes,
    );
  }

  /// Check if daily behavior patterns are within normal ranges
  static bool isNormalDailyBehavior(MovementSummary summary) {
    final totalHours = 24.0;
    final idleHours = summary.restingTime.inMinutes / 60.0;
    final movementHours = summary.activeTime.inMinutes / 60.0;
    final remainingHours = totalHours - idleHours - movementHours;

    // Check if idle time is within normal range (10-14 hours)
    final isIdleNormal =
        idleHours >= _normalMinIdleHours && idleHours <= _normalMaxIdleHours;

    // Check if movement time is within normal range (8-10 hours)
    final isMovementNormal = movementHours >= _normalMinMovementHours &&
        movementHours <= _normalMaxMovementHours;

    // Allow some flexibility for unaccounted time (up to 2 hours)
    final isTimeAccountedFor = remainingHours <= 2.0;

    return isIdleNormal && isMovementNormal && isTimeAccountedFor;
  }

  /// Get behavior assessment message
  static String getBehaviorAssessment(MovementSummary summary) {
    final idleHours = summary.restingTime.inMinutes / 60.0;
    final movementHours = summary.activeTime.inMinutes / 60.0;

    if (isNormalDailyBehavior(summary)) {
      return 'Normal behavior pattern';
    }

    List<String> issues = [];

    if (idleHours < _normalMinIdleHours) {
      issues.add(
          'Insufficient rest time (${idleHours.toStringAsFixed(1)}h < ${_normalMinIdleHours}h)');
    } else if (idleHours > _normalMaxIdleHours) {
      issues.add(
          'Excessive rest time (${idleHours.toStringAsFixed(1)}h > ${_normalMaxIdleHours}h)');
    }

    if (movementHours < _normalMinMovementHours) {
      issues.add(
          'Insufficient activity (${movementHours.toStringAsFixed(1)}h < ${_normalMinMovementHours}h)');
    } else if (movementHours > _normalMaxMovementHours) {
      issues.add(
          'Excessive activity (${movementHours.toStringAsFixed(1)}h > ${_normalMaxMovementHours}h)');
    }

    return issues.isEmpty ? 'Borderline normal behavior' : issues.join('; ');
  }

  /// Get behavior status color
  static Color getBehaviorStatusColor(MovementSummary summary) {
    if (isNormalDailyBehavior(summary)) {
      return Colors.green;
    }

    final idleHours = summary.restingTime.inMinutes / 60.0;
    final movementHours = summary.activeTime.inMinutes / 60.0;

    // Critical thresholds (beyond which immediate attention may be needed)
    if (idleHours < 8.0 ||
        idleHours > 16.0 ||
        movementHours < 6.0 ||
        movementHours > 12.0) {
      return Colors.red;
    }

    return Colors.orange; // Warning level
  }

  /// Get movement state display name
  static String getMovementStateDisplayName(MovementState state) {
    switch (state) {
      case MovementState.idle:
        return 'Idle';
      case MovementState.walking:
        return 'Walking';
      case MovementState.lying:
        return 'Lying Down';
      case MovementState.grazing:
        return 'Grazing';
      case MovementState.standing:
        return 'Standing';
    }
  }

  /// Get movement intensity display name
  static String getMovementIntensityDisplayName(MovementIntensity intensity) {
    switch (intensity) {
      case MovementIntensity.none:
        return 'None';
      case MovementIntensity.low:
        return 'Low';
      case MovementIntensity.moderate:
        return 'Moderate';
      case MovementIntensity.high:
        return 'High';
      case MovementIntensity.veryHigh:
        return 'Very High';
    }
  }

  /// Get color for movement state
  static Color getMovementStateColor(MovementState state) {
    switch (state) {
      case MovementState.idle:
        return Colors.grey;
      case MovementState.walking:
        return Colors.green;
      case MovementState.lying:
        return Colors.blue;
      case MovementState.grazing:
        return Colors.lightGreen;
      case MovementState.standing:
        return Colors.teal;
    }
  }

  /// Detect specific cattle behavior patterns using combined sensor data
  static MovementState detectSpecificBehavior(
    AccelData accel,
    GyroData gyro,
    double accelMagnitude,
    double gyroMagnitude,
    List<MovementData> recentData,
  ) {
    // Rumination detection: rhythmic jaw movements create specific patterns
    if (_detectRumination(accel, gyro, recentData)) {
      return MovementState.lying; // Cattle typically ruminate while lying
    }

    // Head shaking pattern (could indicate discomfort or flies)
    if (_detectHeadShaking(gyro, gyroMagnitude)) {
      return MovementState.standing;
    }

    // Walking pattern: coordinated movement with regular acceleration patterns
    if (_detectWalkingPattern(accelMagnitude, gyroMagnitude, recentData)) {
      return MovementState.walking;
    }

    return MovementState
        .idle; // Default to idle if no specific behavior detected
  }

  /// Detect rumination behavior pattern
  static bool _detectRumination(
      AccelData accel, GyroData gyro, List<MovementData> recentData) {
    // Rumination creates small, rhythmic movements
    if (recentData.length < 10) return false;

    final recentMagnitudes =
        recentData.takeLast(10).map((d) => d.magnitude).toList();

    // Check for rhythmic pattern (low amplitude, regular frequency)
    final avgMagnitude =
        recentMagnitudes.reduce((a, b) => a + b) / recentMagnitudes.length;
    final isLowAmplitude = avgMagnitude < 1.5;

    if (!isLowAmplitude) return false;

    // Check for regularity in the pattern
    int peaks = 0;
    for (int i = 1; i < recentMagnitudes.length - 1; i++) {
      if (recentMagnitudes[i] > recentMagnitudes[i - 1] &&
          recentMagnitudes[i] > recentMagnitudes[i + 1]) {
        peaks++;
      }
    }

    // Rumination typically has 3-6 peaks in a 10-second window
    return peaks >= 3 && peaks <= 6;
  }

  /// Detect head shaking pattern
  static bool _detectHeadShaking(GyroData gyro, double gyroMagnitude) {
    // Head shaking creates high rotational movement with specific patterns
    return gyroMagnitude > 4.0 &&
        (gyro.x.abs() > 3.0 || gyro.y.abs() > 3.0) &&
        gyro.z.abs() < 2.0; // Mostly horizontal movement
  }

  /// Detect walking pattern
  static bool _detectWalkingPattern(double accelMagnitude, double gyroMagnitude,
      List<MovementData> recentData) {
    // Walking has moderate acceleration with coordinated rotation
    if (accelMagnitude < 2.0 || accelMagnitude > 6.0) return false;
    if (gyroMagnitude < 0.5 || gyroMagnitude > 4.0) return false;

    // Check for regularity in recent movement
    if (recentData.length < 5) return false;

    final recentStates = recentData.takeLast(5);
    final walkingCount = recentStates
        .where((d) =>
            d.state == MovementState.walking ||
            d.state == MovementState.standing)
        .length;

    return walkingCount >= 3; // Consistent movement pattern
  }

  /// Enhanced movement state analysis incorporating cattle-specific behaviors
  static MovementState enhancedMovementAnalysis(
    AccelData accel,
    GyroData gyro,
    double accelMagnitude,
    double gyroMagnitude,
    List<MovementData> recentData,
  ) {
    // First check for specific behaviors
    final specificBehavior = detectSpecificBehavior(
        accel, gyro, accelMagnitude, gyroMagnitude, recentData);

    if (specificBehavior != MovementState.idle) {
      return specificBehavior;
    }

    // Fall back to standard analysis
    return analyzeMovementState(accelMagnitude, gyroMagnitude, accel);
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    if (count <= 0) return <T>[];
    if (count >= length) return this;
    return skip(length - count);
  }
}
