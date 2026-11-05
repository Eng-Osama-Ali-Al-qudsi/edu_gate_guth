import 'package:flutter_test/flutter_test.dart';
import 'package:edu_gate_guth/controllers/auth_controller.dart';
import 'package:edu_gate_guth/models/login_request.dart';
import 'package:edu_gate_guth/models/password_reset_request.dart';
import 'package:edu_gate_guth/models/register_request.dart';
import 'package:edu_gate_guth/repositories/auth_repository_impl.dart';
import 'package:edu_gate_guth/services/remembered_identifier_store.dart';

void main() {
  late AuthController controller;
  late MemoryRememberedIdentifierStore identifierStore;

  setUp(() {
    identifierStore = MemoryRememberedIdentifierStore();
    controller = AuthController(
      repository: AuthRepositoryImpl(requestDelay: const Duration(milliseconds: 5)),
      rememberedIdentifierStore: identifierStore,
    );
  });

  tearDown(() => controller.dispose());

  test('exposes loading state and registers a student', () async {
    final future = controller.register(
      request: const RegisterRequest(
        fullName: 'Ali Mohammed',
        academicId: '202612345',
        email: 'ali@example.edu',
        password: 'Student123',
      ),
    );

    expect(controller.isLoading, isTrue);
    final result = await future;
    expect(result.isSuccess, isTrue);
    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('updates authentication state after successful login', () async {
    await controller.register(
      request: const RegisterRequest(
        fullName: 'Ali Mohammed',
        academicId: '202612345',
        email: 'ali@example.edu',
        password: 'Student123',
      ),
    );

    final result = await controller.login(
      request: const LoginRequest(identifier: '202612345', password: 'Student123'),
    );

    expect(result.isSuccess, isTrue);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.currentUser?.fullName, 'Ali Mohammed');
    controller.logout();
    expect(controller.isAuthenticated, isFalse);
    expect(controller.currentUser, isNull);
  });

  test('stores Remember Me selection and reports authentication failures', () async {
    controller.setRememberMe(true);
    expect(controller.rememberMe, isTrue);

    final result = await controller.login(
      request: const LoginRequest(identifier: '202612345', password: 'incorrect'),
    );

    expect(result.isSuccess, isFalse);
    expect(controller.errorMessage, isNotNull);
    expect(controller.isAuthenticated, isFalse);
  });


  test('restores only the remembered identifier during initialization', () async {
    await identifierStore.saveIdentifier('202612345');

    await controller.initialize();

    expect(controller.rememberMe, isTrue);
    expect(controller.rememberedIdentifier, '202612345');
    expect(controller.isAuthenticated, isFalse);
  });

  test('saves the identifier but never the password when Remember Me is enabled', () async {
    await controller.register(
      request: const RegisterRequest(
        fullName: 'Ali Mohammed',
        academicId: '202612345',
        email: 'ali@example.edu',
        password: 'Student123',
      ),
    );
    controller.setRememberMe(true);

    final result = await controller.login(
      request: const LoginRequest(identifier: '202612345', password: 'Student123'),
    );

    expect(result.isSuccess, isTrue);
    expect(await identifierStore.readIdentifier(), '202612345');
    expect(controller.isAuthenticated, isTrue);
  });

  test('clears the remembered identifier when Remember Me is disabled', () async {
    await identifierStore.saveIdentifier('202612345');
    await controller.initialize();

    controller.setRememberMe(false);
    await Future<void>.delayed(Duration.zero);

    expect(await identifierStore.readIdentifier(), isNull);
    expect(controller.rememberedIdentifier, isNull);
    expect(controller.isAuthenticated, isFalse);
  });

  test('binds OTP reset to the identifier that requested the code', () async {
    await controller.register(
      request: const RegisterRequest(
        fullName: 'Ali Mohammed',
        academicId: '202612345',
        email: 'ali@example.edu',
        password: 'Student123',
      ),
    );

    final codeResult = await controller.sendPasswordResetCode(
      identifier: 'ali@example.edu',
    );
    expect(codeResult.isSuccess, isTrue);
    expect(controller.pendingResetIdentifier, 'ali@example.edu');

    final mismatchedIdentifier = await controller.resetPassword(
      request: const PasswordResetRequest(
        identifier: '202612345',
        otp: '123456',
        newPassword: 'Updated123',
      ),
    );
    expect(mismatchedIdentifier.isSuccess, isFalse);

    final resetResult = await controller.resetPassword(
      request: const PasswordResetRequest(
        identifier: 'ali@example.edu',
        otp: '123456',
        newPassword: 'Updated123',
      ),
    );
    expect(resetResult.isSuccess, isTrue);
    expect(controller.pendingResetIdentifier, isNull);
  });

  test('clears an earlier authenticated state after a failed login', () async {
    await controller.register(
      request: const RegisterRequest(
        fullName: 'Ali Mohammed',
        academicId: '202612345',
        email: 'ali@example.edu',
        password: 'Student123',
      ),
    );
    final firstLogin = await controller.login(
      request: const LoginRequest(identifier: '202612345', password: 'Student123'),
    );
    expect(firstLogin.isSuccess, isTrue);
    expect(controller.isAuthenticated, isTrue);

    final failedLogin = await controller.login(
      request: const LoginRequest(identifier: '202612345', password: 'Wrong123'),
    );
    expect(failedLogin.isSuccess, isFalse);
    expect(controller.isAuthenticated, isFalse);
    expect(controller.currentUser, isNull);
  });
}
