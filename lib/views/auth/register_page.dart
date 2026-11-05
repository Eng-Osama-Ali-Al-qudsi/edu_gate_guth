import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/auth_controller.dart';
import '../../models/register_request.dart';
import '../../utils/app_constants.dart';
import '../../utils/form_validators.dart';
import 'widgets/auth_page_shell.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _academicIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _academicIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final result = await widget.controller.register(
      request: RegisterRequest(
        fullName: _fullNameController.text.trim(),
        academicId: _academicIdController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
    if (!mounted) return;

    showAuthMessage(context, message: result.message, isSuccess: result.isSuccess);
    if (result.isSuccess) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return AuthPageShell(
          showBackButton: true,
          title: 'إنشاء حساب جديد',
          subtitle: 'أدخل بياناتك الأكاديمية لإنشاء حساب الطالب.',
          icon: Icons.person_add_alt_1_rounded,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _fullNameController,
                  label: 'الاسم الكامل',
                  hint: 'كما هو مسجل في الجامعة',
                  icon: Icons.person_outline_rounded,
                  validator: FormValidators.validateFullName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _academicIdController,
                  label: 'الرقم الأكاديمي',
                  hint: '9 أو 10 أرقام',
                  icon: Icons.badge_outlined,
                  validator: FormValidators.validateAcademicId,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني الجامعي',
                  hint: 'name@example.com',
                  icon: Icons.alternate_email_rounded,
                  validator: FormValidators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
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
                  label: 'تأكيد كلمة المرور',
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
                const SizedBox(height: 12),
                FormField<bool>(
                  initialValue: false,
                  validator: (value) => value == true ? null : 'يجب الموافقة على الشروط والأحكام للمتابعة.',
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: field.value ?? false,
                          onChanged: field.didChange,
                          title: const Text(
                            'أوافق على الشروط والأحكام',
                            style: TextStyle(fontSize: 13),
                          ),
                          activeColor: AppConstants.primary,
                        ),
                        if (field.errorText != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 12, bottom: 4),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'إنشاء الحساب',
                  icon: Icons.person_add_alt_1_rounded,
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
