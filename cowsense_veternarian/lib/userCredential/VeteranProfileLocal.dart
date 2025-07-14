import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'VeteranProfileModel.dart';

class VeteranProfileLocal {
  static const _storageKey = 'veteran_profile';

  static Future<void> saveToLocal(VeteranProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(profile.toMap());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<VeteranProfile?> getFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json == null) return null;
    final map = jsonDecode(json);
    return VeteranProfile(
      avatar: map['avatar'],
      name: map['name'],
      phone: map['phone'],
      dob: DateTime.parse(map['dob']),
      city: map['city'],
      license: map['license'],
      cnicPath: map['cnicPath'],
      licenseStatus: map['licenseStatus'],
      completedRegistration: map['completedRegistration'],
    );
  }

  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
