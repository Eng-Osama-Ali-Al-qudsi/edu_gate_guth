import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_result.dart';
import '../models/login_request.dart';
import '../models/password_reset_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/remembered_identifier_store.dart';

/// Coordinates authentication operations and exposes UI-independent state.
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    RememberedIdentifierStore? rememberedIdentifierStore,
  })  : _repository = repository,
        _rememberedIdentifierStore =
            rememberedIdentifierStore ?? MemoryRememberedIdentifierStore();

  final AuthRepository _repository;
  final RememberedIdentifierStore _rememberedIdentifierStore;

  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _rememberMe = false;
  UserModel? _currentUser;
  String? _errorMessage;
  String? _pendingResetIdentifier;
  String? _rememberedIdentifier;
  AuthResult? _lastResult;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get rememberMe => _rememberMe;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get pendingResetIdentifier => _pendingResetIdentifier;
  String? get rememberedIdentifier => _rememberedIdentifier;
  AuthResult? get lastResult => _lastResult;

  /// Restores the remembered identifier on startup. This does not restore an
  /// authenticated session because student accounts live only in memory.
  Future<void> initialize() async {
    try {
      final stored = await _rememberedIdentifierStore.readIdentifier();
      final normalized = stored?.trim();
      _rememberedIdentifier =
          normalized == null || normalized.isEmpty ? null : normalized;
      _rememberMe = _rememberedIdentifier != null;
    } catch (_) {
      // Storage failure must not prevent the demo application from opening.
      _rememberedIdentifier = null;
      _rememberMe = false;
    }
    notifyListeners();
  }

  void setRememberMe(bool value) {
    if (_rememberMe == value) return;
    _rememberMe = value;
    if (!value) {
      _rememberedIdentifier = null;
      unawaited(_clearRememberedIdentifier());
    }
    notifyListeners();
  }

  Future<void> _clearRememberedIdentifier() async {
    try {
      await _rememberedIdentifierStore.clearIdentifier();
    } catch (_) {
      // A local preference failure must not block sign-out or form editing.
    }
  }

  Future<AuthResult> login({required LoginRequest request}) {
    return _execute(() async {
      final result = await _repository.login(request);
      if (result.isSuccess) {
        _currentUser = result.user;
        _isAuthenticated = true;
        if (_rememberMe) {
          _rememberedIdentifier = request.identifier.trim();
          try {
            await _rememberedIdentifierStore.saveIdentifier(
              _rememberedIdentifier!,
            );
          } catch (_) {
            // Authentication remains successful; only the convenience feature
            // is unavailable if the platform preference cannot be written.
          }
        } else {
          _rememberedIdentifier = null;
          await _clearRememberedIdentifier();
        }
      } else {
        _currentUser = null;
        _isAuthenticated = false;
      }
      return result;
    });
  }

  Future<AuthResult> register({required RegisterRequest request}) {
    return _execute(() => _repository.register(request));
  }

  Future<AuthResult> sendPasswordResetCode({required String identifier}) {
    return _execute(() async {
      final result = await _repository.sendPasswordResetCode(identifier);
      if (result.isSuccess) _pendingResetIdentifier = identifier.trim();
      return result;
    });
  }

  Future<AuthResult> resetPassword({required PasswordResetRequest request}) {
    return _execute(() async {
      if (_pendingResetIdentifier == null ||
          _pendingResetIdentifier!.toLowerCase() != request.identifier.trim().toLowerCase()) {
        return AuthResult.failure('يرجى بدء استعادة كلمة المرور من جديد.');
      }
      final result = await _repository.resetPassword(request);
      if (result.isSuccess) _pendingResetIdentifier = null;
      return result;
    });
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<AuthResult> _execute(Future<AuthResult> Function() operation) async {
    if (_isLoading) {
      return AuthResult.failure('هناك عملية قيد التنفيذ، يرجى الانتظار.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await operation();
      _lastResult = result;
      _errorMessage = result.isSuccess ? null : result.message;
      return result;
    } catch (_) {
      const message = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
      final result = AuthResult.failure(message);
      _lastResult = result;
      _errorMessage = message;
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
