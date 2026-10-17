import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
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
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          AppStrings.appName,
          style: AppTextStyles.appBarTitle,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: AppColors.appBarBackground,
            alignment: Alignment.center,
            child: IntrinsicWidth(
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                labelColor: AppColors.customStyle,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                indicatorColor: AppColors.customStyle,
                labelStyle: AppTextStyles.tabActive,
                unselectedLabelStyle: AppTextStyles.tabInactive,
                labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: AppStrings.articlesTab),
                  Tab(text: AppStrings.newsTab),
                  Tab(text: AppStrings.podcastsTab),
                ],
              ),
            ),
          ),
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
            return Row(
              children: [
                Expanded(child: _buildTabContent()),
                nav,
              ],
            );
          }

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