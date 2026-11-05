/// Represents a student account stored by the demonstration repository.
///
/// The password is kept in memory only for this academic demonstration.
/// A production system must never store plaintext passwords in this manner.
class UserModel {
  const UserModel({
    required this.fullName,
    required this.academicId,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String academicId;
  final String email;
  final String password;

  UserModel copyWith({String? password}) {
    return UserModel(
      fullName: fullName,
      academicId: academicId,
      email: email,
      password: password ?? this.password,
    );
  }
}
