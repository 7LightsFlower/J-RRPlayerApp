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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Returns the correct tab body wrapped so it can live either under a
  /// bottom bar (portrait) or beside a left rail (landscape).
  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: const [
        ArticlesFeedScreen(),
        NewsFeedScreen(),
        PodcastListScreen(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.customBackgr,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F141E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          AppStrings.appName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.customStyle,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.customStyle,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: AppStrings.articlesTab),
            Tab(text: AppStrings.newsTab),
            Tab(text: AppStrings.podcastsTab),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final Size screen = MediaQuery.of(context).size;
          final bool isWide = screen.width > screen.height;

          final nav = AppBottomNav(
            currentIndex: _tabController.index,
            onTap: (index) => _tabController.animateTo(index),
          );

          if (isWide) {
            // Landscape → rail on the left, content on the right.
            return Row(
              children: [
                Expanded(child: _buildTabContent()),
                nav,
              ],
            );
          }

          // Portrait → bar at the bottom.
          return Column(
            children: [
              Expanded(child: _buildTabContent()),
              nav,
            ],
          );
        },
      ),
    );
  }
}