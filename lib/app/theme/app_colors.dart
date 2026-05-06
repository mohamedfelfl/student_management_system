import 'package:flutter/material.dart';

/// Design System Colors following "The Academic Atelier" (Light)
/// and "The Scholarly Midnight" (Dark) specifications.
class AppColors {
  AppColors._();

  // ─── LIGHT MODE: "The Academic Atelier" ───

  static const lightPrimary = Color(0xFF4F378A);
  static const lightPrimaryContainer = Color(0xFF6750A4);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightOnPrimaryContainer = Color(0xFFFFFFFF);

  static const lightSecondary = Color(0xFF625B71);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightSecondaryContainer = Color(0xFFE8DEF8);
  static const lightOnSecondaryContainer = Color(0xFF1D192B);

  static const lightTertiary = Color(0xFF633B48);
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightTertiaryContainer = Color(0xFFFFD8E4);
  static const lightOnTertiaryContainer = Color(0xFF31111D);

  static const lightSurface = Color(0xFFFFFBFE);
  static const lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const lightSurfaceContainerLow = Color(0xFFF7F2FA);
  static const lightSurfaceContainer = Color(0xFFF3EDF7);
  static const lightSurfaceContainerHigh = Color(0xFFECE6F0);
  static const lightSurfaceContainerHighest = Color(0xFFE6E0E9);
  static const lightOnSurface = Color(0xFF1C1B1F);
  static const lightOnSurfaceVariant = Color(0xFF49454F);

  static const lightBackground = Color(0xFFFFFBFE);
  static const lightOnBackground = Color(0xFF1C1B1F);

  static const lightOutline = Color(0xFF79747E);
  static const lightOutlineVariant = Color(0xFFCAC4D0);

  static const lightError = Color(0xFFB3261E);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFF9DEDC);
  static const lightOnErrorContainer = Color(0xFF410E0B);

  // ─── DARK MODE: "The Scholarly Midnight" ───

  static const darkPrimary = Color(0xFFC2C2F2);
  static const darkPrimaryContainer = Color(0xFF101037);
  static const darkOnPrimary = Color(0xFF1C1B2E);
  static const darkOnPrimaryContainer = Color(0xFFE4E1F6);

  static const darkSecondary = Color(0xFFD3BBFF);
  static const darkOnSecondary = Color(0xFF1E1A2E);
  static const darkSecondaryContainer = Color(0xFF592AA9);
  static const darkOnSecondaryContainer = Color(0xFFC7AAFF);

  static const darkTertiary = Color(0xFFF6ADFF);
  static const darkOnTertiary = Color(0xFF2E1A33);
  static const darkTertiaryContainer = Color(0xFF5C3D63);
  static const darkOnTertiaryContainer = Color(0xFFFFD6FF);

  static const darkSurface = Color(0xFF131316);
  static const darkSurfaceBright = Color(0xFF39393C);
  static const darkSurfaceContainerLowest = Color(0xFF0E0E11);
  static const darkSurfaceContainerLow = Color(0xFF1B1B1E);
  static const darkSurfaceContainer = Color(0xFF201F23);
  static const darkSurfaceContainerHigh = Color(0xFF2A2A2D);
  static const darkSurfaceContainerHighest = Color(0xFF353438);
  static const darkOnSurface = Color(0xFFE4E1E6);
  static const darkOnSurfaceVariant = Color(0xFFC8C5CF);

  static const darkBackground = Color(0xFF131316);
  static const darkOnBackground = Color(0xFFE4E1E6);

  static const darkOutline = Color(0xFF938F99);
  static const darkOutlineVariant = Color(0xFF47464E);

  static const darkError = Color(0xFFF2B8B5);
  static const darkOnError = Color(0xFF601410);
  static const darkErrorContainer = Color(0xFF8C1D18);
  static const darkOnErrorContainer = Color(0xFFF9DEDC);

  // ─── SEMANTIC COLORS ───

  static const success = Color(0xFF4CAF50);
  static const successContainer = Color(0xFFC8E6C9);
  static const warning = Color(0xFFFFC107);
  static const warningContainer = Color(0xFFFFF8E1);
  static const info = Color(0xFF2196F3);
  static const infoContainer = Color(0xFFBBDEFB);

  // ─── STATUS CHIPS ───

  static const attendedChip = Color(0xFF4CAF50);
  static const missedChip = Color(0xFFEF5350);
  static const otherLessonChip = Color(0xFFFF9800);

  // ─── ACTION CARD COLORS (Dashboard Quick Actions) ───

  static const actionStudent = Color(0xFF6750A4);
  static const actionQrScanner = Color(0xFFE91E63);
  static const actionAssistant = Color(0xFF607D8B);
  static const actionAssistantDir = Color(0xFF795548);
  static const actionPayment = Color(0xFF4CAF50);
  static const actionExam = Color(0xFFFF9800);
  static const actionReport = Color(0xFF2196F3);
  static const actionGroup = Color(0xFF9C27B0);
  static const actionNotes = Color(0xFF00897B);
  static const actionAdmin = Color(0xFF3F51B5);
  static const actionHonor = Color(0xFFFFC107);
  static const actionSettings = Color(0xFF607D8B);

  // ─── RANK COLORS (Honor Board & Exams) ───

  static const rankGold = Color(0xFFFFD700);
  static const rankSilver = Color(0xFFC0C0C0);
  static const rankBronze = Color(0xFFCD7F32);
  static const rankFirst = Color(0xFF4F378A);
  static const rankSecond = Color(0xFF79747E);
  static const rankThird = Color(0xFF8D6E63);

  // ─── EXAM TAB COLORS ───

  static const examTabActive = Color(0xFFD3BBFF);
  static const examTabInactive = Color(0xFFFFD8E4);
  static const examTabActiveText = Color(0xFF4F378A);
  static const examTabInactiveText = Color(0xFF633B48);

  // ─── GLASSMORPHISM HELPERS ───

  /// Light mode glass opacity (85%)
  static const double lightGlassOpacity = 0.85;

  /// Dark mode glass opacity (80%)
  static const double darkGlassOpacity = 0.80;

  /// Ghost border opacity (15%)
  static const double ghostBorderOpacity = 0.15;

  /// Ambient shadow opacity
  static const double ambientShadowOpacity = 0.06;
  static const double darkAmbientShadowOpacity = 0.40;
}
