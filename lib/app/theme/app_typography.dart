import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system following the "Editorial Scale" design specification.
/// Updated to use 'Cairo' globally to match the modern Arabic aesthetic
/// shown in the new UI designs.
class AppTypography {
  AppTypography._();

  // ─── DISPLAY ───

  /// Display Large — scaled down from 42px
  static TextStyle displayLarge({Color? color}) => GoogleFonts.cairo(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    height: 1.12,
    color: color,
  );

  /// Display Medium — scaled down from 32px
  static TextStyle displayMedium({Color? color}) => GoogleFonts.cairo(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.18,
    color: color,
  );

  /// Display Small — scaled down from 28px
  static TextStyle displaySmall({Color? color}) => GoogleFonts.cairo(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.22,
    color: color,
  );

  // ─── HEADLINES ───

  /// Headline Large — scaled down from 24px, page titles
  static TextStyle headlineLarge({Color? color}) => GoogleFonts.cairo(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: color,
  );

  /// Headline Medium — scaled down from 20px
  static TextStyle headlineMedium({Color? color}) => GoogleFonts.cairo(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.29,
    color: color,
  );

  /// Headline Small — scaled down from 18px
  static TextStyle headlineSmall({Color? color}) => GoogleFonts.cairo(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: color,
  );

  // ─── TITLE ───

  /// Title Large — scaled down from 18px
  static TextStyle titleLarge({Color? color}) => GoogleFonts.cairo(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.27,
    color: color,
  );

  /// Title Medium — scaled down from 14px
  static TextStyle titleMedium({Color? color}) => GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: color,
  );

  /// Title Small — scaled down from 12px
  static TextStyle titleSmall({Color? color}) => GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.43,
    color: color,
  );

  // ─── BODY ───

  /// Body Large — scaled down from 14px, line height 1.6 for readability
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.6,
    color: color,
  );

  /// Body Medium — scaled down from 12px
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.6,
    color: color,
  );

  /// Body Small — scaled down from 10px
  static TextStyle bodySmall({Color? color}) => GoogleFonts.cairo(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.6,
    color: color,
  );

  // ─── LABELS ───

  /// Label Large — scaled down from 12px
  static TextStyle labelLarge({Color? color}) => GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.43,
    color: color,
  );

  /// Label Medium — scaled down from 10px, metadata (IDs, timestamps)
  static TextStyle labelMedium({Color? color}) => GoogleFonts.cairo(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: color,
  );

  /// Label Small — scaled down from 9px
  static TextStyle labelSmall({Color? color}) => GoogleFonts.cairo(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: color,
  );

  // ─── HELPER: Build TextTheme ───

  static TextTheme textTheme({Color? displayColor, Color? bodyColor}) =>
      TextTheme(
        displayLarge: displayLarge(color: displayColor),
        displayMedium: displayMedium(color: displayColor),
        displaySmall: displaySmall(color: displayColor),
        headlineLarge: headlineLarge(color: displayColor),
        headlineMedium: headlineMedium(color: displayColor),
        headlineSmall: headlineSmall(color: displayColor),
        titleLarge: titleLarge(color: bodyColor),
        titleMedium: titleMedium(color: bodyColor),
        titleSmall: titleSmall(color: bodyColor),
        bodyLarge: bodyLarge(color: bodyColor),
        bodyMedium: bodyMedium(color: bodyColor),
        bodySmall: bodySmall(color: bodyColor),
        labelLarge: labelLarge(color: bodyColor),
        labelMedium: labelMedium(color: bodyColor),
        labelSmall: labelSmall(color: bodyColor),
      );
}
