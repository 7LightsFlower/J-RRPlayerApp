import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:provider/provider.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/widgets/audio_player_widget.dart';
import 'package:jrrplayerapp/constants/strings.dart';
import 'package:jrrplayerapp/ui/screens/enlarged_tabs_screen.dart';
import 'package:jrrplayerapp/services/audio_player_service.dart';
import 'package:jrrplayerapp/widgets/radio_button_with_waves.dart';
import 'package:jrrplayerapp/widgets/app_bottom_nav.dart';

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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.customTransp,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
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

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.customBackgr,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.customStyle),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.customBackgr,
      drawer: _buildAppDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final Size screen = MediaQuery.of(context).size;
            final bool isWide = screen.width > screen.height;

            if (isWide) {
              // Landscape → Row: rail слева, контент справа
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildCustomAppBar(),
                        Expanded(
                          child: OrientationBuilder(
                            builder: (context, orientation) =>
                                _buildLandscapeLayout(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppBottomNav(
                    currentIndex: _currentNavIndex,
                    onTap: (index) {
                      setState(() => _currentNavIndex = index);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EnlargedTabsScreen(initialIndex: index),
                        ),
                      );
                    },
                  ),

                ],
              );
            }

            // Portrait → Column: всё как было, nav внизу
            return Column(
              children: [
                _buildCustomAppBar(),
                Expanded(
                  child: OrientationBuilder(
                    builder: (context, orientation) => _buildPortraitLayout(),
                  ),
                ),
                AppBottomNav(
                  currentIndex: _currentNavIndex,
                  onTap: (index) {
                    setState(() => _currentNavIndex = index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EnlargedTabsScreen(initialIndex: index),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==================== PORTRAIT LAYOUT ====================
  Widget _buildPortraitLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              RadioButtonWithWaves(screenWidth: availableWidth),
              const SizedBox(height: 12),
              const AudioPlayerWidget(),
              const SizedBox(height: 12),
            ],
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT: logo + live indicator, wrapped in scroll so it never overflows
              SizedBox(
                width: leftWidth,
                height: availableHeight,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: availableHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioButtonWithWaves(screenWidth: leftWidth),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // RIGHT: audio player, always scrollable + bounded
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
  // ==================== APP BAR ====================
  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSquareIconButton(
            icon: Icons.menu,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Row(
            children: [
              Text(
                AppStrings.appName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSizes.medium,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.radio,
                color: AppColors.customStyle.withValues(alpha: 0.8),
                size: 18,
              ),
            ],
          ),
          _buildSquareIconButton(
            icon: Icons.wifi,
            iconColor: AppColors.customStyle,
            onTap: _showSignalStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildSquareIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1C212B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 22),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // ==================== APP DRAWER ====================
  Widget _buildAppDrawer() {
    return Drawer(
      backgroundColor: AppColors.appBarBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1C212B)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.radio, color: AppColors.customStyle, size: 36),
                SizedBox(height: 8),
                Text(
                  'Плеер Радио J-Rock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSizes.medium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white70),
            title: const Text(
              'О радио',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: const Text(
              'Настройки',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== SIGNAL STATUS ====================
  void _showSignalStatus() {
    final audioService = context.read<AudioPlayerService>();
    final hasConnection = audioService.hasNetworkConnection ?? false;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.appBarBackground,
        title: const Text(
          'Статус сигнала',
          style: TextStyle(color: Colors.white),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasConnection ? Icons.wifi : Icons.wifi_off,
              color: hasConnection ? AppColors.customStyle : Colors.redAccent,
            ),
            const SizedBox(width: 12),
            Text(
              hasConnection ? 'Подключено' : 'Нет соединения',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
      backgroundColor: AppColors.customBackgr,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('О радио'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.appBarBackground,
                border: Border.all(
                  color: AppColors.customStyle.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.customStyle.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.radio,
                size: 56,
                color: AppColors.customStyle,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppFontSizes.large,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Версия 1.0.0',
              style: TextStyle(color: Colors.white54, fontSize: AppFontSizes.medium),
            ),
            const SizedBox(height: 32),
            const Text(
              'J-Rock Radio — онлайн-радиостанция, посвящённая '
              'Слушать, думать, жить\n'
              'Человеку нужно место, где можно остановиться и подумать.'
              'Без готовых ответов, правильных слов и необходимости соглашаться.'
              'Здесь музыка соседствует с разговорами о человеке, Библии, истории, науке и жизни. '
              'О том, что действительно важно, когда остаёшься один на один с собой. '
              'Можно просто слушать. А можно вместе искать свои ответы. ',
              style: TextStyle(
                color: Colors.white70,
                fontSize: AppFontSizes.medium,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Divider(color: Color(0xFF1C212B), thickness: 1),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.copyright, 'Все права защищены', 'Радио J-Rock'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.code, 'Разработчик', 'Команда Радио J-Rock'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.web, 'Сайт', 'рttps://jrock.ru'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.customStyle, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: AppFontSizes.small),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: AppFontSizes.medium),
              ),
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
  bool _autoPlayOnStart = false;
  bool _showNotifications = true;
  bool _highQualityStream = true;
  double _defaultVolume = 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.customBackgr,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader('Воспроизведение'),
          SwitchListTile(
            secondary: const Icon(
              Icons.play_circle_outline,
              color: AppColors.customStyle,
            ),
            title: const Text(
              'Автовоспроизведение',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Запускать радио при открытии приложения',
              style: TextStyle(color: Colors.white54, fontSize: AppFontSizes.small),
            ),
            value: _autoPlayOnStart,
            activeThumbColor: AppColors.customStyle,
            onChanged: (value) {
              setState(() {
                _autoPlayOnStart = value;
              });
            },
          ),
          SwitchListTile(
            secondary: const Icon(
              Icons.high_quality,
              color: AppColors.customStyle,
            ),
            title: const Text(
              'Высокое качество звука',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Использовать поток с более высоким битрейтом',
              style: TextStyle(color: Colors.white54, fontSize: AppFontSizes.small),
            ),
            value: _highQualityStream,
            activeThumbColor: AppColors.customStyle,
            onChanged: (value) {
              setState(() {
                _highQualityStream = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.volume_up,
                      color: AppColors.customStyle,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Громкость по умолчанию',
                      style: TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      '${(_defaultVolume * 100).round()}%',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.customStyle,
                    inactiveTrackColor: const Color(0xFF1C212B),
                    thumbColor: AppColors.customStyle,
                    overlayColor: AppColors.customStyle.withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _defaultVolume,
                    onChanged: (value) {
                      setState(() {
                        _defaultVolume = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1C212B), thickness: 1),
          _buildSectionHeader('Уведомления'),
          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_outlined,
              color: AppColors.customStyle,
            ),
            title: const Text(
              'Показывать уведомления',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Отображать информацию о треке в шторке',
              style: TextStyle(color: Colors.white54, fontSize: AppFontSizes.small),
            ),
            value: _showNotifications,
            activeThumbColor: AppColors.customStyle,
            onChanged: (value) {
              setState(() {
                _showNotifications = value;
              });
            },
          ),
          const Divider(color: Color(0xFF1C212B), thickness: 1),
          _buildSectionHeader('Сброс'),
          ListTile(
            leading: const Icon(
              Icons.restore,
              color: AppColors.customStyle,
            ),
            title: const Text(
              'Сбросить настройки',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Вернуть все параметры к значениям по умолчанию',
              style: TextStyle(color: Colors.white54, fontSize: AppFontSizes.small),
            ),
            onTap: _resetSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.customStyle,
          fontSize: AppFontSizes.small,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _resetSettings() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.appBarBackground,
        title: const Text(
          'Сбросить настройки?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Все параметры будут возвращены к значениям по умолчанию.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _autoPlayOnStart = false;
                _showNotifications = true;
                _highQualityStream = true;
                _defaultVolume = 0.7;
              });
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Настройки сброшены'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Сбросить',
              style: TextStyle(color: AppColors.customStyle),
            ),
          ),
        ],
      ),
    );
  }
}