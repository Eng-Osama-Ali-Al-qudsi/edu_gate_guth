import 'user_model.dart';

class AuthResult {
  const AuthResult({
    required this.isSuccess,
    required this.message,
    this.user,
  });

  final bool isSuccess;
  final String message;
  final UserModel? user;

  factory AuthResult.success(String message, {UserModel? user}) {
    return AuthResult(isSuccess: true, message: message, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(isSuccess: false, message: message);
  }
}
