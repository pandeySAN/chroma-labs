class UserEntity {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String authProvider;
  final String role;
  final String? profilePicture;
  final bool isDoctor;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.authProvider,
    this.role = 'patient',
    this.profilePicture,
    this.isDoctor = false,
  });
}
