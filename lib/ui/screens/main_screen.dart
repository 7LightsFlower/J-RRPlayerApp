import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/widgets/audio_player_widget.dart';
import 'package:jrrplayerapp/constants/strings.dart';
import 'package:jrrplayerapp/widgets/radio_button_with_waves.dart';
import 'package:jrrplayerapp/ui/screens/enlarged_tabs_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isInitialized = false;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildSocialButton(String asset, String url, double buttonSize) {
    final double clampedSize = buttonSize.clamp(30.0, 60.0);
    return SizedBox(
      width: clampedSize,
      height: clampedSize,
      child: ElevatedButton(
        onPressed: () => _launchURL(url),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.customBackgr,
          foregroundColor: AppColors.customWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          padding: EdgeInsets.zero,
        ),
        child: SvgPicture.asset(
          asset,
          width: clampedSize,
          height: clampedSize,
          colorFilter: const ColorFilter.mode(AppColors.customWhite, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildSocialButtons(double buttonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialButton('assets/icon/icon_vkontakte.svg', AppStrings.vkontakteUrl, buttonSize),
        _buildSocialButton('assets/icon/icon_telegram.svg', AppStrings.telegramUrl, buttonSize),
        _buildSocialButton('assets/icon/icon_wwweblink.svg', AppStrings.wwweblinkUrl, buttonSize),
      ],
    );
  }

  // Top part (radio + player) – unchanged
  Widget _buildTopPart({required double availableWidth, required double availableHeight}) {
    return SizedBox(
      height: availableHeight * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: RadioButtonWithWaves(screenWidth: availableWidth),
          ),
          const AudioPlayerWidget(),
        ],
      ),
    );
  }

  // Build three icon buttons for Articles, News, Podcasts
  Widget _buildNavigationIcons({double iconSize = 36}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _navIcon(Icons.article, AppStrings.articlesTab, 0, iconSize),
        _navIcon(Icons.newspaper, AppStrings.newsTab, 1, iconSize),
        _navIcon(Icons.podcasts, AppStrings.podcastsTab, 2, iconSize),
      ],
    );
  }

  Widget _navIcon(IconData icon, String label, int index, double size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: AppColors.customWhite, size: size),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EnlargedTabsScreen(initialIndex: index),
              ),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: AppColors.customTransp,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.customWhite, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.customWhite,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeAsync();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.customTransp,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
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
    final bool showAppBar = kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.customBackgr,
        body: Center(child: CircularProgressIndicator(color: AppColors.customWhite)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.customBackgr,
      appBar: showAppBar
          ? AppBar(
              title: const Text(AppStrings.appName),
              backgroundColor: AppColors.customWhite,
              foregroundColor: AppColors.customBackgr,
            )
          : null,
      body: SafeArea(
        top: true,
        bottom: false,
        child: showAppBar
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final double availableWidth = constraints.maxWidth;
                  final double buttonSize = availableWidth * 0.08;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: _buildSocialButtons(buttonSize),
                      ),
                      _buildTopPart(
                        availableWidth: availableWidth,
                        availableHeight: constraints.maxHeight,
                      ),
                      const SizedBox(height: 8),
                      _buildNavigationIcons(iconSize: 36),
                      const Spacer(),
                    ],
                  );
                },
              )
            : OrientationBuilder(
                builder: (context, orientation) {
                  if (orientation == Orientation.landscape) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final double availableWidth = constraints.maxWidth;
                        final double availableHeight = constraints.maxHeight;
                        final double leftWidth = availableWidth * 0.4;
                        final double rightWidth = availableWidth * 0.6;
                        final double buttonSize = rightWidth * 0.10;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: leftWidth,
                              height: availableHeight,
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  RadioButtonWithWaves(screenWidth: leftWidth),
                                  const Expanded(
                                    child: AudioPlayerWidget(),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: availableHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: _buildSocialButtons(buttonSize),
                                    ),
                                    const Spacer(),
                                    _buildNavigationIcons(iconSize: 40),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final double availableWidth = constraints.maxWidth;
                        final double availableHeight = constraints.maxHeight;
                        final double buttonSize = availableWidth * 0.10;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: _buildSocialButtons(buttonSize),
                            ),
                            _buildTopPart(
                              availableWidth: availableWidth,
                              availableHeight: availableHeight,
                            ),
                            const SizedBox(height: 8),
                            _buildNavigationIcons(iconSize: 36),
                            const Spacer(),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
      ),
    );
  }
}
