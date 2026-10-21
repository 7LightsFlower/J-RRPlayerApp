import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_strings.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size screen = MediaQuery.of(context).size;
        final bool isWide = screen.width > screen.height;

        if (isWide) {
          return _buildSideRail(context);
        }
        return _buildBottomBar(context, constraints.maxWidth);
      },
    );
  }

  // ==================== BOTTOM BAR (portrait) ====================
  Widget _buildBottomBar(BuildContext context, double width) {
    // Размеры масштабируются от ширины экрана в заданных пределах
    final double iconSize = (width * 0.065)
        .clamp(AppIconSizes.mediumPlus, AppIconSizes.mediumLarge);
    final double labelSize = (width * 0.028)
        .clamp(AppDimens.navLabelMin, AppDimens.navLabelMax);
    final double verticalPadding =
        (width * 0.03).clamp(AppSpacing.xsmall, AppSpacing.smallMid);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: AppSpacing.xsmall,
      ),
      decoration: const BoxDecoration(
        color: AppColors.appBarBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.appBarBorder,
            width: AppDimens.dividerThickness,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bottomItem(Icons.radio, AppStrings.articlesTab, 0, iconSize, labelSize),
          _bottomItem(Icons.newspaper, AppStrings.newsTab, 1, iconSize, labelSize),
          _bottomItem(Icons.mic, AppStrings.podcastsTab, 2, iconSize, labelSize),
        ],
      ),
    );
  }

  Widget _bottomItem(
    IconData icon,
    String label,
    int index,
    double iconSize,
    double labelSize,
  ) {
    final bool isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap?.call(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxsmall),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.customStyle : AppColors.iconInactive,
                size: iconSize,
              ),
              const SizedBox(height: AppSpacing.xxsmall),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (isActive
                          ? AppTextStyles.navActive
                          : AppTextStyles.navInactive)
                      .copyWith(fontSize: labelSize),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SIDE RAIL (landscape) ====================
  Widget _buildSideRail(BuildContext context) {
    return Container(
      width: AppDimens.navRailWidth,
      decoration: const BoxDecoration(
        color: AppColors.appBarBackground,
        border: Border(
          left: BorderSide(
            color: AppColors.appBarBorder,
            width: AppDimens.dividerThickness,
          ),
        ),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _sideItem(Icons.radio, AppStrings.articlesTab, 0),
            _sideItem(Icons.newspaper, AppStrings.newsTab, 1),
            _sideItem(Icons.mic, AppStrings.podcastsTab, 2),
          ],
        ),
      ),
    );
  }

  Widget _sideItem(IconData icon, String label, int index) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap?.call(index),
      child: Container(
        width: AppDimens.navRailItemWidth,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.smallMid),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.customStyle.withValues(alpha: 0.12)
              : AppColors.customTransp,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.customStyle : AppColors.iconInactive,
              size: AppIconSizes.mediumPlus,
            ),
            const SizedBox(height: AppSpacing.compact),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: isActive
                  ? AppTextStyles.navActive
                  : AppTextStyles.navInactive,
            ),
          ],
        ),
      ),
    );
  }
}
