import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/constants/app_strings.dart';
import 'package:jrrplayerapp/services/audio_player_service.dart';

/// Единый трёхкнопочный AppBar.
///
///   [menu/back]   РАДИО J-ROCK 📻   [wifi]
///
/// Слева — квадратная кнопка (по умолчанию `menu`, для вложенных экранов
/// удобно передать `Icons.arrow_back`). Справа — квадратная кнопка wifi,
/// открывающая диалог статуса сигнала.
class CustomAppBar extends StatelessWidget {
  final IconData leadingIcon;
  final VoidCallback? onLeadingTap;

  const CustomAppBar({
    super.key,
    this.leadingIcon = Icons.menu,
    this.onLeadingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSquareIconButton(
            icon: leadingIcon,
            onTap: onLeadingTap ?? () {},
          ),
          Row(
            children: [
              const Text(
                AppStrings.appName,
                style: TextStyle(
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
            onTap: () => _showSignalStatus(context),
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

  void _showSignalStatus(BuildContext context) {
    final audioService = context.read<AudioPlayerService>();
    final hasConnection = audioService.hasNetworkConnection ?? false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}