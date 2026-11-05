import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'بوابة الطالب';
  static const String demoOtp = '123456';
  static const Duration simulatedNetworkDelay = Duration(milliseconds: 450);

  static const Color primary = Color(0xFF173B57);
  static const Color primaryLight = Color(0xFF285B7C);
  static const Color accent = Color(0xFFC69A52);
  static const Color background = Color(0xFFF3F6F9);
  static const Color textPrimary = Color(0xFF1D2B36);
  static const Color textSecondary = Color(0xFF687985);
  static const Color success = Color(0xFF16845B);
  static const Color danger = Color(0xFFB84040);
  static const Color border = Color(0xFFDCE4EA);

  /// Local Cairo variable font registered in pubspec.yaml.
  static const String fontFamily = 'Cairo';
}
