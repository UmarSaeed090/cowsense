import 'package:cloud_firestore/cloud_firestore.dart';

class VeteranProfile {
  final String? avatar;
  final String name;
  final String phone;
  final DateTime dob;
  final String city;
  final String license;
  final String cnicPath;
  final String licenseStatus;
  final bool completedRegistration;

  VeteranProfile({
    required this.name,
    required this.phone,
    required this.dob,
    required this.city,
    required this.license,
    required this.cnicPath,
    required this.licenseStatus,
    required this.completedRegistration,
    this.avatar,
  });

  factory VeteranProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VeteranProfile(
      avatar: data['avatar'],  // Can be null, no default set here
      name: data['name'] ?? '',  // Default to empty string if missing
      phone: data['phone'] ?? '',  // Default to empty string if missing
      dob: data['dob'] is Timestamp
          ? (data['dob'] as Timestamp).toDate()
          : DateTime.tryParse(data['dob'] ?? '') ?? DateTime.now(),  // Ensure valid date, fallback to current date
      city: data['city'] ?? '',  // Default to empty string if missing
      license: data['license'] ?? '',  // Default to empty string if missing
      cnicPath: data['cnicPath'] ?? '',  // Default to empty string if missing
      licenseStatus: data['licenseStatus'] ?? 'not-verified',  // Default to 'not-verified' if missing
      completedRegistration: data['completedRegistration'] ?? false,  // Default to false if missing
    );
  }

  VeteranProfile copyWith({
    String? name,
    String? phone,
    DateTime? dob,
    String? city,
    String? license,
    String? cnicPath,
    String? licenseStatus,
    bool? completedRegistration,
    String? avatar,
  }) {
    return VeteranProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      city: city ?? this.city,
      license: license ?? this.license,
      cnicPath: cnicPath ?? this.cnicPath,
      licenseStatus: licenseStatus ?? this.licenseStatus,
      completedRegistration: completedRegistration ?? this.completedRegistration,
      avatar: avatar ?? this.avatar,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'avatar': avatar,
      'name': name,
      'phone': phone,
      'dob': dob.toIso8601String(),
      'city': city,
      'license': license,
      'cnicPath': cnicPath,
      'licenseStatus': licenseStatus,
      'completedRegistration': completedRegistration,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      ...toMap(),
      'dob': Timestamp.fromDate(dob),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
