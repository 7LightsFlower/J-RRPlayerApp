// lib/ui/screens/articles_feed_screen.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/models/article.dart';
import 'package:jrrplayerapp/widgets/article_item.dart';
import 'package:jrrplayerapp/constants/strings.dart';
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
    _featuredController = PageController(viewportFraction: 0.92);
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
      const base = AppStrings.articlesFeedUrl;
      final url = kIsWeb ? AppStrings.proxyUrl('$base/') : '$base/';
      final response = await AppStrings.getWithProxy(url);

      if (response.statusCode == 200) {
        _parseHtml(response.body, isFirstLoad: true);
        _startAutoScroll();
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Нет подключения к интернету';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMorePages) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      const base = AppStrings.articlesFeedUrl;
      final url = kIsWeb
          ? AppStrings.proxyUrl('$base/p$nextPage')
          : '$base/p$nextPage';
      final response = await AppStrings.getWithProxy(url);

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
          : 'https://jrock.ru/favicon-32.png';

      return Article(
        id: href,
        title: title.replaceAll(RegExp(r'\s+'), ' ').trim(),
        date: date,
        imageUrl: finalImageUrl,
        description: description,
        url: _normalizeUrl(href),
        category: category.isEmpty ? 'Статья' : category,
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
          : 'https://jrock.pro/wp-content/uploads/2023/01/jrock-logo.png';

      return Article(
        id: url,
        title: title.replaceAll(RegExp(r'\s+'), ' ').trim(),
        date: date,
        imageUrl: finalImageUrl,
        description: title,
        url: _normalizeUrl(url),
        category: 'Статья',
      );
    } catch (e) {
      debugPrint('Ошибка парсинга (старая структура): $e');
      return null;
    }
  }

  String _normalizeUrl(String raw) {
    var u = raw.trim();
    if ((u.startsWith('"') && u.endsWith('"')) ||
        (u.startsWith("'") && u.endsWith("'"))) {
      u = u.substring(1, u.length - 1);
    }
    if (u.startsWith('//')) return 'https:$u';
    if (u.startsWith('/')) return 'https://jrock.ru$u';
    if (!u.startsWith('http')) return 'https://jrock.ru/$u';
    return u;
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day} ${_monthName(now.month)}';
  }

  String _monthName(int m) {
    const months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoader();
    if (_error.isNotEmpty) return _buildError();
    if (_articles.isEmpty) {
      return Center(
        child: Text('Пусто', style: AppTextStyles.smallMuted),
      );
    }

    final featured = _articles.take(_featuredCount).toList();
    final rest = _articles.skip(_featuredCount).toList();

    return RefreshIndicator(
      onRefresh: _loadArticles,
      color: AppColors.customStyle,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          const SizedBox(height: 8),

          // ---------- FEATURED PAGEVIEW ----------
          SizedBox(
            height: (MediaQuery.of(context).size.height * 0.38).clamp(200.0, 340.0),
            child: PageView.builder(
              controller: _featuredController,
              itemCount: featured.length,
              onPageChanged: (i) => setState(() => _featuredIndex = i),
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _FeaturedArticleCard(article: featured[i]),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          _buildDots(featured.length),

          const SizedBox(height: 12),

          // ---------- "НОВЫЕ МАТЕРИАЛЫ" HEADER ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'НОВЫЕ МАТЕРИАЛЫ',
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
                      Text('Все материалы', style: AppTextStyles.smallAccent),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.customStyle,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ---------- REST OF THE LIST ----------
          ...rest.map((a) => ArticleItem(article: a)),

          if (_hasMorePages)
            _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.customStyle,
                      ),
                    ),
                  )
                : const SizedBox(height: 20)
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('Больше нет', style: AppTextStyles.smallMuted),
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
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          decoration: BoxDecoration(
            color: active ? AppColors.customStyle : AppColors.dotInactive,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.customStyle),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 80, color: AppColors.customGrey),
          const SizedBox(height: 20),
          Text(
            _error.isEmpty ? 'Нет интернета' : _error,
            style: AppTextStyles.mediumMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadArticles,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.customStyle,
              foregroundColor: Colors.white,
            ),
            child: const Text('Обновить', style: AppTextStyles.button),
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
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: article.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.surfaceMuted),
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.surfaceMuted),
            ),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xE6000000),
                    Color(0x99000000),
                    Color(0x00000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),

            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_border,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (article.category ?? 'Статья').toUpperCase(),
                    style: AppTextStyles.smallAccent.copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    style: AppTextStyles.mediumBold.copyWith(
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (article.description.isNotEmpty)
                    Text(
                      article.description,
                      style: AppTextStyles.smallMuted.copyWith(height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        article.date,
                        style: AppTextStyles.smallMuted,
                      ),
                      const Spacer(),
                      const Row(
                        children: [
                          Text(
                            'Читать далее',
                            style: AppTextStyles.smallAccent,
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.customStyle,
                            size: 16,
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
      backgroundColor: AppColors.customBackgr,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Все материалы', style: AppTextStyles.appBarTitle),
      ),
      body: articles.isEmpty
          ? Center(
              child: Text('Пока ничего нет', style: AppTextStyles.mediumMuted),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: articles.length,
              itemBuilder: (context, i) =>
                  ArticleItem(article: articles[i]),
            ),
    );
  }
}