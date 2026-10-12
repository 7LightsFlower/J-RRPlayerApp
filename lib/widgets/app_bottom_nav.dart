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
        final double width = constraints.maxWidth;
        final double iconSize = (width * 0.065).clamp(20.0, 28.0);
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
              _navItem(
                icon: Icons.radio,
                label: AppStrings.articlesTab,
                index: 0,
                iconSize: iconSize,
                labelSize: labelSize,
              ),
              _navItem(
                icon: Icons.newspaper,
                label: AppStrings.newsTab,
                index: 1,
                iconSize: iconSize,
                labelSize: labelSize,
              ),
              _navItem(
                icon: Icons.mic,
                label: AppStrings.podcastsTab,
                index: 2,
                iconSize: iconSize,
                labelSize: labelSize,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    required double iconSize,
    required double labelSize,
  }) {
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
}
