import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/repositories/podcast_repository.dart';
import 'package:jrrplayerapp/services/audio_player_service.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:jrrplayerapp/models/podcast.dart';
import 'package:jrrplayerapp/widgets/podcast_item.dart';
import 'package:flutter/foundation.dart';
import 'package:jrrplayerapp/constants/strings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int pageSize = 10;
const String _rssCacheKey = 'cached_rss_response';
const String _cacheTimestampKey = 'rss_cache_timestamp';
const Duration cacheDuration = Duration(hours: 1);

enum ConnectionType { wifi, mobile, offline }

// ----------------------------------------------------------------------
// Парсеры (только полный)
// ----------------------------------------------------------------------

List<PodcastEpisode> _parseRssFull(String responseBody) {
  try {
    final document = xml.XmlDocument.parse(responseBody);
    var items = document.findAllElements('item').toList();
    if (items.isEmpty) {
      final channel = document.findAllElements('channel').firstOrNull;
      items = channel?.findElements('item').toList() ?? [];
    }

    String? channelImageUrl;
    final channel = document.findAllElements('channel').firstOrNull;
    if (channel != null) {
      final channelImage = channel.findElements('image').firstOrNull;
      if (channelImage != null) {
        final channelUrlElement = channelImage.findElements('url').firstOrNull;
        if (channelUrlElement != null) {
          channelImageUrl = channelUrlElement.innerText.trim();
        }
      }
      if (channelImageUrl == null) {
        final itunesImage = channel.findElements('itunes:image').firstOrNull;
        if (itunesImage != null) {
          channelImageUrl = itunesImage.getAttribute('href')?.trim();
        }
      }
    }

    List<PodcastEpisode> podcasts = [];

    for (var item in items) {
      try {
        final titleElement = item.findElements('title').firstOrNull;
        final enclosureElement = item.findElements('enclosure').firstOrNull;
        if (titleElement == null || enclosureElement == null) continue;
        final title = titleElement.innerText.trim();
        final audioUrl = enclosureElement.getAttribute('url') ?? '';
        if (audioUrl.isEmpty) continue;

        final descriptionElement = item.findElements('description').firstOrNull;
        final durationElement = item.findElements('itunes:duration').firstOrNull;
        final guidElement = item.findElements('guid').firstOrNull;
        final pubDateElement = item.findElements('pubDate').firstOrNull;

        String? episodeImageUrl;
        final itunesImage = item.findElements('itunes:image').firstOrNull;
        if (itunesImage != null) {
          episodeImageUrl = itunesImage.getAttribute('href')?.trim();
        }
        if (episodeImageUrl == null) {
          final mediaThumbnail = item.findElements('media:thumbnail').firstOrNull;
          if (mediaThumbnail != null) {
            episodeImageUrl = mediaThumbnail.getAttribute('url')?.trim();
          }
        }
        if (episodeImageUrl == null) {
          final mediaContents = item.findElements('media:content');
          for (var content in mediaContents) {
            final type = content.getAttribute('type');
            final url = content.getAttribute('url');
            if (type?.startsWith('image/') == true && url != null) {
              episodeImageUrl = url.trim();
              break;
            }
          }
        }
        if (episodeImageUrl == null) {
          final enclosures = item.findElements('enclosure');
          for (var enclosure in enclosures) {
            final type = enclosure.getAttribute('type');
            final url = enclosure.getAttribute('url');
            if (type?.startsWith('image/') == true && url != null) {
              episodeImageUrl = url.trim();
              break;
            }
          }
        }

        final description = descriptionElement?.innerText.trim() ?? '';
        final durationString = durationElement?.innerText.trim() ?? '0:00:00';
        final guid = guidElement?.innerText.trim() ?? '${podcasts.length}_${DateTime.now().millisecondsSinceEpoch}';
        final duration = _parseDuration(durationString);
        DateTime publishedDate = DateTime.now();
        if (pubDateElement != null) {
          publishedDate = _parseDate(pubDateElement.innerText.trim());
        }

        podcasts.add(PodcastEpisode(
          id: guid,
          title: title,
          audioUrl: audioUrl,
          imageUrl: episodeImageUrl,
          channelImageUrl: channelImageUrl,
          description: description,
          duration: duration,
          publishedDate: publishedDate,
          channelId: 'jrr_podcast_channel',
          channelTitle: 'Подкасты',
        ));
      } catch (e) {
        continue;
      }
    }
    return podcasts;
  } catch (e) {
    debugPrint('Full parse error: $e');
    return [];
  }
}

Duration _parseDuration(String durationString) {
  try {
    if (!durationString.contains(':')) {
      final seconds = int.tryParse(durationString) ?? 0;
      return Duration(seconds: seconds);
    }
    final parts = durationString.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return Duration(minutes: minutes, seconds: seconds);
    } else if (parts.length >= 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }
    return Duration.zero;
  } catch (e) {
    return Duration.zero;
  }
}

DateTime _parseDate(String dateString) {
  try {
    return DateTime.parse(dateString);
  } catch (e) {
    try {
      final parts = dateString.split(' ');
      if (parts.length >= 3) {
        final day = int.tryParse(parts[1]) ?? 1;
        final month = _parseMonth(parts[2]);
        final year = int.tryParse(parts[3]) ?? DateTime.now().year;
        return DateTime(year, month, day);
      }
    } catch (e2) {
      // Игнорируем ошибки парсинга, используем текущую дату
    }
    return DateTime.now();
  }
}

int _parseMonth(String month) {
  const months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
    'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
    'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
  };
  return months[month] ?? 1;
}

// ----------------------------------------------------------------------
// Экран
// ----------------------------------------------------------------------

class PodcastListScreen extends StatefulWidget {
  const PodcastListScreen({super.key});

  @override
  State<PodcastListScreen> createState() => _PodcastListScreenState();
}

class _PodcastListScreenState extends State<PodcastListScreen> {
  List<PodcastEpisode> podcasts = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  String errorMessage = '';

  bool _isDownloading = false;
  String _downloadStatus = '';
  ConnectionType _connectionType = ConnectionType.offline;

  final ScrollController _scrollController = ScrollController();
  final Connectivity _connectivity = Connectivity();

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _initConnectivity();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityResult);
    _scrollController.addListener(_scrollListener);

    // 1. Сначала загружаем кеш (показываем сразу, если есть)
    await _loadCachedData();

    // 2. Если есть интернет, запускаем фоновое обновление свежими данными
    if (_connectionType != ConnectionType.offline) {
      _fetchFreshData();
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityResult(result);
    } catch (e) {
      debugPrint('Connectivity check error: $e');
    }
  }

  void _handleConnectivityResult(dynamic result) {
    List<ConnectivityResult> results;
    if (result is List<ConnectivityResult>) {
      results = result;
    } else if (result is ConnectivityResult) {
      results = [result];
    } else {
      results = [];
    }
    for (var r in results) {
      _updateConnectionType(r);
    }
  }

  void _updateConnectionType(ConnectivityResult result) {
    setState(() {
      switch (result) {
        case ConnectivityResult.wifi:
          _connectionType = ConnectionType.wifi;
          break;
        case ConnectivityResult.mobile:
          _connectionType = ConnectionType.mobile;
          break;
        default:
          _connectionType = ConnectionType.offline;
      }
    });
    debugPrint('🔌 Connection type: $_connectionType');
  }

  // ----------------------------------------------------------------------
  // Загрузка кеша
  // ----------------------------------------------------------------------
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_rssCacheKey);
      if (cachedData != null) {
        _updateStatus('Загрузка из кэша...');
        List<PodcastEpisode> cachedPodcasts;
        if (kIsWeb) {
          cachedPodcasts = _parseRssFull(cachedData);
        } else {
          cachedPodcasts = await compute(_parseRssFull, cachedData)
              .timeout(const Duration(seconds: 3), onTimeout: () => []);
        }
        if (cachedPodcasts.isNotEmpty && mounted) {
          final podcastRepo = Provider.of<PodcastRepository>(context, listen: false);
          podcastRepo.setEpisodes(cachedPodcasts);
          cachedPodcasts.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
          setState(() {
            podcasts = cachedPodcasts.take(pageSize).toList();
            isLoading = false;
            hasMore = cachedPodcasts.length > pageSize;
            errorMessage = '';
          });
          debugPrint('📂 Загружено ${podcasts.length} эпизодов из кеша');
          return;
        }
      }
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = '';
        });
        debugPrint('📂 Кеш не найден, ожидаем загрузки из сети');
      }
    } catch (e) {
      debugPrint('Cache load error: $e');
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = '';
        });
      }
    }
  }

  // ----------------------------------------------------------------------
  // Фоновое обновление (используем AppStrings.getWithProxy)
  // ----------------------------------------------------------------------
  Future<void> _fetchFreshData() async {
    if (!mounted) return;
    if (_connectionType == ConnectionType.offline) return;

    // Получаем репозиторий синхронно (до всех await)
    final podcastRepo = Provider.of<PodcastRepository>(context, listen: false);

    try {
      _isDownloading = true;
      _startStatusUpdates();

      // Пробуем загрузить полный RSS через универсальный метод с прокси
      final response = await AppStrings.getWithProxy(AppStrings.podcastRssOriginalUrl);
      final responseBody = response.body;
      debugPrint('📡 RSS получен, длина: ${responseBody.length}');

      // Парсим
      List<PodcastEpisode> freshPodcasts;
      if (kIsWeb) {
        freshPodcasts = _parseRssFull(responseBody);
      } else {
        freshPodcasts = await compute(_parseRssFull, responseBody)
            .timeout(const Duration(seconds: 10), onTimeout: () => []);
      }

      // Проверяем, что виджет ещё существует
      if (!mounted) return;

      if (freshPodcasts.isNotEmpty) {
        // Сохраняем в кеш
        await _saveToCache(responseBody);

        podcastRepo.setEpisodes(freshPodcasts);
        freshPodcasts.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));

        setState(() {
          podcasts = freshPodcasts.take(pageSize).toList();
          hasMore = freshPodcasts.length > pageSize;
          errorMessage = '';
          if (isLoading) isLoading = false;
        });
        debugPrint('✅ Загружено ${freshPodcasts.length} эпизодов из сети');
      } else {
        // Парсинг вернул пустой список – используем кеш, если есть
        if (podcasts.isEmpty) {
          // Если кеша не было, показываем ошибку
          setState(() {
            errorMessage = 'Не удалось загрузить подкасты (пустой ответ)';
            isLoading = false;
          });
        } else {
          // Показываем кеш
          setState(() {
            errorMessage = 'Обновление не удалось, показаны кешированные данные';
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch fresh data error: $e');
      if (mounted) {
        if (podcasts.isEmpty) {
          setState(() {
            errorMessage = 'Ошибка загрузки: ${e.toString()}';
            isLoading = false;
          });
        } else {
          // Есть кеш – просто показываем уведомление
          setState(() {
            errorMessage = 'Не удалось обновить, показан кеш';
          });
        }
      }
    } finally {
      _isDownloading = false;
      _stopStatusUpdates();
    }
  }

  // ----------------------------------------------------------------------
  // Ручное обновление (pull-to-refresh)
  // ----------------------------------------------------------------------
  Future<void> _refreshPodcasts() async {
    if (!mounted) return;
    if (_connectionType == ConnectionType.offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет подключения к интернету')),
      );
      return;
    }
    await _fetchFreshData();
  }

  // ----------------------------------------------------------------------
  // Кэш (сохранение)
  // ----------------------------------------------------------------------
  Future<void> _saveToCache(String rssData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rssCacheKey, rssData);
      await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
      debugPrint('💾 Cache saved');
    } catch (e) {
      debugPrint('Cache save error: $e');
    }
  }

  // ----------------------------------------------------------------------
  // Вспомогательные методы
  // ----------------------------------------------------------------------
  void _startStatusUpdates() {
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isDownloading && mounted) {
        setState(() {
          _downloadStatus = _getRandomStatusMessage();
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopStatusUpdates() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;
    if (mounted) {
      setState(() {
        _downloadStatus = '';
      });
    }
  }

  String _getRandomStatusMessage() {
    const messages = [
      'Оптимизация загрузки...',
      'Обработка данных...',
      'Подготовка к воспроизведению...',
      'Настройка качества звука...',
      'Проверка доступности...',
    ];
    return messages[Random().nextInt(messages.length)];
  }

  void _updateStatus(String status) {
    if (mounted && _isDownloading) {
      setState(() {
        _downloadStatus = status;
      });
    }
  }

  // ----------------------------------------------------------------------
  // Пагинация
  // ----------------------------------------------------------------------
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!isLoadingMore && hasMore && !isLoading) {
        _loadMorePodcasts();
      }
    }
  }

  Future<void> _loadMorePodcasts() async {
    if (isLoadingMore || !hasMore) return;
    if (!mounted) return;
    setState(() {
      isLoadingMore = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final podcastRepo = Provider.of<PodcastRepository>(context, listen: false);
      final allEpisodes = podcastRepo.getSortedEpisodes();
      final startIndex = podcasts.length;
      final endIndex = startIndex + pageSize;
      if (startIndex < allEpisodes.length) {
        final morePodcasts = allEpisodes.sublist(
          startIndex,
          endIndex < allEpisodes.length ? endIndex : allEpisodes.length,
        );
        if (mounted) {
          setState(() {
            podcasts.addAll(morePodcasts);
            hasMore = endIndex < allEpisodes.length;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            hasMore = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Load more error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _scrollController.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // Build
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = Provider.of<AudioPlayerService>(context, listen: false);
      final podcastRepo = Provider.of<PodcastRepository>(context, listen: false);
      audioService.setPodcastRepository(podcastRepo);
    });

    return Scaffold(
      backgroundColor: AppColors.customBlack,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading && _downloadStatus.isNotEmpty) {
      return _buildLoadingScreen();
    }
    if (errorMessage.isNotEmpty) {
      return _buildErrorScreen();
    }
    if (podcasts.isEmpty) {
      return _buildEmptyScreen();
    }
    return _buildPodcastList();
  }

  Widget _buildLoadingScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                _downloadStatus,
                style: const TextStyle(color: AppColors.customWhite, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_connectionType == ConnectionType.mobile)
                const Text(
                  'Используется оптимизированный режим для медленного соединения',
                  style: TextStyle(color: AppColors.customGrey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _connectionType == ConnectionType.offline
                  ? Icons.wifi_off
                  : Icons.error_outline,
              size: 64,
              color: AppColors.customWhite,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(color: AppColors.customWhite, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _refreshPodcasts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.customGreen,
                    foregroundColor: AppColors.customWhite,
                  ),
                  child: const Text('Повторить'),
                ),
                const SizedBox(width: 16),
                if (_connectionType != ConnectionType.offline && podcasts.isNotEmpty)
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        errorMessage = '';
                      });
                    },
                    child: const Text('Продолжить'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.podcasts, size: 64, color: AppColors.customGrey),
          const SizedBox(height: 16),
          const Text(
            'Нет доступных подкастов',
            style: TextStyle(color: AppColors.customWhite, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _connectionType == ConnectionType.offline
                ? 'Подключитесь к интернету для загрузки'
                : 'Проверьте соединение и попробуйте снова',
            style: const TextStyle(color: AppColors.customGrey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshPodcasts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.customGreen,
              foregroundColor: AppColors.customWhite,
            ),
            child: const Text('Загрузить подкасты'),
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastList() {
    return RefreshIndicator(
      onRefresh: _refreshPodcasts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: podcasts.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == podcasts.length && hasMore) {
            return _buildLoadMoreIndicator();
          }
          return PodcastItem(
            key: ValueKey(podcasts[index].id),
            podcast: podcasts[index],
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: isLoadingMore
            ? Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    _connectionType == ConnectionType.mobile
                        ? 'Загрузка... (может занять время)'
                        : 'Загрузка...',
                    style: const TextStyle(color: AppColors.customGrey),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: _loadMorePodcasts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.customGreen,
                  foregroundColor: AppColors.customWhite,
                ),
                child: const Text('Загрузить еще'),
              ),
      ),
    );
  }
}
