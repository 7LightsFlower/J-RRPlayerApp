import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/constants/strings.dart';
import 'package:jrrplayerapp/ui/screens/articles_feed_screen.dart';
import 'package:jrrplayerapp/ui/screens/news_feed_screen.dart';
import 'package:jrrplayerapp/ui/screens/podcast_list_screen.dart';
import 'package:jrrplayerapp/widgets/app_bottom_nav.dart';

class FullScreenTabs extends StatefulWidget {
  final TabController tabController;

  const FullScreenTabs({super.key, required this.tabController});

  @override
  State<FullScreenTabs> createState() => _FullScreenTabsState();
}

class _FullScreenTabsState extends State<FullScreenTabs>
    with SingleTickerProviderStateMixin {
  late TabController _fullScreenTabController;

  @override
  void initState() {
    super.initState();
    _fullScreenTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.tabController.index,
    );
    _fullScreenTabController.addListener(() {
      if (mounted) setState(() {});
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fullScreenTabController.dispose();
    super.dispose();
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _fullScreenTabController,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppStrings.appName,
          style: AppTextStyles.appBarTitle,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.appBarBackground,
            child: TabBar(
              controller: _fullScreenTabController,
              labelColor: AppColors.customStyle,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
              indicatorColor: AppColors.customStyle,
              labelStyle: AppTextStyles.tabActive,
              unselectedLabelStyle: AppTextStyles.tabInactive,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final Size screen = MediaQuery.of(context).size;
            final bool isWide = screen.width > screen.height;

            final nav = AppBottomNav(
              currentIndex: _fullScreenTabController.index,
              onTap: (index) => _fullScreenTabController.animateTo(index),
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
      ),
    );
  }
}