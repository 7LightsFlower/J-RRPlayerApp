// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Основные цвета фона
  static const Color customBackgr = Color(0xFF202020);
  static const Color customBackgrNight = Color(0xFF000000);

  // Системные цвета
  static const Color statusBarColor = Color(0xFF202020);
  static const Color navBarColor = Color(0x00000000);

  // ===== AppBar / навигация (единый тёмный стиль) =====
  /// Фон AppBar, верхних табов и нижней навигации
  static const Color appBarBackground = Color(0xFF0F141E);

  /// Цвет разделителей/границ у AppBar, табов, нижней навигации
  static const Color appBarBorder = Color(0xFF1C212B);

  /// Фон карточек/элементов списка на тёмном фоне
  static const Color cardBackground = Color(0xFF1A1F29);

  /// Фон плейсхолдеров/неактивных поверхностей
  static const Color surfaceMuted = Color(0xFF232A36);

  /// Неактивный трек слайдера / прогресс-бара
  static const Color sliderInactiveTrack = Color(0xFF2A3242);

  /// Неактивная точка в индикаторах карусели
  static const Color dotInactive = Color(0xFF3A4553);

  // ===== Текст на тёмном =====
  /// Приглушённый серый текст (описания, даты)
  static const Color textMuted = Color(0xFF9AA4B2);

  /// Ещё тише (второстепенные даты, подписи)
  static const Color textSubtle = Color(0xFF6E7787);

  // Акцентные цвета
  static const Color primary = Color(0xFF53B9C5);
  static const Color primaryDark = Color(0xFF3A8A92);
  static const Color primaryLight = Color(0xFF66F0FF);
  static const Color secondary = Color(0xFF007F02);
  static const Color secondaryDark = Color(0xFF004C01);
  static const Color secondaryLight = Color(0xFF00FF40);

  // Базовые цвета
  static const Color customWhite = Color(0xFFFFFFFF);
  static const Color customBlack = Color(0xFF202020);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Полупрозрачные цвета
  static const Color transpStyleStatusBar = Color(0xE6202020);
  static const Color transpStyleNavBar = Color(0xE6202020);

  // Дополнительные цвета
  static const Color customIcon = Color(0xFF6A1818);
  static const Color customStyle = Color(0xFF53B9C5);
  static const Color customStyleShadow = Color(0xFFABDCDC);
  static const Color customVolume = Color(0xFF007BFF);
  static const Color customWhiteTransp = Color(0xFF383838);
  static const Color customRed = Color(0xFFFF0000);
  static const Color customGreen = Color(0xFF007F02);
  static const Color customLightGreen = Color(0xFF66BB6A);
  static const Color customTransp = Color(0x00000000);
  static const Color customPurple = Color(0xFF9C27B0);
  static const Color customGrey = Color(0xFF757575);
  static const Color customDarkGrey = Color(0xFF424242);
}