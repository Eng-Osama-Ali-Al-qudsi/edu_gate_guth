import 'package:flutter_test/flutter_test.dart';
import 'package:edu_gate_guth/models/login_request.dart';
import 'package:edu_gate_guth/models/password_reset_request.dart';
import 'package:edu_gate_guth/models/register_request.dart';
import 'package:edu_gate_guth/repositories/auth_repository_impl.dart';

void main() {
  late AuthRepositoryImpl repository;
  const student = RegisterRequest(
    fullName: 'Ali Mohammed',
    academicId: '202612345',
    email: 'ali.student@example.edu',
    password: 'Student123',
  );

  setUp(() {
    repository = AuthRepositoryImpl(requestDelay: Duration.zero);
  });

  test('registers a new student', () async {
    final result = await repository.register(student);
    expect(result.isSuccess, isTrue);
    expect(result.user?.academicId, student.academicId);
    expect(repository.registeredStudentCount, 1);
  });

  test('rejects duplicate academic IDs', () async {
    await repository.register(student);
    final result = await repository.register(
      const RegisterRequest(
        fullName: 'Another Student',
        academicId: '202612345',
        email: 'another@example.edu',
        password: 'Another123',
      ),
    );
    expect(result.isSuccess, isFalse);
    expect(result.message, contains('الرقم الأكاديمي'));
    expect(repository.registeredStudentCount, 1);
  });

  test('rejects duplicate email addresses regardless of case', () async {
    await repository.register(student);
    final result = await repository.register(
      const RegisterRequest(
        fullName: 'Another Student',
        academicId: '202612346',
        email: 'ALI.STUDENT@example.edu',
        password: 'Another123',
      ),
    );
    expect(result.isSuccess, isFalse);
    expect(result.message, contains('البريد الإلكتروني'));
  });

  test('logs in using academic ID or email', () async {
    await repository.register(student);

    final byId = await repository.login(
      const LoginRequest(identifier: '202612345', password: 'Student123'),
    );
    final byEmail = await repository.login(
      const LoginRequest(identifier: 'ALI.STUDENT@example.edu', password: 'Student123'),
    );

    expect(byId.isSuccess, isTrue);
    expect(byEmail.isSuccess, isTrue);
    expect(byEmail.user?.fullName, 'Ali Mohammed');
  });

  test('rejects incorrect credentials and unknown accounts', () async {
    await repository.register(student);

    final wrongPassword = await repository.login(
      const LoginRequest(identifier: '202612345', password: 'Wrong123'),
    );
    final unknownUser = await repository.login(
      const LoginRequest(identifier: '999999999', password: 'Student123'),
    );

    expect(wrongPassword.isSuccess, isFalse);
    expect(unknownUser.isSuccess, isFalse);
  });

  test('rejects recovery for an account that does not exist', () async {
    final result = await repository.sendPasswordResetCode('unknown@example.edu');
    expect(result.isSuccess, isFalse);
  });

  test('sends demo code, rejects wrong OTP, and updates password with correct OTP', () async {
    await repository.register(student);

    final codeResult = await repository.sendPasswordResetCode(student.email);
    expect(codeResult.isSuccess, isTrue);
    expect(codeResult.message, contains('123456'));
    expect(codeResult.message, contains('لم تُرسل رسالة فعلية'));

    final wrongOtp = await repository.resetPassword(
      const PasswordResetRequest(
        identifier: 'ali.student@example.edu',
        otp: '000000',
        newPassword: 'Updated123',
      ),
    );
    expect(wrongOtp.isSuccess, isFalse);

    final resetResult = await repository.resetPassword(
      const PasswordResetRequest(
        identifier: 'ali.student@example.edu',
        otp: '123456',
        newPassword: 'Updated123',
      ),
    );
    expect(resetResult.isSuccess, isTrue);

    final oldPassword = await repository.login(
      const LoginRequest(identifier: '202612345', password: 'Student123'),
    );
    final newPassword = await repository.login(
      const LoginRequest(identifier: '202612345', password: 'Updated123'),
    );
    expect(oldPassword.isSuccess, isFalse);
    expect(newPassword.isSuccess, isTrue);
  });

  test('requires requesting a code before password reset', () async {
    await repository.register(student);
    final result = await repository.resetPassword(
      const PasswordResetRequest(
        identifier: '202612345',
        otp: '123456',
        newPassword: 'Updated123',
      ),
    );
    expect(result.isSuccess, isFalse);
  });
}
