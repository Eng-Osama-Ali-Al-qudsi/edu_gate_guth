class FormValidators {
  FormValidators._();

  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+$",
  );
  static final RegExp _academicIdentifierPattern =
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{4,}$');
  static final RegExp _academicIdPattern = RegExp(r'^[0-9]{9,10}$');
  static final RegExp _numberPattern = RegExp(r'[0-9]');
  static final RegExp _uppercasePattern = RegExp(r'[A-Z]');
  static final RegExp _otpPattern = RegExp(r'^[0-9]{6}$');

  static String? validateIdentifier(String? value) {
    final identifier = value?.trim() ?? '';
    if (identifier.isEmpty) return 'يرجى إدخال الرقم الأكاديمي أو البريد الإلكتروني.';
    if (identifier.length < 5) return 'يجب ألا يقل المعرّف عن 5 أحرف.';
    if (_emailPattern.hasMatch(identifier) ||
        _academicIdentifierPattern.hasMatch(identifier)) {
      return null;
    }
    return 'أدخل بريداً إلكترونياً صحيحاً أو معرّفاً أكاديمياً صالحاً.';
  }

  static String? validateFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'يرجى إدخال الاسم الكامل.';
    if (name.length < 3) return 'يجب ألا يقل الاسم عن 3 أحرف.';
    return null;
  }

  static String? validateAcademicId(String? value) {
    final academicId = value?.trim() ?? '';
    if (academicId.isEmpty) return 'يرجى إدخال الرقم الأكاديمي.';
    if (!_academicIdPattern.hasMatch(academicId)) {
      return 'يجب أن يتكون الرقم الأكاديمي من 9 أو 10 أرقام.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'يرجى إدخال البريد الإلكتروني الجامعي.';
    if (!_emailPattern.hasMatch(email)) return 'صيغة البريد الإلكتروني غير صحيحة.';
    return null;
  }

  static String? validateLoginPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'يرجى إدخال كلمة المرور.';
    if (password.length < 6) return 'يجب ألا تقل كلمة المرور عن 6 أحرف.';
    return null;
  }

  static String? validateStrongPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'يرجى إدخال كلمة المرور.';
    if (password.length < 8) return 'يجب ألا تقل كلمة المرور عن 8 أحرف.';
    if (!_numberPattern.hasMatch(password)) {
      return 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل.';
    }
    if (!_uppercasePattern.hasMatch(password)) {
      return 'يجب أن تحتوي كلمة المرور على حرف إنجليزي كبير واحد على الأقل.';
    }
    return null;
  }

  static String? validateConfirmPassword(
    String? value, {
    required String originalPassword,
  }) {
    if (value == null || value.isEmpty) return 'يرجى تأكيد كلمة المرور.';
    if (value != originalPassword) return 'كلمتا المرور غير متطابقتين.';
    return null;
  }

  static String? validateOtp(String? value) {
    final otp = value?.trim() ?? '';
    if (otp.isEmpty) return 'يرجى إدخال رمز التحقق.';
    if (!_otpPattern.hasMatch(otp)) return 'يجب أن يتكون رمز التحقق من 6 أرقام.';
    return null;
  }
}
