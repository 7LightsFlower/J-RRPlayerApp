import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/models/news.dart';

class NewsDetailScreen extends StatelessWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.customBackgr,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          news.title,
          style: AppTextStyles.appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              news.date,
              style: AppTextStyles.small
                  .copyWith(color: AppColors.customGreen),
            ),
            const SizedBox(height: 8),
            if (news.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  news.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: const Color(0xFF232A36),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.customGrey,
                        size: 48,
                      ),
                    ),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 200,
                      color: const Color(0xFF232A36),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.customGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],
            DefaultTextStyle(
              style: AppTextStyles.medium.copyWith(height: 1.5),
              child: Html(data: news.description),
            ),
          ],
        ),
      ),
    );
  }
}