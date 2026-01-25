/// User model representing the authenticated user
class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final String authProvider;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    required this.authProvider,
  });

  /// Full name computed property
  String get fullName => '$firstName $lastName'.trim();

  /// Check if user has profile picture
  bool get hasProfilePicture => 
      profilePicture != null && profilePicture!.isNotEmpty;

  /// Create User from JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profilePicture: json['profile_picture'] as String?,
      authProvider: json['auth_provider'] as String? ?? 'email',
    );
  }

  /// Convert User to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'profile_picture': profilePicture,
      'auth_provider': authProvider,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
