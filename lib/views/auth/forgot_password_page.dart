import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/app_constants.dart';
import '../../utils/form_validators.dart';
import 'reset_password_page.dart';
import 'widgets/auth_page_shell.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/primary_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final result = await widget.controller.sendPasswordResetCode(identifier: identifier);
    if (!mounted) return;

    showAuthMessage(context, message: result.message, isSuccess: result.isSuccess);
    if (result.isSuccess) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordPage(
            controller: widget.controller,
            identifier: identifier,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return AuthPageShell(
          showBackButton: true,
          title: 'استعادة كلمة المرور',
          subtitle: 'أدخل المعرّف المرتبط بحسابك للمتابعة إلى إعادة تعيين كلمة المرور.',
          icon: Icons.mark_email_read_outlined,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppConstants.primaryLight),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'سننشئ رمز تحقق تجريبياً داخل التطبيق. لا يتم إرسال بريد إلكتروني أو رسالة نصية فعلية.',
                          style: TextStyle(height: 1.7, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                AuthTextField(
                  controller: _identifierController,
                  label: 'البريد الإلكتروني أو الرقم الأكاديمي',
                  hint: 'أدخل المعرّف المسجل في حسابك',
                  icon: Icons.person_search_outlined,
                  validator: FormValidators.validateIdentifier,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'إنشاء رمز التحقق',
                  icon: Icons.send_rounded,
                  isLoading: widget.controller.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                Text(
                  'رمز العرض التوضيحي: ${AppConstants.demoOtp}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
