// lib/constants/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// Единая тема приложения.
  /// Используйте её в MaterialApp: `theme: AppTheme.theme`.
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.customStyle),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Здесь же можно централизовать остальное:
        // fontFamily: 'Montserrat',
        // scaffoldBackgroundColor: AppColors.customBackgr,
        // appBarTheme: AppBarTheme(backgroundColor: AppColors.appBarBackground),
        // sliderTheme: SliderThemeData(...),
      );
}