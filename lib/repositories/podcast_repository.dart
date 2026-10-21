import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jrrplayerapp/models/podcast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PodcastRepository with ChangeNotifier {
  // ---- Ключи SharedPreferences ----
  static const String _episodesCacheKey = 'episodes_cache';
  static const String _positionsKey = 'podcast_positions';

  /// Сколько эпизодов держим в быстром кэше getEpisodeById
  static const int _cacheLimit = 20;

  /// Позиции короче этого порога не сохраняем (случайные тапы)
  static const int _minSavedPositionSeconds = 1;

  final List<PodcastEpisode> _episodes = [];
  final Map<String, Duration> _durations = {};
  final Map<String, Duration> _positions = {};
  final Map<String, PodcastEpisode> _episodeCache = {};

  /// Подставляет уточнённую длительность (из плеера), если она известна
  PodcastEpisode _withDuration(PodcastEpisode episode) {
    final duration = _durations[episode.id];
    return duration != null ? episode.copyWith(duration: duration) : episode;
  }

  List<PodcastEpisode> get episodes => _episodes.map(_withDuration).toList();

  // ==================== ЭПИЗОДЫ ====================

  void updateEpisodeDuration(String episodeId, Duration duration) {
    if (_durations[episodeId] == duration) return;
    _durations[episodeId] = duration;
    _episodeCache.remove(episodeId); // Инвалидируем кэш
    notifyListeners();
  }

  Future<void> setEpisodes(List<PodcastEpisode> episodes) async {
    _episodes
      ..clear()
      ..addAll(episodes);

    // Кэшируем только первые эпизоды для экономии памяти
    _episodeCache.clear();
    for (final episode in episodes.take(_cacheLimit)) {
      _episodeCache[episode.id] = episode;
    }

    await _saveToStorage();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final episodesJson = _episodes.map((e) => e.toJson()).toList();
      await prefs.setString(_episodesCacheKey, jsonEncode(episodesJson));
    } catch (e) {
      debugPrint('Error saving episodes to storage: $e');
    }
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_episodesCacheKey);
      if (jsonString != null) {
        final List episodesJson = jsonDecode(jsonString);
        _episodes
          ..clear()
          ..addAll(episodesJson.map((json) => PodcastEpisode.fromJson(json)));
        _episodeCache.clear();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading episodes from storage: $e');
    }
  }

  /// Эпизод по ID (с быстрым кэшем). Длительность — актуальная.
  PodcastEpisode? getEpisodeById(String id) {
    final cached = _episodeCache[id];
    if (cached != null) return _withDuration(cached);

    final index = _episodes.indexWhere((episode) => episode.id == id);
    if (index == -1) return null;

    final episode = _episodes[index];
    if (_episodeCache.length >= _cacheLimit) {
      _episodeCache.remove(_episodeCache.keys.first);
    }
    _episodeCache[id] = episode;
    return _withDuration(episode);
  }

  List<PodcastEpisode> getAllEpisodes() => List.of(_episodes);

  /// Эпизоды, отсортированные по дате (новые первыми)
  List<PodcastEpisode> getSortedEpisodes() {
    return getAllEpisodes()
      ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
  }

  Future<PodcastEpisode?> getNextEpisode(PodcastEpisode currentEpisode) async {
    final episodes = getSortedEpisodes();
    final currentIndex =
        episodes.indexWhere((ep) => ep.id == currentEpisode.id);
    if (currentIndex != -1 && currentIndex + 1 < episodes.length) {
      return episodes[currentIndex + 1];
    }
    return null;
  }

  Future<PodcastEpisode?> getPreviousEpisode(
    PodcastEpisode currentEpisode,
  ) async {
    final episodes = getSortedEpisodes();
    final currentIndex =
        episodes.indexWhere((ep) => ep.id == currentEpisode.id);
    if (currentIndex > 0) {
      return episodes[currentIndex - 1];
    }
    return null;
  }

  void addEpisode(PodcastEpisode episode) {
    _episodes.add(episode);
    notifyListeners();
  }

  void removeEpisode(String id) {
    _episodes.removeWhere((episode) => episode.id == id);
    _durations.remove(id);
    _positions.remove(id);
    _episodeCache.remove(id);
    notifyListeners();
  }

  void clear() {
    _episodes.clear();
    _durations.clear();
    _positions.clear();
    _episodeCache.clear();
    notifyListeners();
  }

  // ==================== ПОЗИЦИИ ВОСПРОИЗВЕДЕНИЯ ====================

  bool hasEpisodePosition(String episodeId) {
    return (_positions[episodeId] ?? Duration.zero) > Duration.zero;
  }

  /// Сохранённая позиция эпизода (Duration.zero, если её нет)
  Duration getEpisodePosition(String episodeId) {
    return _positions[episodeId] ?? Duration.zero;
  }

  void updateEpisodePosition(String episodeId, Duration position) {
    // Не сохраняем случайные короткие позиции
    if (position.inSeconds <= _minSavedPositionSeconds) return;

    // Позиции хранятся с точностью до секунды: если секунда та же —
    // не пишем в хранилище и не перерисовываем все карточки заново.
    // (PodcastItem вызывает этот метод несколько раз за одну секунду.)
    if (_positions[episodeId]?.inSeconds == position.inSeconds) return;

    _positions[episodeId] = position;
    _savePositionsToStorage();
    notifyListeners();
  }

  Future<void> _savePositionsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionsMap = _positions.map(
        (key, value) => MapEntry(key, value.inSeconds.toString()),
      );
      await prefs.setString(_positionsKey, jsonEncode(positionsMap));
    } catch (e) {
      debugPrint('Error saving positions to storage: $e');
    }
  }

  /// Загружает сохранённые позиции. Вызывается при создании репозитория
  /// в main.dart — без этого после перезапуска все эпизоды начинались с 0.
  Future<void> loadPositionsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionsJson = prefs.getString(_positionsKey);
      if (positionsJson == null) return;

      final Map<String, dynamic> positionsMap = jsonDecode(positionsJson);
      positionsMap.forEach((key, value) {
        // Не затираем позицию, обновлённую уже после запуска
        if (value is String && !_positions.containsKey(key)) {
          _positions[key] = Duration(seconds: int.tryParse(value) ?? 0);
        }
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading positions from storage: $e');
    }
  }
}
