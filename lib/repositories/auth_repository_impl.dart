import '../models/auth_result.dart';
import '../models/login_request.dart';
import '../models/password_reset_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'auth_repository.dart';

/// In-memory demonstration repository with a simulated network delay.
///
/// Data is lost when the application process is restarted. Passwords are kept
/// in memory as plain strings only to keep this classroom example dependency-
/// free; this implementation is not suitable for real authentication.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    this.requestDelay = AppConstants.simulatedNetworkDelay,
  });

  final Duration requestDelay;
  final Map<String, UserModel> _studentsByAcademicId = {};
  final Map<String, String> _resetCodesByIdentifier = {};

  int get registeredStudentCount => _studentsByAcademicId.length;

  String _normalize(String value) => value.trim().toLowerCase();

  UserModel? _findStudent(String identifier) {
    final normalized = _normalize(identifier);
    for (final student in _studentsByAcademicId.values) {
      if (_normalize(student.academicId) == normalized ||
          _normalize(student.email) == normalized) {
        return student;
      }
    }
    return null;
  }

  @override
  Future<AuthResult> register(RegisterRequest request) async {
    await Future<void>.delayed(requestDelay);

    final academicId = request.academicId.trim();
    final email = request.email.trim();

    if (_studentsByAcademicId.containsKey(academicId)) {
      return AuthResult.failure('هذا الرقم الأكاديمي مسجل مسبقاً.');
    }
    if (_findStudent(email) != null) {
      return AuthResult.failure('هذا البريد الإلكتروني مسجل مسبقاً.');
    }

    final student = UserModel(
      fullName: request.fullName.trim(),
      academicId: academicId,
      email: email,
      password: request.password,
    );
    _studentsByAcademicId[academicId] = student;
    return AuthResult.success('تم إنشاء الحساب بنجاح.', user: student);
  }

  @override
  Future<AuthResult> login(LoginRequest request) async {
    await Future<void>.delayed(requestDelay);

    final student = _findStudent(request.identifier);
    if (student == null || student.password != request.password) {
      return AuthResult.failure('بيانات الدخول غير صحيحة. تحقق من المعرّف وكلمة المرور.');
    }
    return AuthResult.success('تم تسجيل الدخول بنجاح.', user: student);
  }

  @override
  Future<AuthResult> sendPasswordResetCode(String identifier) async {
    await Future<void>.delayed(requestDelay);

    final student = _findStudent(identifier);
    if (student == null) {
      return AuthResult.failure('لا يوجد حساب مرتبط بهذا الرقم الأكاديمي أو البريد الإلكتروني.');
    }

    final normalizedIdentifier = _normalize(identifier);
    _resetCodesByIdentifier[normalizedIdentifier] = AppConstants.demoOtp;
    return AuthResult.success(
      'تم إنشاء رمز تحقق تجريبي. لم تُرسل رسالة فعلية. رمز الاختبار هو ${AppConstants.demoOtp}.',
      user: student,
    );
  }

  @override
  Future<AuthResult> resetPassword(PasswordResetRequest request) async {
    await Future<void>.delayed(requestDelay);

    final normalizedIdentifier = _normalize(request.identifier);
    final expectedOtp = _resetCodesByIdentifier[normalizedIdentifier];
    if (expectedOtp == null) {
      return AuthResult.failure('يرجى طلب رمز تحقق جديد أولاً.');
    }
    if (request.otp != expectedOtp) {
      return AuthResult.failure('رمز التحقق غير صحيح.');
    }

    final student = _findStudent(request.identifier);
    if (student == null) {
      return AuthResult.failure('تعذر العثور على الحساب المطلوب.');
    }

    final updatedStudent = student.copyWith(password: request.newPassword);
    _studentsByAcademicId[student.academicId] = updatedStudent;
    _resetCodesByIdentifier.remove(normalizedIdentifier);
    return AuthResult.success('تم تحديث كلمة المرور بنجاح.', user: updatedStudent);
  }
}
