import 'package:flutter/material.dart';
import 'package:gia_pha/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.red,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.red,
      onPrimary: AppColors.goldLight,
      primaryContainer: AppColors.paperDark,
      onPrimaryContainer: AppColors.redDark,
      secondary: AppColors.gold,
      onSecondary: AppColors.redDeep,
      secondaryContainer: AppColors.goldLight,
      onSecondaryContainer: AppColors.redDeep,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      outline: AppColors.goldDark,
      outlineVariant: AppColors.gold,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.redDeep,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: AppColors.goldLight,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.red),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.red,
          selectedForegroundColor: AppColors.goldLight,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.gold),
      popupMenuTheme: const PopupMenuThemeData(color: AppColors.paper),
    );
  }
}
