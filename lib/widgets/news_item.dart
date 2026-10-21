import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/models/news.dart';
import 'package:jrrplayerapp/ui/screens/news_detail_screen.dart';

class NewsItem extends StatelessWidget {
  final News news;

  const NewsItem({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final String title = news.title.trim();
    final String excerpt = _excerpt(news.description, title);

    return Material(
      color: AppColors.customTransp,
      child: InkWell(
        onTap: () => _openNewsDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.small),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(news.date, style: AppTextStyles.newsDate),
              if (news.imageUrl.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xsmall),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xsmall),
                  child: AspectRatio(
                    // единые пропорции для всех картинок
                    aspectRatio: AppDimens.newsImageAspectRatio,
                    child: Image.network(
                      news.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover, // заполняет рамку, обрезая края
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceMuted,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.customGrey,
                            size: AppIconSizes.large,
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.surfaceMuted,
                          child: const Center(
                            child: SizedBox(
                              width: AppDimens.smallSpinner,
                              height: AppDimens.smallSpinner,
                              child: CircularProgressIndicator(
                                strokeWidth: AppDimens.progressStroke,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xsmall),

              // Заголовок — как в карточке статьи (14, жирный, белый)
              Text(
                title.isNotEmpty ? title : excerpt,
                style: AppTextStyles.mediumBold,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Описание — как в карточке статьи (12, серый, 1.35)
              if (title.isNotEmpty && excerpt.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.compact),
                Text(
                  excerpt,
                  style: AppTextStyles.podcastMetaTall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Текст описания без повтора заголовка (в RSS описание часто
  /// начинается с того же предложения, что и заголовок).
  String _excerpt(String html, String title) {
    String text = _previewText(html, maxChars: 400);
    final String head =
        title.replaceAll(RegExp(r'(…|\.\.\.)$'), '').trim();
    if (head.isNotEmpty && text.startsWith(head)) {
      text = text
          .substring(head.length)
          .replaceFirst(RegExp(r'^[\s.,:;!?…–—-]+'), '');
    }
    return text;
  }

  String _previewText(String html, {int maxChars = 180}) {
    final text = html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars).trimRight()}…';
  }

  void _openNewsDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(news: news),
      ),
    );
  }
}
