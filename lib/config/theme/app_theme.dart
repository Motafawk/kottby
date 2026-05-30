import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// تعريف ثيم التطبيق المطابق للإصدار القديم.
///
/// نستخدم Material 2 (useMaterial3: false) للحفاظ على نفس مظهر الإصدار القديم.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final MaterialColor primarySwatchMaterial = MaterialColor(
      AppColors.primary.toARGB32(),
      AppColors.primarySwatch,
    );

    return ThemeData(
      useMaterial3: false,
      fontFamily: AppStrings.fontFamily,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      canvasColor: AppColors.scaffoldBackground,
      primarySwatch: primarySwatchMaterial,
      // ألوان الـ AppBar: خلفية تركوازية (اللون الأساسي) + نص أبيض.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: AppStrings.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      // أزرار التطبيق الأساسية باللون التركوازي.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // تنسيق InputDecoration المستخدم في حقول البحث (نفس الإصدار القديم).
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.only(
          top: 10,
          left: 10,
          right: 10,
          bottom: 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          gapPadding: 0,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.tertiary[300]!),
          borderRadius: BorderRadius.circular(4),
          gapPadding: 0,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary),
          borderRadius: BorderRadius.circular(4),
          gapPadding: 0,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          gapPadding: 0,
          borderSide: BorderSide(color: AppColors.tertiary[500]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          gapPadding: 0,
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.red),
          gapPadding: 0,
        ),
        labelStyle: const TextStyle(height: 1),
        hintStyle: TextStyle(height: 1.5, color: AppColors.tertiary[400]),
        helperStyle: const TextStyle(height: 1.4),
        helperMaxLines: 3,
        fillColor: Colors.white,
        filled: true,
        errorStyle: const TextStyle(height: 0.8, color: Colors.red),
      ),
    );
  }
}
