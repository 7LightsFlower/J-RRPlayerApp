import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/ui/screens/articles_feed_screen.dart';
import 'package:jrrplayerapp/ui/screens/news_feed_screen.dart';
import 'package:jrrplayerapp/ui/screens/podcast_list_screen.dart';
import 'package:jrrplayerapp/widgets/app_bottom_nav.dart';
import 'package:jrrplayerapp/widgets/custom_app_bar.dart';

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
      body: SafeArea(
        // В портрете нижний отступ делает сама AppBottomNav —
        // её фон уходит под системную панель Android (без серой полосы)
        bottom: MediaQuery.sizeOf(context).width >
            MediaQuery.sizeOf(context).height,
        child: Column(
          children: [
            CustomAppBar(
              leadingIcon: Icons.arrow_back,
              onLeadingTap: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: LayoutBuilder(
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
            ),
          ],
        ),
      ),
    );
  }
}