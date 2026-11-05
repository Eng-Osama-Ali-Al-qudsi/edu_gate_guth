import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';

import '../../../utils/app_constants.dart';

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.showBackButton = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: showBackButton
          ? AppBar(
              backgroundColor: AppConstants.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                tooltip: 'رجوع',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth < 380 ? 18 : 26,
                vertical: 22,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppConstants.primary,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primary.withValues(alpha: 0.18),
                                blurRadius: 22,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 34),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppConstants.accent,
                              fontWeight: FontWeight.w700,
                              fontVariations: const [FontVariation('wght', 700)],
                              letterSpacing: 0.2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppConstants.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontVariations: const [FontVariation('wght', 800)],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppConstants.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontVariations: const [FontVariation('wght', 500)],
                              height: 1.7,
                            ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppConstants.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D173B57),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'بوابة الخدمات الأكاديمية للطلاب',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
