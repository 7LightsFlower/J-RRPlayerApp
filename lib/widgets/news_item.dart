import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/models/news.dart';
import 'package:jrrplayerapp/ui/screens/news_detail_screen.dart';

class NewsItem extends StatelessWidget {
  final News news;

  const NewsItem({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.customTransp,
      child: InkWell(
        onTap: () => _openNewsDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news.date,
                style: AppTextStyles.small
                    .copyWith(color: AppColors.customGreen),
              ),
              if (news.imageUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                Image.network(
                  news.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ],
              const SizedBox(height: 8),
              DefaultTextStyle(
                style: AppTextStyles.medium,
                child: Html(
                  data: news.description,
                  style: {
                    "b": Style(fontWeight: FontWeight.w400),
                    "strong": Style(fontWeight: FontWeight.w400),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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