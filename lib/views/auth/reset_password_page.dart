import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/auth_controller.dart';
import '../../models/password_reset_request.dart';
import '../../utils/app_constants.dart';
import '../../utils/form_validators.dart';
import 'widgets/auth_page_shell.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/primary_button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.controller,
    required this.identifier,
  });

  final AuthController controller;
  final String identifier;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final result = await widget.controller.resetPassword(
      request: PasswordResetRequest(
        identifier: widget.identifier,
        otp: _otpController.text.trim(),
        newPassword: _passwordController.text,
      ),
    );
    if (!mounted) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppConstants.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: AppConstants.success, size: 42),
        title: const Text('تم تحديث كلمة المرور'),
        content: const Text('أصبحت كلمة المرور الجديدة فعّالة. يمكنك الآن تسجيل الدخول بها.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('العودة لتسجيل الدخول'),
          ),
        ],
      ),
    );
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return AuthPageShell(
          showBackButton: true,
          title: 'تعيين كلمة مرور جديدة',
          subtitle: 'أدخل رمز التحقق ثم اختر كلمة مرور قوية لحسابك.',
          icon: Icons.password_rounded,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'الحساب: ${widget.identifier}',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: AppConstants.primary,
                      fontWeight: FontWeight.w600,
                      fontVariations: [FontVariation('wght', 600)],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  controller: _otpController,
                  label: 'رمز التحقق',
                  hint: 'أدخل الرمز المكوّن من 6 أرقام',
                  icon: Icons.verified_user_outlined,
                  validator: FormValidators.validateOtp,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور الجديدة',
                  hint: '8 أحرف على الأقل، مع رقم وحرف كبير',
                  icon: Icons.lock_outline_rounded,
                  validator: FormValidators.validateStrongPassword,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    tooltip: _isPasswordVisible ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'تأكيد كلمة المرور الجديدة',
                  hint: 'أعد إدخال كلمة المرور',
                  icon: Icons.lock_reset_rounded,
                  validator: (value) => FormValidators.validateConfirmPassword(
                    value,
                    originalPassword: _passwordController.text,
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    tooltip: _isConfirmPasswordVisible ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
                    onPressed: () => setState(
                      () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                    ),
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'تحديث كلمة المرور',
                  icon: Icons.check_rounded,
                  isLoading: widget.controller.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
