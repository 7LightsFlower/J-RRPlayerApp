import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_strings.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/widgets/audio_player_widget.dart';
import 'package:jrrplayerapp/ui/screens/enlarged_tabs_screen.dart';
import 'package:jrrplayerapp/widgets/animated_radio_button.dart';
import 'package:jrrplayerapp/widgets/app_bottom_nav.dart';
import 'package:jrrplayerapp/widgets/custom_app_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  bool _isInitialized = false;
  int _currentNavIndex = 0;
  late AnimationController _pulseController;
  // ignore: unused_field
  late Animation<double> _pulseAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeAsync();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeAsync() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnlargedTabsScreen(initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildAppDrawer(),
      body: SafeArea(
        // В портрете нижний отступ делает сама AppBottomNav —
        // её фон уходит под системную панель Android (без серой полосы)
        bottom: MediaQuery.sizeOf(context).width >
            MediaQuery.sizeOf(context).height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final Size screen = MediaQuery.of(context).size;
            final bool isWide = screen.width > screen.height;

            if (isWide) {
              // Landscape → Row: rail справа, контент слева
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        CustomAppBar(
                          leadingIcon: Icons.menu,
                          onLeadingTap: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                        ),
                        Expanded(
                          child: _withWebsiteLink(
                            OrientationBuilder(
                              builder: (context, orientation) =>
                                  _buildLandscapeLayout(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppBottomNav(
                    currentIndex: _currentNavIndex,
                    onTap: _onNavTap,
                  ),
                ],
              );
            }

            // Portrait → Column: nav внизу
            return Column(
              children: [
                CustomAppBar(
                  leadingIcon: Icons.menu,
                  onLeadingTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: _withWebsiteLink(
                    OrientationBuilder(
                      builder: (context, orientation) =>
                          _buildPortraitLayout(),
                    ),
                  ),
                ),
                AppBottomNav(
                  currentIndex: _currentNavIndex,
                  onTap: _onNavTap,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==================== ССЫЛКА НА САЙТ ====================

  /// Кладёт ссылку на сайт поверх контента в левом верхнем углу,
  /// прямо под кнопкой меню. Места по высоте не занимает,
  /// поэтому размер логотипа не меняется.
  Widget _withWebsiteLink(Widget content) {
    return Stack(
      children: [
        Positioned.fill(child: content),
        const Positioned(
          top: 0,
          // Выравнивание по кнопке меню в CustomAppBar (отступ 20)
          left: AppSpacing.smallPlus,
          child: _WebsiteLink(),
        ),
      ],
    );
  }

  // ==================== PORTRAIT LAYOUT ====================

  Widget _buildPortraitLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;

        // Плеер берёт столько, сколько ему нужно, логотип — всё остальное.
        // Если места мало, логотип уменьшается (FittedBox), а не наезжает
        // на кнопку Play. Раньше на невысоких экранах контент не помещался,
        // spaceEvenly не находил свободного места и элементы «слипались».
        return Column(
          children: [
            Expanded(
              child: Padding(
                // Меньше отступов → больше места для логотипа.
                // Снизу 16 + собственный запас виджета под пульсацию (~13)
                // всё ещё хватает, чтобы кольцо не касалось свечения Play.
                padding: const EdgeInsets.only(
                  top: AppSpacing.xxsmall,
                  bottom: AppSpacing.small,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedRadioButton(
                      screenWidth: availableWidth,
                    ),
                  ),
                ),
              ),
            ),
            const AudioPlayerWidget(),
            const SizedBox(height: AppSpacing.xsmall),
          ],
        );
      },
    );
  }

  // ==================== LANDSCAPE LAYOUT ====================
  Widget _buildLandscapeLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;
        final double leftWidth = availableWidth * 0.4;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.xsmall,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT: logo
              SizedBox(
                width: leftWidth,
                height: availableHeight,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRadioButton(screenWidth: leftWidth),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              // RIGHT: player
              const Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: AudioPlayerWidget(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== APP DRAWER ====================
  Widget _buildAppDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.appBarBorder),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.radio,
                  color: AppColors.customStyle,
                  size: AppIconSizes.drawerHeader,
                ),
                SizedBox(height: AppSpacing.xsmall),
                Text(AppStrings.radioName, style: AppTextStyles.mediumBold),
              ],
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: AppColors.iconSecondary),
            title: const Text(AppStrings.menuAbout, style: AppTextStyles.medium),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.iconSecondary),
            title:
                const Text(AppStrings.menuSettings, style: AppTextStyles.medium),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==================== WEBSITE LINK ====================
/// Иконка «веб» + адрес сайта радио. По нажатию открывает сайт в браузере.
class _WebsiteLink extends StatelessWidget {
  const _WebsiteLink();

  static final Uri _url = Uri.parse(AppStrings.wwweblinkUrl);

  Future<void> _open() async {
    await launchUrl(_url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.customTransp,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xsmall),
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxsmall,
            vertical: AppSpacing.xxsmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language,
                color: AppColors.customStyle,
                size: AppIconSizes.small,
              ),
              const SizedBox(width: AppSpacing.xxsmall),
              Text(_url.host, style: AppTextStyles.badge), // jrock.ru
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== EQUALIZER PAINTER ====================
class EqualizerPainter extends CustomPainter {
  final Color color;

  EqualizerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const int barCount = 15;
    final double spacing = size.width / (barCount * 2);
    final double startX = spacing;
    final double bottomY = size.height - size.height * 0.08;

    for (int i = 0; i < barCount; i++) {
      final double x = startX + i * (spacing * 2);
      final double height =
          size.height * (0.15 + (i % 5) * 0.08 + (i % 3) * 0.05);
      final double startY = bottomY - height;

      canvas.drawLine(Offset(x, startY), Offset(x, bottomY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant EqualizerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ==================== ABOUT SCREEN ====================
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.menuAbout)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.small),
            Container(
              width: AppDimens.aboutLogo,
              height: AppDimens.aboutLogo,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.appBarBackground,
                border: Border.all(
                  color: AppColors.customStyle.withValues(alpha: 0.5),
                  width: AppDimens.aboutLogoBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.customStyle.withValues(alpha: 0.2),
                    blurRadius: AppDimens.aboutLogoBlur,
                    spreadRadius: AppDimens.aboutLogoSpread,
                  ),
                ],
              ),
              child: const Icon(
                Icons.radio,
                size: AppIconSizes.logo,
                color: AppColors.customStyle,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),

            // Название радио — крупный заголовок
            const Text(
              AppStrings.appName,
              style: AppTextStyles.large,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xsmall),

            // Версия — приглушённый
            Text(
              '${AppStrings.aboutVersionLabel} ${AppStrings.appVersion}',
              style: AppTextStyles.mediumMuted,
            ),
            const SizedBox(height: AppSpacing.large),

            // Описание — читаемый абзац
            Text(
              AppStrings.aboutDescription,
              style: AppTextStyles.mediumMutedBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.large),
            const Divider(),
            const SizedBox(height: AppSpacing.small),
            _buildInfoRow(
              Icons.copyright,
              AppStrings.aboutCopyright,
              AppStrings.radioName,
            ),
            const SizedBox(height: AppSpacing.smallMinus),
            _buildInfoRow(
              Icons.code,
              AppStrings.aboutDeveloper,
              AppStrings.aboutDeveloperName,
            ),
            const SizedBox(height: AppSpacing.smallMinus),
            _buildInfoRow(
              Icons.web,
              AppStrings.aboutWebsite,
              AppStrings.wwweblinkUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.customStyle, size: AppIconSizes.infoRow),
        const SizedBox(width: AppSpacing.smallMinus),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.smallMuted),
              const SizedBox(height: AppSpacing.xxxsmall),
              Text(value, style: AppTextStyles.medium),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== SETTINGS SCREEN ====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Значения по умолчанию
  static const bool _defAutoPlay = false;
  static const bool _defNotifications = true;
  static const bool _defHighQuality = true;
  static const double _defVolume = 0.7;

  bool _autoPlayOnStart = _defAutoPlay;
  bool _showNotifications = _defNotifications;
  bool _highQualityStream = _defHighQuality;
  double _defaultVolume = _defVolume;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.menuSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xsmall),
        children: [
          _buildSectionHeader(AppStrings.settingsPlayback),
          SwitchListTile(
            secondary: const Icon(
              Icons.play_circle_outline,
              color: AppColors.customStyle,
            ),
            title: const Text(
              AppStrings.settingsAutoPlay,
              style: AppTextStyles.medium,
            ),
            subtitle: Text(
              AppStrings.settingsAutoPlayHint,
              style: AppTextStyles.smallMuted,
            ),
            value: _autoPlayOnStart,
            onChanged: (value) => setState(() => _autoPlayOnStart = value),
          ),
          SwitchListTile(
            secondary: const Icon(
              Icons.high_quality,
              color: AppColors.customStyle,
            ),
            title: const Text(
              AppStrings.settingsHighQuality,
              style: AppTextStyles.medium,
            ),
            subtitle: Text(
              AppStrings.settingsHighQualityHint,
              style: AppTextStyles.smallMuted,
            ),
            value: _highQualityStream,
            onChanged: (value) => setState(() => _highQualityStream = value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
              vertical: AppSpacing.smallMinus,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.volume_up,
                      color: AppColors.customStyle,
                      size: AppIconSizes.infoRow,
                    ),
                    const SizedBox(width: AppSpacing.smallMinus),
                    const Text(
                      AppStrings.settingsDefaultVolume,
                      style: AppTextStyles.medium,
                    ),
                    const Spacer(),
                    Text(
                      '${(_defaultVolume * 100).round()}%',
                      style: AppTextStyles.mediumMuted,
                    ),
                  ],
                ),
                Slider(
                  value: _defaultVolume,
                  onChanged: (value) => setState(() => _defaultVolume = value),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader(AppStrings.settingsNotifications),
          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_outlined,
              color: AppColors.customStyle,
            ),
            title: const Text(
              AppStrings.settingsShowNotifications,
              style: AppTextStyles.medium,
            ),
            subtitle: Text(
              AppStrings.settingsShowNotificationsHint,
              style: AppTextStyles.smallMuted,
            ),
            value: _showNotifications,
            onChanged: (value) => setState(() => _showNotifications = value),
          ),
          const Divider(),
          _buildSectionHeader(AppStrings.settingsReset),
          ListTile(
            leading: const Icon(Icons.restore, color: AppColors.customStyle),
            title: const Text(
              AppStrings.settingsResetTitle,
              style: AppTextStyles.medium,
            ),
            subtitle: Text(
              AppStrings.settingsResetHint,
              style: AppTextStyles.smallMuted,
            ),
            onTap: _resetSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.small,
        AppSpacing.small,
        AppSpacing.small,
        AppSpacing.xsmall,
      ),
      child: Text(title.toUpperCase(), style: AppTextStyles.smallAccent),
    );
  }

  void _resetSettings() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.settingsResetConfirmTitle),
        content: const Text(AppStrings.settingsResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _autoPlayOnStart = _defAutoPlay;
                _showNotifications = _defNotifications;
                _highQualityStream = _defHighQuality;
                _defaultVolume = _defVolume;
              });
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.settingsResetDone),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              AppStrings.settingsResetConfirm,
              style: AppTextStyles.mediumAccent,
            ),
          ),
        ],
      ),
    );
  }
}
