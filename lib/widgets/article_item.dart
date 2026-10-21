// article_item.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_strings.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/models/article.dart';
import 'package:jrrplayerapp/ui/screens/articles_detail_screen.dart';

class ArticleItem extends StatelessWidget {
  final Article article;
  final String? categoryLabel;

  const ArticleItem({
    super.key,
    required this.article,
    this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final String category =
        categoryLabel ?? article.category ?? AppStrings.articleDefaultCategory;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smallMinus,
        vertical: AppSpacing.compact,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Material(
        color: AppColors.customTransp,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => _openArticleDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.smallMinus),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildThumbnail(),
                const SizedBox(width: AppSpacing.smallMinus),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        article.title,
                        style: AppTextStyles.mediumBold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Description
                      if (article.description.isNotEmpty &&
                          article.description != article.title) ...[
                        const SizedBox(height: AppSpacing.compact),
                        Text(
                          article.description,
                          style: AppTextStyles.podcastMetaTall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xsmall),

                      // Date + category badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            article.date,
                            style: AppTextStyles.smallMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xxsmall),
                          _buildCategoryBadge(category),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xxsmall),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.customWhite,
                  size: AppIconSizes.appBarButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== THUMBNAIL ====================
  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: SizedBox(
        width: AppDimens.articleThumbnail,
        height: AppDimens.articleThumbnail,
        child: article.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: article.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Center(
        child: Icon(
          Icons.article_outlined,
          color: AppColors.customStyle,
          size: AppIconSizes.large,
        ),
      ),
    );
  }

  // ==================== CATEGORY BADGE ====================
  Widget _buildCategoryBadge(String category) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _iconForCategory(category),
          color: AppColors.customStyle,
          size: AppIconSizes.xsmall,
        ),
        const SizedBox(width: AppSpacing.xxsmall),
        Flexible(
          child: Text(
            category.toUpperCase(),
            style: AppTextStyles.badge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _iconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('история')) return Icons.account_balance;
    if (c.contains('перевод')) return Icons.headphones;
    if (c.contains('между делом')) return Icons.menu_book;
    if (c.contains('музыкальн') && c.contains('новост')) {
      return Icons.article_outlined;
    }
    if (c.contains('новост')) return Icons.article_outlined;
    if (c.contains('всё просто') || c.contains('все просто')) {
      return Icons.lightbulb_outline;
    }
    if (c.contains('вопрос')) return Icons.help_outline;
    if (c.contains('видео')) return Icons.play_circle_outline;
    if (c.contains('станц')) return Icons.radio;
    if (c.contains('программ')) return Icons.mic_none;
    if (c.contains('статья') || c.contains('статьи')) {
      return Icons.article_outlined;
    }
    return Icons.label_outline;
  }

  void _openArticleDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(articleUrl: article.url),
      ),
    );
  }
}
