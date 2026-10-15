// article_item.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
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
        color: const Color(0xFF1A1F29),
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
                // ---- IMAGE ----
                _buildThumbnail(),

                const SizedBox(width: 12),

                // ---- TEXT ----
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title (white, bold, up to 2 lines)
                      Text(
                        article.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Description
                      if (article.description.isNotEmpty &&
                          article.description != article.title) ...[
                        const SizedBox(height: 6),
                        Text(
                          article.description,
                          style: const TextStyle(
                            color: Color(0xFF9AA4B2),
                            fontSize: 13,
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
                          // Date (left)
                          Text(
                            article.date,
                            style: const TextStyle(
                              color: Color(0xFF6E7787),
                              fontSize: 12,
                            ),
                          ),

                          const Spacer(),

                          // Category badge (right)
                          _buildCategoryBadge(category),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                // Chevron
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
      color: const Color(0xFF232A36),
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
  /// Small teal badge with an icon and the category name in caps.
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
          style: const TextStyle(
            color: AppColors.customStyle,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  /// Picks a Material icon based on the category name.
  /// Falls back to a generic article icon if the category is unknown.
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

  // ==================== NAVIGATION ====================
  void _openArticleDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(articleUrl: article.url),
      ),
    );
  }
}