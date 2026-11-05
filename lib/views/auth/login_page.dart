import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/login_request.dart';
import '../../utils/app_constants.dart';
import '../../utils/form_validators.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'widgets/auth_page_shell.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _identifierController.text = widget.controller.rememberedIdentifier ?? '';
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final result = await widget.controller.login(
      request: LoginRequest(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      ),
    );
    if (!mounted) return;

    if (!result.isSuccess) {
      showAuthMessage(context, message: result.message, isSuccess: false);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.verified_rounded, color: AppConstants.success, size: 38),
        title: const Text('تم تسجيل الدخول'),
        content: Text('مرحباً ${result.user?.fullName ?? 'بك'}، نتمنى لك تجربة أكاديمية موفقة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterPage(controller: widget.controller),
      ),
    );
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordPage(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return AuthPageShell(
          title: 'تسجيل الدخول',
          subtitle: 'سجّل الدخول للوصول إلى حسابك وخدماتك الأكاديمية.',
          icon: Icons.school_rounded,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _identifierController,
                  label: 'الرقم الأكاديمي أو البريد الإلكتروني',
                  hint: 'أدخل المعرّف الأكاديمي أو البريد',
                  icon: Icons.badge_outlined,
                  validator: FormValidators.validateIdentifier,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  hint: 'أدخل كلمة المرور',
                  icon: Icons.lock_outline_rounded,
                  validator: FormValidators.validateLoginPassword,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    tooltip: _isPasswordVisible ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: widget.controller.rememberMe,
                      onChanged: (value) => widget.controller.setRememberMe(value ?? false),
                      activeColor: AppConstants.primary,
                    ),
                    const Expanded(child: Text('تذكر معرّف الحساب على هذا الجهاز')),
                    TextButton(
                      onPressed: _openForgotPassword,
                      child: const Text('نسيت كلمة المرور؟'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'تسجيل الدخول',
                  icon: Icons.login_rounded,
                  isLoading: widget.controller.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ليس لديك حساب؟'),
                    TextButton(
                      onPressed: _openRegister,
                      child: const Text('إنشاء حساب جديد'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppConstants.primaryLight),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'يُحفظ المعرّف فقط دون كلمة المرور. الحساب التجريبي نفسه يُفقد عند إغلاق التطبيق؛ قد تحتاج إلى إنشاء الحساب مجدداً بعد إعادة التشغيل.',
                          style: TextStyle(fontSize: 12, height: 1.6, color: AppConstants.textSecondary),
                        ),
                      ),
                    ],
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
