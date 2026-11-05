import 'package:flutter/services.dart';

/// Stores only the last successful account identifier, never a password or
/// authentication token. The default implementation is useful for tests.
abstract class RememberedIdentifierStore {
  Future<String?> readIdentifier();
  Future<void> saveIdentifier(String identifier);
  Future<void> clearIdentifier();
}

class MemoryRememberedIdentifierStore implements RememberedIdentifierStore {
  String? _identifier;

  @override
  Future<String?> readIdentifier() async => _identifier;

  @override
  Future<void> saveIdentifier(String identifier) async {
    _identifier = identifier;
  }

  @override
  Future<void> clearIdentifier() async {
    _identifier = null;
  }
}

/// Uses the host platform's private preferences through a built-in
/// MethodChannel; no third-party Flutter plugin is required.
class MethodChannelRememberedIdentifierStore implements RememberedIdentifierStore {
  const MethodChannelRememberedIdentifierStore();

  static const MethodChannel _channel =
      MethodChannel('edu_gate_guth/remembered_identifier');

  @override
  Future<String?> readIdentifier() {
    return _channel.invokeMethod<String>('readIdentifier');
  }

  @override
  Future<void> saveIdentifier(String identifier) async {
    await _channel.invokeMethod<void>(
      'saveIdentifier',
      <String, Object>{'identifier': identifier},
    );
  }

  @override
  Future<void> clearIdentifier() async {
    await _channel.invokeMethod<void>('clearIdentifier');
  }
}
