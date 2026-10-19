import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:xml/xml.dart' as xml;
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/models/news.dart';
import 'package:jrrplayerapp/widgets/news_item.dart';
import 'package:jrrplayerapp/constants/strings.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  List<News> _news = [];
  bool _isLoading = true;
  String _error = '';
  final ScrollController _scrollController = ScrollController();
  final Set<String> _loadedGuids = {};

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ==================== LOADING ====================
  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _news.clear();
      _loadedGuids.clear();
    });

    try {
      final responses = await Future.wait(
        AppStrings.newsFeedUrls.map(
          (url) => AppStrings.getWithProxy(url),
        ),
      );

      final List<News> combined = [];
      for (int i = 0; i < responses.length; i++) {
        final resp = responses[i];
        if (resp.statusCode == 200) {
          final parsed = _parseRss(resp.body);
          debugPrint(
            '📰 Feed ${i + 1}: ${parsed.length} items '
            '(${AppStrings.newsFeedUrls[i]})',
          );
          combined.addAll(parsed);
        } else {
          debugPrint('⚠️ Feed ${i + 1} failed: HTTP ${resp.statusCode}');
        }
      }

      if (combined.isEmpty) {
        throw Exception('Не удалось загрузить ни одного источника');
      }

      final Map<String, News> unique = {};
      for (final n in combined) {
        unique.putIfAbsent(n.id, () => n);
      }

      final sorted = unique.values.toList()
        ..sort((a, b) => b.parsedDate.compareTo(a.parsedDate));

      setState(() {
        _news = sorted;
        _isLoading = false;
      });

      debugPrint('✅ Всего новостей: ${sorted.length}');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки новостей: $e');
      setState(() {
        _error = 'Не удалось загрузить новости: $e';
        _isLoading = false;
      });
    }
  }

  // ==================== RSS PARSER ====================
  List<News> _parseRss(String xmlBody) {
    final List<News> result = [];

    try {
      final document = xml.XmlDocument.parse(xmlBody);
      final items = document.findAllElements('item');

      for (final item in items) {
        try {
          final title = _text(item, 'title');
          final link = _text(item, 'link');
          final guid = _text(item, 'guid') ?? link;
          final pubDate = _text(item, 'pubDate');
          final rawDescription = _text(item, 'description') ?? '';

          String imageUrl = '';
          final enclosure = item.findElements('enclosure').firstOrNull;
          if (enclosure != null) {
            imageUrl = enclosure.getAttribute('url') ?? '';
          }

          if (title == null || title.isEmpty) continue;

          final parsedDate = _parseRfc822(pubDate);

          result.add(
            News(
              id: guid ?? link ?? title,
              title: _stripHtml(title),
              date: _formatDate(parsedDate),
              imageUrl: imageUrl,
              description: rawDescription,
              url: link ?? '',
              parsedDate: parsedDate,
            ),
          );
        } catch (e) {
          debugPrint('❌ Ошибка парсинга item: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка парсинга RSS XML: $e');
    }

    return result;
  }

  String? _text(xml.XmlElement parent, String tag) {
    final el = parent.findElements(tag).firstOrNull;
    return el?.innerText.trim();
  }

  String _stripHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime _parseRfc822(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    try {
      final parts = raw.split(' ');
      if (parts.length < 5) return DateTime.now();

      final day = int.tryParse(parts[1]) ?? 1;
      final month = _monthFromName(parts[2]);
      final year = int.tryParse(parts[3]) ?? DateTime.now().year;

      final timeParts = parts[4].split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      final second =
          int.tryParse(timeParts.length > 2 ? timeParts[2] : '0') ?? 0;

      return DateTime.utc(year, month, day, hour, minute, second).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  int _monthFromName(String name) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    return months[name] ?? 1;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  // ==================== UI ====================
  Widget _buildErrorWidget() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off,
                size: 64,
                color: AppColors.customGrey,
              ),
              const SizedBox(height: 16),
              Text(
                _error,
                style: AppTextStyles.medium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadNews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.customStyle,
                  foregroundColor: AppColors.customWhite,
                ),
                child: const Text(
                  'Попробовать снова',
                  style: AppTextStyles.button,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.article_outlined,
                size: 64,
                color: AppColors.customGrey,
              ),
              const SizedBox(height: 16),
              Text(
                'Новости не найдены',
                style: AppTextStyles.mediumMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.customBlack,
      body: RefreshIndicator(
        onRefresh: _loadNews,
        color: AppColors.customStyle,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.customStyle),
                ),
              )
            : _error.isNotEmpty
                ? _buildErrorWidget()
                : _news.isEmpty
                    ? _buildEmptyWidget()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _news.length,
                        itemBuilder: (ctx, index) {
                          return NewsItem(news: _news[index]);
                        },
                      ),
      ),
    );
  }
}