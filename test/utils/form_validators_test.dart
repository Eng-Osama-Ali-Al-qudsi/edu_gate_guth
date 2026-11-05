import 'package:flutter_test/flutter_test.dart';
import 'package:edu_gate_guth/utils/form_validators.dart';

void main() {
  group('FormValidators.validateIdentifier', () {
    test('rejects empty and short identifiers', () {
      expect(FormValidators.validateIdentifier(''), isNotNull);
      expect(FormValidators.validateIdentifier('abc'), isNotNull);
    });

    test('accepts academic identifiers and valid email addresses', () {
      expect(FormValidators.validateIdentifier('202612345'), isNull);
      expect(FormValidators.validateIdentifier('student@example.edu'), isNull);
    });

    test('rejects malformed identifiers', () {
      expect(FormValidators.validateIdentifier('bad identifier'), isNotNull);
      expect(FormValidators.validateIdentifier('student@invalid'), isNotNull);
    });
  });

  group('Registration validators', () {
    test('validates full name', () {
      expect(FormValidators.validateFullName(''), isNotNull);
      expect(FormValidators.validateFullName('Ali'), isNull);
      expect(FormValidators.validateFullName('  علي محمد  '), isNull);
    });

    test('accepts only 9 or 10 numeric academic ID digits', () {
      expect(FormValidators.validateAcademicId('123456789'), isNull);
      expect(FormValidators.validateAcademicId('1234567890'), isNull);
      expect(FormValidators.validateAcademicId('12345678'), isNotNull);
      expect(FormValidators.validateAcademicId('12345678A'), isNotNull);
    });

    test('validates email without imposing a university domain', () {
      expect(FormValidators.validateEmail('student@gmail.com'), isNull);
      expect(FormValidators.validateEmail('student@university.edu'), isNull);
      expect(FormValidators.validateEmail('student@'), isNotNull);
    });

    test('validates login password minimum length', () {
      expect(FormValidators.validateLoginPassword('12345'), isNotNull);
      expect(FormValidators.validateLoginPassword('123456'), isNull);
    });

    test('requires strong password length, number, and uppercase letter', () {
      expect(FormValidators.validateStrongPassword('Abc12345'), isNull);
      expect(FormValidators.validateStrongPassword('Abc1234'), isNotNull);
      expect(FormValidators.validateStrongPassword('abcdefgh'), isNotNull);
      expect(FormValidators.validateStrongPassword('abcdefg1'), isNotNull);
    });

    test('checks password confirmation exactly', () {
      expect(
        FormValidators.validateConfirmPassword('Abc12345', originalPassword: 'Abc12345'),
        isNull,
      );
      expect(
        FormValidators.validateConfirmPassword('abc12345', originalPassword: 'Abc12345'),
        isNotNull,
      );
      expect(
        FormValidators.validateConfirmPassword('', originalPassword: 'Abc12345'),
        isNotNull,
      );
    });
  });

  group('FormValidators.validateOtp', () {
    test('accepts exactly six digits', () {
      expect(FormValidators.validateOtp('123456'), isNull);
    });

    test('rejects empty, short, long, or nonnumeric codes', () {
      expect(FormValidators.validateOtp(''), isNotNull);
      expect(FormValidators.validateOtp('12345'), isNotNull);
      expect(FormValidators.validateOtp('1234567'), isNotNull);
      expect(FormValidators.validateOtp('12A456'), isNotNull);
    });
  });
}
