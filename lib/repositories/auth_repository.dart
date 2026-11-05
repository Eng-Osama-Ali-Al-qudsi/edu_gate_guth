import '../models/auth_result.dart';
import '../models/login_request.dart';
import '../models/password_reset_request.dart';
import '../models/register_request.dart';

abstract class AuthRepository {
  Future<AuthResult> register(RegisterRequest request);

  Future<AuthResult> login(LoginRequest request);

  Future<AuthResult> sendPasswordResetCode(String identifier);

  Future<AuthResult> resetPassword(PasswordResetRequest request);
}
