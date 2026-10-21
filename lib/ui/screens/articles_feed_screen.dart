// lib/ui/screens/articles_feed_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_strings.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/models/article.dart';
import 'package:jrrplayerapp/widgets/article_item.dart';
import 'package:jrrplayerapp/ui/screens/articles_detail_screen.dart';

class ArticlesFeedScreen extends StatefulWidget {
  const ArticlesFeedScreen({super.key});

  @override
  State<ArticlesFeedScreen> createState() => _ArticlesFeedScreenState();
}

class _ArticlesFeedScreenState extends State<ArticlesFeedScreen> {
  List<Article> _articles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  int _currentPage = 1;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _loadedUrls = {};

  late final PageController _featuredController;
  Timer? _autoScrollTimer;
  int _featuredIndex = 0;
  static const int _featuredCount = 3;

  @override
  void initState() {
    super.initState();
    _featuredController = PageController(
      viewportFraction: AppDimens.featuredViewportFraction,
    );
    _loadArticles();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _featuredController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMorePages) {
        _loadMoreArticles();
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_featuredController.hasClients) return;
      final int total = _featuredCount.clamp(0, _articles.length);
      if (total <= 1) return;
      final int next = (_featuredIndex + 1) % total;
      _featuredController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
      _articles.clear();
      _loadedUrls.clear();
      _featuredIndex = 0;
    });
    _autoScrollTimer?.cancel();

    try {
      // getWithProxy сам добавляет CORS-прокси в вебе —
      // повторно оборачивать в proxyUrl не нужно (иначе двойной прокси).
      final response =
          await AppStrings.getWithProxy('${AppStrings.articlesFeedUrl}/');

      if (response.statusCode == 200) {
        _parseHtml(response.body, isFirstLoad: true);
        _startAutoScroll();
      } else {
        throw Exception('${AppStrings.serverError}: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = AppStrings.noInternet;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMorePages) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await AppStrings.getWithProxy(
        '${AppStrings.articlesFeedUrl}/p$nextPage',
      );

      if (response.statusCode == 200) {
        _parseHtml(response.body, isFirstLoad: false);
      } else {
        _hasMorePages = false;
      }
    } catch (_) {
      _hasMorePages = false;
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _parseHtml(String html, {required bool isFirstLoad}) {
    final document = parser.parse(html);
    var items = document.querySelectorAll('a.row');
    bool isNewStructure = items.isNotEmpty;
    if (items.isEmpty) {
      items = document.querySelectorAll('.qt-part-archive-item');
      isNewStructure = false;
    }

    final List<Article> newArticles = [];
    for (final el in items) {
      final article =
          isNewStructure ? _parseArticleNew(el) : _parseArticleOld(el);
      if (article != null && !_loadedUrls.contains(article.url)) {
        newArticles.add(article);
        _loadedUrls.add(article.url);
      }
    }

    final hasNext = document.querySelector('a[rel="next"]') != null ||
        document.querySelector('.next.page-numbers') != null ||
        document.querySelector('nav.pager a[href*="/p"]') != null;

    setState(() {
      if (isFirstLoad) {
        _articles = newArticles;
      } else {
        _articles.addAll(newArticles);
      }
      _currentPage = isFirstLoad ? 1 : _currentPage + 1;
      _hasMorePages = hasNext && newArticles.isNotEmpty;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  Article? _parseArticleNew(dom.Element row) {
    try {
      final href = row.attributes['href'];
      if (href == null || href.isEmpty) return null;

      final titleEl = row.querySelector('.rbody b');
      final title = titleEl?.text.trim();
      if (title == null || title.isEmpty) return null;

      String description = '';
      final bodyEl = row.querySelector('.rbody');
      if (bodyEl != null) {
        for (final span in bodyEl.children.whereType<dom.Element>()) {
          if (span.localName == 'span') {
            description = span.text.trim();
            break;
          }
        }
      }

      final dateEl = row.querySelector('.rdate');
      final date = dateEl?.text.trim() ?? _getCurrentDate();

      final kindEl = row.querySelector('.rkind .badge-kind');
      final category = kindEl?.text.trim() ?? '';

      final img = row.querySelector('img');
      String? imageUrl = img?.attributes['src'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        imageUrl = _normalizeUrl(imageUrl);
      }

      final finalImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
          ? imageUrl
          : AppStrings.articleFallbackImage;

      return Article(
        id: href,
        title: title.replaceAll(RegExp(r'\s+'), ' ').trim(),
        date: date,
        imageUrl: finalImageUrl,
        description: description,
        url: _normalizeUrl(href),
        category:
            category.isEmpty ? AppStrings.articleDefaultCategory : category,
      );
    } catch (e) {
      debugPrint('Ошибка парсинга (новая структура): $e');
      return null;
    }
  }

  Article? _parseArticleOld(dom.Element element) {
    try {
      final link = element.querySelector('h3.qt-title a');
      final title = link?.text.trim();
      final url = link?.attributes['href'];
      if (title == null || url == null || title.isEmpty || url.isEmpty) {
        return null;
      }

      final dateEl = element.querySelector('.qt-date');
      final date = dateEl?.text.trim() ?? _getCurrentDate();

      String? imageUrl;
      final img = element.querySelector('img[data-lazy-src]');
      imageUrl = img?.attributes['data-lazy-src'];
      if (imageUrl == null || imageUrl.isEmpty) {
        imageUrl = img?.attributes['src'];
      }
      if (imageUrl == null || imageUrl.isEmpty) {
        final bg = element.querySelector('.qt-header-bg');
        imageUrl = bg?.attributes['data-bgimage'];
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        imageUrl = _normalizeUrl(imageUrl);
      }

      final finalImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
          ? imageUrl
          : AppStrings.articleLegacyFallbackImage;

      return Article(
        id: url,
        title: title.replaceAll(RegExp(r'\s+'), ' ').trim(),
        date: date,
        imageUrl: finalImageUrl,
        description: title,
        url: _normalizeUrl(url),
        category: AppStrings.articleDefaultCategory,
      );
    } catch (e) {
      debugPrint('Ошибка парсинга (старая структура): $e');
      return null;
    }
  }

  String _normalizeUrl(String raw) {
    const base = AppStrings.wwweblinkUrl;
    var u = raw.trim();
    if ((u.startsWith('"') && u.endsWith('"')) ||
        (u.startsWith("'") && u.endsWith("'"))) {
      u = u.substring(1, u.length - 1);
    }
    if (u.startsWith('//')) return 'https:$u';
    if (u.startsWith('/')) return '$base$u';
    if (!u.startsWith('http')) return '$base/$u';
    return u;
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day} ${AppStrings.monthsGenitive[now.month]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoader();
    if (_error.isNotEmpty) return _buildError();
    if (_articles.isEmpty) {
      return Center(
        child: Text(AppStrings.articlesEmpty, style: AppTextStyles.smallMuted),
      );
    }

    final featured = _articles.take(_featuredCount).toList();
    final rest = _articles.skip(_featuredCount).toList();

    return RefreshIndicator(
      onRefresh: _loadArticles,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: AppSpacing.xsmall),
        children: [
          const SizedBox(height: AppSpacing.xsmall),

          // ---------- FEATURED PAGEVIEW ----------
          SizedBox(
            height: (MediaQuery.of(context).size.height *
                    AppDimens.featuredHeightFactor)
                .clamp(AppDimens.featuredMinHeight, AppDimens.featuredMaxHeight),
            child: PageView.builder(
              controller: _featuredController,
              itemCount: featured.length,
              onPageChanged: (i) => setState(() => _featuredIndex = i),
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.compact,
                  ),
                  child: _FeaturedArticleCard(article: featured[i]),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xsmall),

          _buildDots(featured.length),

          const SizedBox(height: AppSpacing.smallMinus),

          // ---------- "НОВЫЕ МАТЕРИАЛЫ" HEADER ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.articlesNewHeader,
                  style: AppTextStyles.small,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllArticlesScreen(articles: _articles),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Text(
                        AppStrings.articlesAll,
                        style: AppTextStyles.smallAccent,
                      ),
                      SizedBox(width: AppSpacing.xxsmall),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.customStyle,
                        size: AppIconSizes.smallPlus,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxsmall),

          // ---------- REST OF THE LIST ----------
          ...rest.map((a) => ArticleItem(article: a)),

          if (_hasMorePages)
            _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.smallPlus),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox(height: AppSpacing.smallPlus)
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.smallPlus),
              child: Center(
                child: Text(
                  AppStrings.articlesNoMore,
                  style: AppTextStyles.smallMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool active = i == _featuredIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxsmall),
          width: active ? AppDimens.dotActive : AppDimens.dot,
          height: active ? AppDimens.dotActive : AppDimens.dot,
          decoration: BoxDecoration(
            color: active ? AppColors.customStyle : AppColors.dotInactive,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildLoader() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off,
            size: AppIconSizes.emptyState,
            color: AppColors.customGrey,
          ),
          const SizedBox(height: AppSpacing.smallPlus),
          Text(
            _error.isEmpty ? AppStrings.noInternetShort : _error,
            style: AppTextStyles.mediumMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.smallPlus),
          ElevatedButton(
            onPressed: _loadArticles,
            child: const Text(AppStrings.refresh),
          ),
        ],
      ),
    );
  }
}

// ==================== FEATURED CARD ====================
class _FeaturedArticleCard extends StatelessWidget {
  final Article article;
  const _FeaturedArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(articleUrl: article.url),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: article.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.surfaceMuted),
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.surfaceMuted),
            ),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.gradientDarkStrong,
                    AppColors.gradientDarkMedium,
                    AppColors.customTransp,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),

            Positioned(
              top: AppSpacing.smallMinus,
              right: AppSpacing.smallMinus,
              child: Container(
                width: AppDimens.overlayButton,
                height: AppDimens.overlayButton,
                decoration: const BoxDecoration(
                  color: AppColors.overlayDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_border,
                  color: AppColors.customWhite,
                  size: AppIconSizes.appBarButton,
                ),
              ),
            ),

            Positioned(
              left: AppSpacing.small,
              right: AppSpacing.small,
              bottom: AppSpacing.small,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (article.category ?? AppStrings.articleDefaultCategory)
                        .toUpperCase(),
                    style: AppTextStyles.smallAccent,
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  Text(
                    article.title,
                    style: AppTextStyles.mediumBold,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xsmall),
                  if (article.description.isNotEmpty)
                    Text(
                      article.description,
                      style: AppTextStyles.smallMutedTall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSpacing.smallMinus),
                  Row(
                    children: [
                      Text(article.date, style: AppTextStyles.smallMuted),
                      const Spacer(),
                      const Row(
                        children: [
                          Text(
                            AppStrings.readMore,
                            style: AppTextStyles.smallAccent,
                          ),
                          SizedBox(width: AppSpacing.xxsmall),
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.customStyle,
                            size: AppIconSizes.small,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ALL ARTICLES SCREEN ====================
class AllArticlesScreen extends StatelessWidget {
  final List<Article> articles;
  const AllArticlesScreen({super.key, required this.articles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(AppStrings.articlesAll),
      ),
      body: articles.isEmpty
          ? Center(
              child: Text(
                AppStrings.articlesNothingYet,
                style: AppTextStyles.mediumMuted,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xsmall),
              itemCount: articles.length,
              itemBuilder: (context, i) => ArticleItem(article: articles[i]),
            ),
    );
  }
}
