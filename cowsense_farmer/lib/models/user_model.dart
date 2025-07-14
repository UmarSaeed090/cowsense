class UserModel {
  final String uid;
  final String? displayName;
  final String? photoUrl;
  final String? email;
  final String? phoneNumber;
  final List<String>? cows;
  final String? bio;
  final String? city;

  UserModel({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.email,
    this.phoneNumber,
    this.cows,
    this.bio,
    this.city,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      displayName: data['display_name'] ?? data['name'] ?? '',
      photoUrl: data['photo_url'],
      email: data['email'],
      phoneNumber: data['phone_number'],
      bio: data['bio'],
      city: data['city'],
      cows:
          data['cows'] != null ? List<String>.from(data['cows'] as List) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'display_name': displayName,
      'photo_url': photoUrl,
      'email': email,
      'phone_number': phoneNumber,
      'cows': cows,
      'bio': bio,
      'city': city,
    };
  }
}
