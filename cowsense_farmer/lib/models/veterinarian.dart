class Veterinarian {
  final String id;
  final String name;
  final String specialization;
  final String experience;
  final String education;
  final String? imageUrl;
  final String phoneNumber;
  final String email;
  final double rating;
  final int totalReviews;
  final String? bio;
  final List<String>? languages;
  final Map<String, dynamic>? availability;
  final List<String>? appointments;

  Veterinarian({
    required this.id,
    required this.name,
    required this.specialization,
    required this.experience,
    required this.education,
    this.imageUrl,
    required this.phoneNumber,
    required this.email,
    required this.rating,
    required this.totalReviews,
    this.bio,
    this.languages,
    this.availability,
    this.appointments,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialization': specialization,
      'experience': experience,
      'education': education,
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
      'email': email,
      'rating': rating,
      'totalReviews': totalReviews,
      'bio': bio,
      'languages': languages,
      'availability': availability,
      'appointments': appointments,
    };
  }

  factory Veterinarian.fromMap(Map<String, dynamic> map, String id) {
    return Veterinarian(
      id: id,
      name: map['name'] ?? '',
      specialization: map['specialization'] ?? '',
      experience: map['experience'] ?? '',
      education: map['education'] ?? '',
      imageUrl: map['imageUrl'],
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews']?.toInt() ?? 0,
      bio: map['bio'],
      languages: List<String>.from(map['languages'] ?? []),
      availability: map['availability'],
      appointments: List<String>.from(map['appointments'] ?? []),
    );
  }
}
