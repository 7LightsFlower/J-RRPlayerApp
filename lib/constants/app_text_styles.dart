import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';

/// Централизованные размеры шрифтов.
/// Шкала: 10 / 11 / 12 / 14 / 16 / 18
class AppFontSizes {
  AppFontSizes._();

  /// 10 — мелкие подписи, бейджи, "LIVE", подписи под иконками навигации
  static const double small = 10.0;

  /// 12 — табы (верхние), подписи нижней навигации
  static const double tab = 12.0;

  /// 12 — названия подкастов / эпизодов, компактные заголовки
  static const double smallMedium = 12.0;

  /// 14 — основной текст: исполнитель, описания, обычные подписи
  static const double medium = 14.0;

  /// 16 — компактный крупный (заголовки в списках)
  static const double compactLarge = 16.0;

  /// 18 — заголовки трека, названия экранов, крупные акценты
  static const double large = 18.0;
}

/// Готовые TextStyle-ы для типовых случаев.
/// Используйте их вместо ручного `TextStyle(fontSize: ...)`.
class AppTextStyles {
  AppTextStyles._();

  // ==================== 10 — МЕЛКИЙ ====================
  /// "СЕЙЧАС В ЭФИРЕ", "LIVE", бейджи
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

  // ==================== 11 — ТАБЫ / НАВИГАЦИЯ ====================
  /// Активный таб (верхние табы, выбранный пункт)
  static const TextStyle tabActive = TextStyle(
    fontSize: AppFontSizes.tab,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.customStyle,
  );

  /// Неактивный таб
  static TextStyle tabInactive = TextStyle(
    fontSize: AppFontSizes.tab,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.3,
    color: AppColors.customWhite.withValues(alpha: 0.5),
  );

  /// Подпись нижней навигации — активная
  static const TextStyle navActive = TextStyle(
    fontSize: AppFontSizes.tab,
    fontWeight: FontWeight.w600,
    color: AppColors.customStyle,
  );

  /// Подпись нижней навигации — неактивная
  static TextStyle navInactive = TextStyle(
    fontSize: AppFontSizes.tab,
    fontWeight: FontWeight.normal,
    color: AppColors.customWhite.withValues(alpha: 0.5),
  );

  // ==================== 12 — ПОДКАСТЫ ====================
  /// Название подкаста / эпизода в списке
  static const TextStyle podcastTitle = TextStyle(
    fontSize: AppFontSizes.smallMedium,
    fontWeight: FontWeight.w400,
    color: AppColors.customWhite,
    height: 1.2,
  );

  /// Название подкаста — приглушённое (например, прослушанное)
  static TextStyle podcastTitleMuted = TextStyle(
    fontSize: AppFontSizes.smallMedium,
    color: AppColors.customWhite.withValues(alpha: 0.6),
    height: 1.2,
  );

  /// Мета-информация эпизода (дата, длительность)
  static TextStyle podcastMeta = TextStyle(
    fontSize: AppFontSizes.smallMedium,
    color: AppColors.customWhite.withValues(alpha: 0.5),
    height: 1.2,
  );

  // ==================== 14 — СРЕДНИЙ ====================
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

  /// Акцентный средний (цвет customStyle)
  static const TextStyle mediumAccent = TextStyle(
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.w600,
    color: AppColors.customStyle,
  );

  // ==================== 16 — КОМПАКТНЫЙ КРУПНЫЙ ====================
  /// Заголовок в компактных списках / карточках
  static const TextStyle compactLarge = TextStyle(
    fontSize: AppFontSizes.compactLarge,
    fontWeight: FontWeight.w600,
    color: AppColors.customWhite,
    height: 1.2,
  );

  /// Компактный крупный — обычный
  static const TextStyle compactLargeRegular = TextStyle(
    fontSize: AppFontSizes.compactLarge,
    color: AppColors.customWhite,
    height: 1.2,
  );

  // ==================== 18 — КРУПНЫЙ ====================
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

  /// Заголовок экрана (AppBar title)
  static const TextStyle appBarTitle = TextStyle(
    fontSize: AppFontSizes.large,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  // ==================== КНОПКИ ====================
  /// Текст ElevatedButton / OutlinedButton
  static const TextStyle button = TextStyle(
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.w600,
  );
}