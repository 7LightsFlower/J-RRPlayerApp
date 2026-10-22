// lib/constants/app_sizes.dart

/// Централизованные размеры иконок.
class AppIconSizes {
  AppIconSizes._();

  /// 14 — иконки в бейджах категорий
  static const double xsmall = 14.0;

  /// 16 — мелкие иконки в тексте, inline-акценты
  static const double small = 16.0;

  /// 18 — chevron рядом с текстовой ссылкой, иконка радио в AppBar
  static const double smallPlus = 18.0;

  /// 20 — иконки в строках информации / настроек
  static const double infoRow = 20.0;

  /// 22 — квадратные кнопки AppBar, кнопки поверх карточек
  static const double appBarButton = 22.0;

  /// 24 — стандартные иконки кнопок, действий
  static const double medium = 24.0;

  /// 26 — иконки навигации, громкости
  static const double mediumPlus = 26.0;

  /// 30 — play/pause в карточке подкаста, макс. иконка нижней навигации
  static const double mediumLarge = 30.0;

  /// 32 — крупные иконки в списках, плейсхолдерах
  static const double large = 32.0;

  /// 36 — иконка радио в шапке Drawer
  static const double drawerHeader = 36.0;

  /// 48 — иллюстрации, крупные акценты
  static const double xlarge = 48.0;

  /// 56 — логотип на экране «О радио»
  static const double logo = 56.0;

  /// 64 — пустые состояния, большие иллюстрации
  static const double xxlarge = 64.0;

  /// 80 — пустые состояния / ошибки (offline)
  static const double emptyState = 80.0;
}

/// Отступы.
class AppSpacing {
  AppSpacing._();

  static const double xxxsmall = 2.0;
  static const double xxsmall = 4.0;
  static const double compact = 6.0;
  static const double xsmall = 8.0;
  static const double xsmallPlus = 10.0;
  static const double smallMinus = 12.0;
  static const double smallMid = 14.0;
  static const double small = 16.0;
  static const double smallPlus = 20.0;
  static const double medium = 24.0;
  static const double large = 32.0;
  static const double xlarge = 48.0;
  static const double xxlarge = 64.0;

  // ---- Устаревшие: это размеры иконок, не отступы ----
  @Deprecated('Use AppIconSizes.infoRow')
  static const double infoRow = AppIconSizes.infoRow;
  @Deprecated('Use AppIconSizes.appBarButton')
  static const double appBarButton = AppIconSizes.appBarButton;
  @Deprecated('Use AppIconSizes.drawerHeader')
  static const double drawerHeader = AppIconSizes.drawerHeader;
  @Deprecated('Use AppIconSizes.emptyState')
  static const double emptyState = AppIconSizes.emptyState;
}

/// Скругления.
class AppRadius {
  AppRadius._();

  /// 8 — обложки подкастов, картинки в ленте новостей
  static const double xsmall = 8.0;

  /// 10 — картинки в деталях новости, обложка в плеере, превью статей
  static const double small = 10.0;

  /// 12 — карточки списков, кнопки AppBar, пункты навигации
  static const double card = 12.0;

  /// 14 — featured-карточки
  static const double medium = 14.0;
}

/// Прочие фиксированные размеры элементов.
class AppDimens {
  AppDimens._();

  // ---- Общее ----
  static const double dividerThickness = 1.0;
  static const double sliderTrackHeight = 4.0;
  static const double progressStroke = 2.0;

  /// Маленький спиннер внутри кнопок / картинок
  static const double smallSpinner = 20.0;

  // ---- AppBar ----
  /// Квадратная кнопка в CustomAppBar
  static const double appBarButton = 44.0;

  // ---- Навигация ----
  static const double navRailWidth = 88.0;
  static const double navRailItemWidth = 72.0;
  static const double navLabelMin = 9.0;
  static const double navLabelMax = 12.0;

  // ---- Featured-карусель статей ----
  static const double featuredHeightFactor = 0.38; // доля высоты экрана
  static const double featuredMinHeight = 200.0;
  static const double featuredMaxHeight = 340.0;
  static const double featuredViewportFraction = 0.92;

  /// Круглая кнопка поверх картинки (закладка)
  static const double overlayButton = 40.0;

  // ---- Индикаторы карусели ----
  static const double dot = 8.0;
  static const double dotActive = 10.0;

  // ---- Статьи / новости ----
  static const double articleThumbnail = 96.0;
  static const double newsImageAspectRatio = 16 / 9;

  // ---- Логотип «О радио» ----
  static const double aboutLogo = 120.0;
  static const double aboutLogoBorder = 2.0;
  static const double aboutLogoBlur = 30.0;
  static const double aboutLogoSpread = 4.0;

  // ---- Изображения ----
  static const double imageErrorHeight = 120.0;
  static const double imageLoadingHeight = 200.0;

  // ---- Большая кнопка радио ----
  /// Размер кнопки относительно доступной ширины
  static const double radioButtonFactor = 0.5;

  // ---- Плеер ----
  static const double playerMaxHeightFactor = 0.6; // доля высоты экрана
  /// Компактный плеер, если 60% высоты экрана меньше этого значения
  /// (≈ экраны ниже 700 pt, напр. iPhone 8 / SE) — тогда логотип
  /// на главном экране остаётся полного размера
  static const double playerCompactThreshold = 420.0;
  static const double playerPlayButton = 84.0;
  static const double playerPlayButtonCompact = 64.0;
  static const double playerSkipIcon = 38.0;
  static const double playerSkipIconCompact = 30.0;
  static const double playerCover = 88.0;
  static const double playerCoverCompact = 64.0;
  static const double playerGlowBlur = 20.0;
  static const double playerGlowSpread = 2.0;
  static const double volumeTrackHeight = 8.0;
  static const double volumeThumbRadius = 10.0;
  static const double volumeRightInset = 40.0;

  // ---- Карточка подкаста ----
  static const double podcastCover = 76.0;
  static const double podcastPlayButton = 48.0;
  static const double podcastPlayBorder = 2.0;
  static const double podcastSliderTrack = 3.0;
  static const double podcastSliderThumb = 4.0;
  static const double podcastSliderOverlay = 12.0;
}
