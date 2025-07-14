import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'sensor_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  User? _user;
  UserModel? _userProfile;
  bool _loading = true;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> initialize() async {
    if (_loading) {
      // If still loading, wait for the first auth state change
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _loading;
  bool get isAuthenticated => _user != null;

  Future<void> _onAuthStateChanged(User? user) async {
    try {
      _user = user;
      if (_user != null) {
        await _fetchUserProfile();
      } else {
        _userProfile = null;
      }
    } catch (e) {
      debugPrint('Error in auth state change: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      _loading = true;
      notifyListeners();
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      final userData = {
        'uid': userCredential.user?.uid,
        'name': name,
        'email': email,
        'created_at': FieldValue.serverTimestamp(),
        'cows': [],
      };

      await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .set(userData);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _loading = true;
      notifyListeners();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _loading = false;
        notifyListeners();
        throw Exception('Google sign-in aborted');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      // If new user, create profile in Firestore
      final userDoc =
          await _firestore.collection('users').doc(userCred.user!.uid).get();
      if (!userDoc.exists) {
        final userData = {
          'uid': userCred.user!.uid,
          'name': userCred.user!.displayName ?? '',
          'email': userCred.user!.email ?? '',
          'photo_url': userCred.user!.photoURL,
          'phone_number': userCred.user!.phoneNumber,
          'created_at': FieldValue.serverTimestamp(),
          'google': true,
        };
        await _firestore
            .collection('users')
            .doc(userCred.user!.uid)
            .set(userData);
      }
      await _fetchUserProfile();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _userProfile = null;
    notifyListeners();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (userDoc.exists) {
        _userProfile = UserModel.fromFirestore(userDoc.data()!);
        // Update sensor subscriptions with user's cow IDs
        final cowIds = List<String>.from(userDoc.data()!['cows'] ?? []);
        if (navigatorKey.currentContext != null) {
          Provider.of<SensorProvider>(navigatorKey.currentContext!,
                  listen: false)
              .updateSubscriptions(cowIds);
        }
      } else {
        debugPrint('User document does not exist in Firestore');
      }
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateProfile({
    required String displayName,
    String? bio,
    String? city,
    String? phoneNumber,
    File? profileImage,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      String? photoURL;
      if (profileImage != null) {
        final ref = _storage.ref().child('profile_images/${user.uid}');
        await ref.putFile(profileImage);
        photoURL = await ref.getDownloadURL();
      }

      // Update Firebase Auth profile
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore user document
      final userData = {
        'display_name': displayName,
        'bio': bio,
        'city': city,
        'phone_number': phoneNumber,
        if (photoURL != null) 'photo_url': photoURL,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).update(userData);

      // Update local user profile
      _userProfile = UserModel(
        uid: user.uid,
        displayName: displayName,
        photoUrl: photoURL ?? _userProfile?.photoUrl,
        email: _userProfile?.email,
        phoneNumber: phoneNumber ?? _userProfile?.phoneNumber,
        bio: bio ?? _userProfile?.bio,
        city: city ?? _userProfile?.city,
      );

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Reauthenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
