import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/ui/screens/articles_feed_screen.dart';
import 'package:jrrplayerapp/ui/screens/news_feed_screen.dart';
import 'package:jrrplayerapp/ui/screens/podcast_list_screen.dart';
import 'package:jrrplayerapp/widgets/app_bottom_nav.dart';
import 'package:jrrplayerapp/widgets/custom_app_bar.dart';

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
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leadingIcon: Icons.arrow_back,
              onLeadingTap: () => Navigator.pop(context),
            ),
            Expanded(
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
          ],
        ),
      ),
    );
  }
}