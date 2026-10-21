import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_strings.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smallPlus,
        vertical: AppSpacing.smallMinus,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSquareIconButton(
            icon: leadingIcon,
            onTap: onLeadingTap ?? () {},
          ),
          Row(
            children: [
              const Text(AppStrings.appName, style: AppTextStyles.brandTitle),
              const SizedBox(width: AppSpacing.xsmall),
              Icon(
                Icons.radio,
                color: AppColors.customStyle.withValues(alpha: 0.8),
                size: AppIconSizes.smallPlus,
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
    Color iconColor = AppColors.customWhite,
  }) {
    return Container(
      width: AppDimens.appBarButton,
      height: AppDimens.appBarButton,
      decoration: BoxDecoration(
        color: AppColors.appBarBorder,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: AppIconSizes.appBarButton),
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
        title: const Text(
          AppStrings.signalStatusTitle,
          style: AppTextStyles.mediumBold,
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasConnection ? Icons.wifi : Icons.wifi_off,
              color: hasConnection ? AppColors.customStyle : AppColors.customRed,
            ),
            const SizedBox(width: AppSpacing.smallMinus),
            Text(
              hasConnection
                  ? AppStrings.signalConnected
                  : AppStrings.signalDisconnected,
              style: AppTextStyles.medium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }
}
