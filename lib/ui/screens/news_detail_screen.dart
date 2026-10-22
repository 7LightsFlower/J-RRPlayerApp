import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/constants/app_theme.dart';
import 'package:jrrplayerapp/models/news.dart';
import 'package:jrrplayerapp/widgets/custom_app_bar.dart';

class NewsDetailScreen extends StatelessWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  /// Теги, которые должны выглядеть как обычный текст
  static const List<String> _plainTags = [
    'p', 'span', 'div', 'li',
    'b', 'strong', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  ];

  /// Убирает жирное начертание из HTML: теги <b>/<strong> и inline
  /// `font-weight`. Одного style-map недостаточно — inline-стили его
  /// перебивают, из-за чего часть текста была жирной.
  static String _withoutBold(String html) => html
      .replaceAll(
        RegExp(r'</?(b|strong)(\s[^>]*)?>', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'font-weight\s*:\s*[^;"]+;?', caseSensitive: false),
        '',
      );

  /// Текст новости — тот же размер и шрифт, что в карточках «Актуальное»
  static Style _bodyStyle() => Style(
        fontFamily: AppTheme.fontFamily,
        fontSize: FontSize(AppFontSizes.medium),
        fontWeight: FontWeight.w400,
        lineHeight: const LineHeight(1.5),
        color: AppColors.customWhite,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leadingIcon: Icons.arrow_back,
              onLeadingTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.small),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(news.date, style: AppTextStyles.newsDate),
                    const SizedBox(height: AppSpacing.xsmall),

                    // Заголовок — как в карточке новости (14, жирный, белый)
                    if (news.title.trim().isNotEmpty) ...[
                      Text(news.title.trim(), style: AppTextStyles.mediumBold),
                      const SizedBox(height: AppSpacing.smallMinus),
                    ],
                    if (news.imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        child: Image.network(
                          news.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: AppDimens.imageErrorHeight,
                            color: AppColors.surfaceMuted,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.customGrey,
                                size: AppIconSizes.xlarge,
                              ),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: AppDimens.imageLoadingHeight,
                              color: AppColors.surfaceMuted,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: AppDimens.progressStroke,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.smallMid),
                    ],
                    Html(
                      data: _withoutBold(news.description),
                      style: {
                        'body': _bodyStyle(),
                        for (final tag in _plainTags)
                          tag: Style(
                            fontSize: FontSize(AppFontSizes.medium),
                            fontWeight: FontWeight.w400,
                          ),
                        'a': Style(color: AppColors.customStyle),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
