import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/strings.dart';
import 'package:jrrplayerapp/ui/screens/articles_feed_screen.dart';
import 'package:jrrplayerapp/ui/screens/news_feed_screen.dart';
import 'package:jrrplayerapp/ui/screens/podcast_list_screen.dart';
import 'package:jrrplayerapp/widgets/app_bottom_nav.dart';

class EnlargedTabsScreen extends StatefulWidget {
  final int initialIndex;
  const EnlargedTabsScreen({super.key, this.initialIndex = 0});

  @override
  State<EnlargedTabsScreen> createState() => _EnlargedTabsScreenState();
}

class _EnlargedTabsScreenState extends State<EnlargedTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    // Rebuild when the tab changes (swipe or tap) so the bottom nav updates.
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.customBackgr,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        backgroundColor: AppColors.customWhite,
        foregroundColor: AppColors.customBlack,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.customStyle,
          unselectedLabelColor: AppColors.customBlack.withValues(alpha: 0.6),
          indicatorColor: AppColors.customStyle,
          tabs: const [
            Tab(text: AppStrings.articlesTab),
            Tab(text: AppStrings.newsTab),
            Tab(text: AppStrings.podcastsTab),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ArticlesFeedScreen(),
                NewsFeedScreen(),
                PodcastListScreen(),
              ],
            ),
          ),
          AppBottomNav(
            currentIndex: _tabController.index,
            onTap: (index) {
              _tabController.animateTo(index);
            },
          ),
        ],
      ),
    );
  }
}