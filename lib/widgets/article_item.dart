// article_item.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
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
    final String category = categoryLabel ?? article.category ?? 'Статья';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openArticleDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildThumbnail(),
                const SizedBox(width: 12),
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
                        const SizedBox(height: 6),
                        Text(
                          article.description,
                          style: AppTextStyles.podcastMeta.copyWith(
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Date + category badge row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            article.date,
                            style: AppTextStyles.smallMuted,
                          ),
                          const Spacer(),
                          _buildCategoryBadge(category),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 22,
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
    const double size = 96.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
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
          size: 32,
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
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          category.toUpperCase(),
          style: AppTextStyles.smallAccent.copyWith(letterSpacing: 0.6),
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