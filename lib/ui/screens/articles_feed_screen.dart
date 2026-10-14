// lib/ui/screens/articles_feed_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:jrrplayerapp/constants/app_colors.dart';

import 'package:jrrplayerapp/models/article.dart';
import 'package:jrrplayerapp/widgets/article_item.dart';
import 'package:jrrplayerapp/constants/strings.dart';

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

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
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

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
      _articles.clear();
      _loadedUrls.clear();
    });

    try {
      // jrock.ru uses /feed for page 1, /feed/p2, /feed/p3... for pagination
      const base = AppStrings.articlesFeedUrl; // e.g. https://jrock.ru/feed
      final url = kIsWeb
          ? AppStrings.proxyUrl('$base/')
          : '$base/';

      final response = await AppStrings.getWithProxy(url);

      if (response.statusCode == 200) {
        _parseHtml(response.body, isFirstLoad: true);
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
      // jrock.ru pagination: /feed/p2, /feed/p3, ...
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
    } catch (e) {
      _hasMorePages = false;
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  // ==================== PARSER ====================
  // Supports BOTH structures:
  //   - OLD jrock.pro: .qt-part-archive-item with h3.qt-title
  //   - NEW jrock.ru:  a.row with <b>title</b>, <span>description</span>,
  //                    .rdate date, .rkind badge, and <img>
  void _parseHtml(String html, {required bool isFirstLoad}) {
    final document = parser.parse(html);

    // Try new jrock.ru structure first
    var items = document.querySelectorAll('a.row');
    bool isNewStructure = items.isNotEmpty;

    // Fallback to old jrock.pro structure
    if (items.isEmpty) {
      items = document.querySelectorAll('.qt-part-archive-item');
      isNewStructure = false;
    }

    final List<Article> newArticles = [];

    for (final el in items) {
      final article = isNewStructure
          ? _parseArticleNew(el)
          : _parseArticleOld(el);
      if (article != null && !_loadedUrls.contains(article.url)) {
        newArticles.add(article);
        _loadedUrls.add(article.url);
      }
    }

    // Detect "next page" link for pagination
    // jrock.ru: <a href=".../feed/p2">→</a> or rel="next"
    // jrock.pro: <a class="next page-numbers">
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

  // ---------- NEW structure (jrock.ru) ----------
  Article? _parseArticleNew(dom.Element row) {
    try {
      final href = row.attributes['href'];
      if (href == null || href.isEmpty) return null;

      // Title is inside <b> inside .rbody
      final titleEl = row.querySelector('.rbody b');
      final title = titleEl?.text.trim();
      if (title == null || title.isEmpty) return null;

      // Description is the <span> sibling inside .rbody (first span that
      // isn't inside another nested element)
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

      // Date from .rdate
      final dateEl = row.querySelector('.rdate');
      final date = dateEl?.text.trim() ?? _getCurrentDate();

      // Category from .rkind .badge-kind (e.g. "Трудности перевода")
      final kindEl = row.querySelector('.rkind .badge-kind');
      final category = kindEl?.text.trim() ?? '';

      // Image: first <img> in the row
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
      );
    } catch (e) {
      debugPrint('Ошибка парсинга статьи (новая структура): $e');
      return null;
    }
  }

  // ---------- OLD structure (jrock.pro) ----------
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

      // Image lookup — same as before
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
      );
    } catch (e) {
      debugPrint('Ошибка парсинга статьи (старая структура): $e');
      return null;
    }
  }

  // ==================== HELPERS ====================

  /// Makes an image/href URL absolute and strips quotes.
  String _normalizeUrl(String raw) {
    var u = raw.trim();

    // strip surrounding quotes
    if ((u.startsWith('"') && u.endsWith('"')) ||
        (u.startsWith("'") && u.endsWith("'"))) {
      u = u.substring(1, u.length - 1);
    }

    if (u.startsWith('//')) return 'https:$u';

    if (u.startsWith('/')) {
      // Relative — resolve against jrock.ru (the current feed)
      return 'https://jrock.ru$u';
    }

    if (!u.startsWith('http')) {
      return 'https://jrock.ru/$u';
    }

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

  // ==================== UI ====================

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 80, color: AppColors.customGrey),
          const SizedBox(height: 20),
          Text(
            _error.isEmpty ? 'Нет интернета' : _error,
            style: const TextStyle(
              color: AppColors.customWhiteTransp,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadArticles,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.customGreen,
            ),
            child: const Text(
              'Обновить',
              style: TextStyle(color: AppColors.customWhite),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.customGreen),
    );
  }

  Widget _buildLoadMore() {
    if (!_hasMorePages) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Больше нет',
            style: TextStyle(color: AppColors.customWhiteTransp),
          ),
        ),
      );
    }
    return _isLoadingMore
        ? const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.customGreen),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.customBlack,
      body: RefreshIndicator(
        onRefresh: _loadArticles,
        color: AppColors.customGreen,
        child: _isLoading
            ? _buildLoader()
            : _error.isNotEmpty
                ? _buildError()
                : _articles.isEmpty
                    ? const Center(
                        child: Text(
                          'Пусто',
                          style: TextStyle(color: AppColors.customGrey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _articles.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _articles.length) {
                            return _buildLoadMore();
                          }
                          return ArticleItem(article: _articles[index]);
                        },
                      ),
      ),
    );
  }
}