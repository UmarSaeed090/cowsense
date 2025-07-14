import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../userCredential/VeteranProfileModel.dart';

class VeteranProfileService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static DocumentReference get _profileRef {
    if (currentUserId == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No user is currently signed in.',
      );
    }
    return _firestore.collection('vet_profiles').doc(currentUserId);
  }

  static Future<VeteranProfile?> fetchProfile() async {
    final snapshot = await _profileRef.get();
    if (snapshot.exists) {
      return VeteranProfile.fromFirestore(snapshot);
    }
    return null;
  }

  static Future<void> saveProfile(VeteranProfile profile) async {
    await _profileRef.set(profile.toFirestoreMap(), SetOptions(merge: true));
  }

  static Future<bool> profileExists() async {
    final snapshot = await _profileRef.get();
    return snapshot.exists;
  }

  static Future<void> deleteProfile() async {
    await _profileRef.delete();
  }
}
