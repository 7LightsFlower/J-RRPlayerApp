// article_item.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/models/article.dart';
import 'package:jrrplayerapp/ui/screens/articles_detail_screen.dart';

class ArticleItem extends StatelessWidget {
  final Article article;

  /// Optional: allows the caller to override the category shown.
  /// If null, we'll try to fall back to a sensible default.
  final String? categoryLabel;

  const ArticleItem({
    super.key,
    required this.article,
    this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
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

                // ---- TEXT BLOCK ----
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category (teal, uppercase, small)
                      Text(
                        (categoryLabel ?? _inferCategory()).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.customStyle,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title (white, bold)
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

                      // Description (grey, up to 2 lines) – only if different from title
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

                      // Date row (with clock icon for a "reading time" feel)
                      if (article.date.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 13,
                              color: Color(0xFF6E7787),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              article.date,
                              style: const TextStyle(
                                color: Color(0xFF6E7787),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ---- CHEVRON ----
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 24,
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
                placeholder: (context, url) => _placeholder(),
                errorWidget: (context, url, error) => _placeholder(),
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

  // ==================== CATEGORY FALLBACK ====================
  /// If you don't pass `categoryLabel`, we try to guess a sensible one.
  /// Override this method (or always pass `categoryLabel`) if your `Article`
  /// model has a real `category` field — then just return `article.category`.
  String _inferCategory() {
    // TODO: if Article has a 'category' or 'type' field, use it here:
    // return article.category;
    return 'Статья';
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