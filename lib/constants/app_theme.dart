// lib/constants/app_theme.dart
import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';

/// Единая тёмная тема приложения.
/// Всё, что задано здесь, НЕ нужно повторять в экранах
/// (фон Scaffold, AppBar, кнопки, индикаторы, диалоги, слайдеры, свитчи).
class AppTheme {
  AppTheme._();

  /// Глобальный шрифт приложения
  static const String fontFamily = 'Montserrat';

  /// Стили, переданные в компоненты темы напрямую, не наследуют
  /// fontFamily из ThemeData — добавляем его явно.
  static TextStyle _font(TextStyle style) =>
      style.copyWith(fontFamily: fontFamily);

  static final ThemeData dark = _buildDark();

  static ThemeData _buildDark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.customStyle,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.customStyle,
      onPrimary: AppColors.customWhite,
      surface: AppColors.customBackgr,
      onSurface: AppColors.customWhite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: AppColors.customBackgr,

      // ---------- AppBar ----------
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.customWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.customTransp,
        titleTextStyle: _font(AppTextStyles.appBarTitle),
      ),

      // ---------- Drawer ----------
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.appBarBackground,
      ),

      // ---------- Диалоги ----------
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.appBarBackground,
        titleTextStyle: _font(AppTextStyles.medium),
        contentTextStyle: _font(AppTextStyles.mediumMuted),
      ),

      // ---------- SnackBar ----------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardBackground,
        contentTextStyle: _font(AppTextStyles.medium),
      ),

      // ---------- Разделители ----------
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: AppDimens.dividerThickness,
      ),

      // ---------- Индикаторы загрузки ----------
      // (RefreshIndicator берёт цвет из colorScheme.primary)
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.customStyle,
      ),

      // ---------- Кнопки ----------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.customStyle,
          foregroundColor: AppColors.customWhite,
          textStyle: _font(AppTextStyles.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.customStyle,
          side: const BorderSide(color: AppColors.customStyle),
          textStyle: _font(AppTextStyles.button),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.customStyle,
        ),
      ),

      // ---------- Свитчи ----------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.customStyle
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.customStyle.withValues(alpha: 0.35)
              : null,
        ),
      ),

      // ---------- Слайдеры ----------
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.customStyle,
        inactiveTrackColor: AppColors.sliderInactiveTrack,
        thumbColor: AppColors.customStyle,
        overlayColor: AppColors.customStyle.withValues(alpha: 0.2),
        trackHeight: AppDimens.sliderTrackHeight,
      ),
    );
  }
}
