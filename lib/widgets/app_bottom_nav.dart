import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/strings.dart';

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
        // Landscape = width > height → switch to left rail.
        // We compare against MediaQuery so it also works when the parent
        // gives us a wide-but-short slot in a Column/Row.
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
    final double iconSize = (width * 0.065).clamp(26.0, 30.0);
    final double labelSize = (width * 0.028).clamp(9.0, 12.0);
    final double verticalPadding = (width * 0.03).clamp(8.0, 14.0);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F141E),
        border: Border(
          top: BorderSide(color: Color(0xFF1C212B), width: 1),
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
        onTap: () {
          if (isActive) return;
          onTap?.call(index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? AppColors.customStyle
                    : Colors.white.withValues(alpha: 0.5),
                size: iconSize,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.customStyle
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: labelSize,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
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
    // Fixed width — comfortable for icon + label.
    const double railWidth = 88.0;

    return Container(
      width: railWidth,
      decoration: const BoxDecoration(
        color: Color(0xFF0F141E),
        border: Border(
          // Border is now on the LEFT, since rail is on the right side.
          left: BorderSide(color: Color(0xFF1C212B), width: 1),
        ),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          // Buttons spread evenly along the full height with generous spacing.
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
      onTap: () {
        if (isActive) return;
        onTap?.call(index);
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.customStyle.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.customStyle
                  : Colors.white.withValues(alpha: 0.5),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive
                    ? AppColors.customStyle
                    : Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}