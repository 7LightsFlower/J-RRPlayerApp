// lib/constants/app_sizes.dart

/// Централизованные размеры иконок.
class AppIconSizes {
  AppIconSizes._();

  /// 16 — мелкие иконки в тексте, chevron, inline-акценты
  static const double small = 16.0;

  /// 24 — стандартные иконки кнопок, действий
  static const double medium = 24.0;

  /// 32 — крупные иконки в списках, плейсхолдерах
  static const double large = 32.0;

  /// 48 — иллюстрации, крупные акценты
  static const double xlarge = 48.0;

  /// 64 — пустые состояния, большие иллюстрации
  static const double xxlarge = 64.0;
}

/// Опционально: отступы/скругления — тоже удобно держать здесь.
class AppSpacing {
  AppSpacing._();

  static const double small = 16.0;
  static const double infoRow  = 20.0;   // ← для infoRow в AboutScreen
  static const double medium = 24.0;
  static const double appBarButton = 22.0;  // ← для квадратных кнопок AppBar
  static const double large = 32.0;
  static const double drawerHeader = 36.0;   // ← для иконки радио в Drawer
  static const double xlarge = 48.0;
  static const double xxlarge = 64.0;      
  static const double emptyState = 80.0; // ← для пустых состояний (offline)

}