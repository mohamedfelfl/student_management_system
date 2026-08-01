import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Student Management System';
  static const String dbName = 'sms_encrypted.db';
  static const String defaultRole = 'user';
  static const String adminRole = 'admin';
  static const String userRole = 'user';
  
  // Supported locales
  static const String en = 'en';
  static const String ar = 'ar';
  
  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // Assets
  static const String logoAssetPath = 'assets/images/logo.png';

  // Student Code & Schedule Constants
  static const String studentCodePrefix = 'EM';
  static const String pngExtension = 'png';
  static const String daySaturday = 'saturday';
  static const String daySunday = 'sunday';
  static const String dayMonday = 'monday';
  static const String dayTuesday = 'tuesday';
  static const String dayWednesday = 'wednesday';
  static const String dayThursday = 'thursday';
  static const String dayFriday = 'friday';
}

class AppCardColors {
  static const navy = Color(0xFF071B38);
  static const brandBlue = Color(0xFF1D61E7);
  static const gold = Color(0xFFF3AB3C);
  static const lightBg = Color(0xFFEBF3FF);
  static const cyanDivider = Color(0xFF00A8E8);
  static const cardWhite = Color(0xFFFFFFFF);
  static const textDark = Color(0xDD000000);
  static const textMuted = Color(0xFF757575);
  static const successGreen = Color(0xFF388E3C);
  static const iconAmber = Color(0xFFFFC107);
}
