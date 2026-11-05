import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/auth_controller.dart';
import 'repositories/auth_repository_impl.dart';
import 'services/remembered_identifier_store.dart';
import 'utils/app_constants.dart';
import 'views/auth/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AuthController(
    repository: AuthRepositoryImpl(),
    rememberedIdentifierStore: const MethodChannelRememberedIdentifierStore(),
  );
  await controller.initialize();
  runApp(EduGateApp(controller: controller));
}

class EduGateApp extends StatefulWidget {
  const EduGateApp({super.key, required this.controller});

  final AuthController controller;

  @override
  State<EduGateApp> createState() => _EduGateAppState();
}

class _EduGateAppState extends State<EduGateApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppConstants.primary;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: AppConstants.accent,
      surface: Colors.white,
      error: AppConstants.danger,
    );

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppConstants.background,
        fontFamily: AppConstants.fontFamily,
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppConstants.textPrimary),
          displayMedium: TextStyle(color: AppConstants.textPrimary),
          displaySmall: TextStyle(color: AppConstants.textPrimary),
          headlineLarge: TextStyle(color: AppConstants.textPrimary),
          headlineMedium: TextStyle(color: AppConstants.textPrimary),
          headlineSmall: TextStyle(color: AppConstants.textPrimary),
          titleLarge: TextStyle(color: AppConstants.textPrimary),
          titleMedium: TextStyle(color: AppConstants.textPrimary),
          titleSmall: TextStyle(color: AppConstants.textPrimary),
          bodyLarge: TextStyle(color: AppConstants.textPrimary),
          bodyMedium: TextStyle(color: AppConstants.textPrimary),
          bodySmall: TextStyle(color: AppConstants.textSecondary),
          labelLarge: TextStyle(color: AppConstants.textPrimary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFCFD),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          labelStyle: const TextStyle(color: AppConstants.textSecondary),
          hintStyle: const TextStyle(color: Color(0xFF9AA8B2), fontSize: 13),
          prefixIconColor: AppConstants.primaryLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppConstants.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppConstants.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppConstants.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppConstants.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppConstants.danger, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppConstants.primary.withValues(alpha: 0.45),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontVariations: [FontVariation('wght', 700)],
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.primaryLight,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontVariations: [FontVariation('wght', 700)],
            ),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: LoginPage(controller: widget.controller),
    );
  }
}
