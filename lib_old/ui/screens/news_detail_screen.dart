import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/models/news.dart';
import 'package:jrrplayerapp/widgets/custom_app_bar.dart';

class NewsDetailScreen extends StatelessWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.customBackgr,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leadingIcon: Icons.arrow_back,
              onLeadingTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.date,
                      style: AppTextStyles.small
                          .copyWith(color: AppColors.customStyle),
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
                            height: 120,
                            color: AppColors.surfaceMuted,
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
                              color: AppColors.surfaceMuted,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.customStyle,
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
                      child: Html(
                        data: news.description,
                        style: {
                          "b": Style(fontWeight: FontWeight.w400),
                          "strong": Style(fontWeight: FontWeight.w400),
                          "h1": Style(fontWeight: FontWeight.w400),
                          "h2": Style(fontWeight: FontWeight.w400),
                          "h3": Style(fontWeight: FontWeight.w400),
                          "h4": Style(fontWeight: FontWeight.w400),
                        },
                      ),
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