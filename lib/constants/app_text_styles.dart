import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';

/// Централизованные размеры шрифтов.
/// Всего три размера — Small / Medium / Large.
class AppFontSizes {
  AppFontSizes._();

  /// 10 — мелкие подписи, бейджи, "СЕЙЧАС В ЭФИРЕ", "LIVE"
  static const double small = 10.0;

  /// 14 — основной текст: исполнитель, описания, обычные подписи
  static const double medium = 14.0;

  /// 16 — для компактного режима
  static const double compactLarge = 16.0;  

  /// 18 — заголовки трека, названия, крупные акценты
  static const double large = 18.0;
}

/// Готовые TextStyle-ы для типовых случаев.
/// Используйте их вместо ручного `TextStyle(fontSize: ...)`.
class AppTextStyles {
  AppTextStyles._();

  // ==================== МЕЛКИЙ (10) ====================
  /// "СЕЙЧАС В ЭФИРЕ", "LIVE", подписи под иконками
  static const TextStyle small = TextStyle(
    fontSize: AppFontSizes.small,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );

  /// Мелкий серый текст (подписи, вспомогательное)
  static TextStyle smallMuted = TextStyle(
    fontSize: AppFontSizes.small,
    color: AppColors.customWhite.withValues(alpha: 0.6),
  );

  /// Мелкий акцентный (например, "СЕЙЧАС В ЭФИРЕ" в цвете customStyle)
  static const TextStyle smallAccent = TextStyle(
    fontSize: AppFontSizes.small,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.customStyle,
  );

  // ==================== СРЕДНИЙ (14) ====================
  /// Обычный текст на белом
  static const TextStyle medium = TextStyle(
    fontSize: AppFontSizes.medium,
    color: AppColors.customWhite,
  );

  /// Серый текст (исполнитель, описание)
  static TextStyle mediumMuted = TextStyle(
    fontSize: AppFontSizes.medium,
    color: AppColors.customWhite.withValues(alpha: 0.6),
  );

  /// Жирный средний (для акцентов)
  static const TextStyle mediumBold = TextStyle(
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.bold,
    color: AppColors.customWhite,
    height: 1.2,

  );

  // ==================== КРУПНЫЙ (18) ====================
  /// Заголовок трека / название
  static const TextStyle large = TextStyle(
    fontSize: AppFontSizes.large,
    fontWeight: FontWeight.bold,
    color: AppColors.customWhite,
    height: 1.2,
  );

  /// Крупный обычный (без жирного)
  static const TextStyle largeRegular = TextStyle(
    fontSize: AppFontSizes.large,
    color: AppColors.customWhite,
    height: 1.2,
  );
}