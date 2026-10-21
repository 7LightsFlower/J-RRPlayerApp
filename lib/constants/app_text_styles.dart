import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';

/// Централизованные размеры шрифтов.
/// Шкала: 10 / 12 / 14 / 16 / 18 / 22
class AppFontSizes {
  AppFontSizes._();

  /// 10 — мелкие подписи, бейджи, подписи под иконками навигации
  static const double small = 10.0;

  /// 10 — табы, подписи нижней навигации
  static const double tab = 10.0;

  /// 12 — названия подкастов / эпизодов, компактные заголовки
  static const double smallMedium = 12.0;

  /// 14 — основной текст: исполнитель, описания, обычные подписи
  static const double medium = 14.0;

  /// 16 — компактный крупный (заголовки в списках)
  static const double compactLarge = 16.0;

  /// 18 — заголовки трека, названия экранов, крупные акценты
  static const double large = 18.0;

  /// 18 — название трека в плеере
  static const double playerTitle = 18.0;

  static const double largeTitle = 22.0;
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
  static final TextStyle smallMuted = TextStyle(
    fontSize: AppFontSizes.small,
    color: AppColors.customWhite.withValues(alpha: 0.6),
  );

  /// Мелкий серый с увеличенным межстрочным (описания в карточках)
  static final TextStyle smallMutedTall = smallMuted.copyWith(height: 1.35);

  /// Мелкий акцентный (например, "СЕЙЧАС В ЭФИРЕ" в цвете customStyle)
  static const TextStyle smallAccent = TextStyle(
    fontSize: AppFontSizes.small,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.customStyle,
  );

  /// Бейдж категории статьи (акцентный, чуть плотнее)
  static const TextStyle badge = TextStyle(
    fontSize: AppFontSizes.small,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.customStyle,
  );

  // ==================== 10 — ТАБЫ / НАВИГАЦИЯ ====================
  /// Активный таб (верхние табы, выбранный пункт)
  static const TextStyle tabActive = TextStyle(
    fontSize: AppFontSizes.tab,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.customStyle,
  );

  /// Неактивный таб
  static final TextStyle tabInactive = TextStyle(
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
  static final TextStyle navInactive = TextStyle(
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

  /// Название эпизода в карточке подкаста (две строки с воздухом)
  static final TextStyle podcastTitleTall = podcastTitle.copyWith(height: 1.5);

  /// Название подкаста — приглушённое (например, прослушанное)
  static final TextStyle podcastTitleMuted = TextStyle(
    fontSize: AppFontSizes.smallMedium,
    color: AppColors.customWhite.withValues(alpha: 0.6),
    height: 1.2,
  );

  /// Мета-информация эпизода (дата, длительность)
  static final TextStyle podcastMeta = TextStyle(
    fontSize: AppFontSizes.smallMedium,
    color: AppColors.customWhite.withValues(alpha: 0.5),
    height: 1.2,
  );

  /// Описание в карточке статьи (12, серый, межстрочный 1.35)
  static final TextStyle podcastMetaTall = podcastMeta.copyWith(height: 1.35);

  // ==================== 14 — СРЕДНИЙ ====================
  /// Обычный текст на белом
  static const TextStyle medium = TextStyle(
    fontSize: AppFontSizes.medium,
    color: AppColors.customWhite,
  );

  /// Обычный белый текст абзацем (межстрочный 1.5) — тело новости
  static const TextStyle mediumBody = TextStyle(
    fontSize: AppFontSizes.medium,
    color: AppColors.customWhite,
    height: 1.5,
  );

  /// Серый текст (исполнитель, описание)
  static final TextStyle mediumMuted = TextStyle(
    fontSize: AppFontSizes.medium,
    color: AppColors.customWhite.withValues(alpha: 0.6),
  );

  /// Серый текст абзацем (межстрочный 1.5) — описание «О радио»
  static final TextStyle mediumMutedBody = mediumMuted.copyWith(height: 1.5);

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

  /// Заголовок бренда в AppBar (РАДИО J-ROCK)
  static const TextStyle brandTitle = TextStyle(
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.customWhite,
  );

  /// Основной читаемый текст с межстрочным (абзацы, описания)
  static final TextStyle mediumReadable = TextStyle(
    fontSize: AppFontSizes.medium,
    color: AppColors.customWhite.withValues(alpha: 0.7),
    height: 1.5,
  );

  // ==================== 16 — КОМПАКТНЫЙ КРУПНЫЙ ====================
  /// Заголовок в компактных списках / карточках
  static const TextStyle compactLarge = TextStyle(
    fontSize: AppFontSizes.compactLarge,
    fontWeight: FontWeight.normal,
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
    color: AppColors.customWhite,
  );

  /// Дата новости (акцентная)
  static const TextStyle newsDate = TextStyle(
    fontSize: AppFontSizes.small,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.customStyle,
  );

  // ==================== КНОПКИ ====================
  /// Текст ElevatedButton / OutlinedButton
  static const TextStyle button = TextStyle(
    fontSize: AppFontSizes.medium,
    fontWeight: FontWeight.w600,
  );

  // ==================== ПЛЕЕР ====================

  // "СЕЙЧАС ИГРАЕТ" (маленький, разреженный, серый)
  static final TextStyle playerHeader = TextStyle(
    fontSize: AppFontSizes.small, // 10
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2, // Широкое расстояние между буквами
    color: AppColors.customWhite.withValues(alpha: 0.5),
  );

  // Название трека (крупное, жирное, белое)
  static const TextStyle playerTrackTitle = TextStyle(
    fontSize: AppFontSizes.playerTitle, // 18 (22 в некомпактном режиме)
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5, // Немного сжимаем буквы для плотности
    color: AppColors.customWhite,
    height: 1.1,
  );

  // Исполнитель (средний, серый)
  static final TextStyle playerTrackArtist = TextStyle(
    fontSize: AppFontSizes.smallMedium, // 12
    fontWeight: FontWeight.w400,
    color: AppColors.customWhite.withValues(alpha: 0.6),
  );
}
