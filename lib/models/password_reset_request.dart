class PasswordResetRequest {
  const PasswordResetRequest({
    required this.identifier,
    required this.otp,
    required this.newPassword,
  });

  final String identifier;
  final String otp;
  final String newPassword;
}
