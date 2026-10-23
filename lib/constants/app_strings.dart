import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppStrings {
  // App
  static const String appName = 'РАДИО J-ROCK';
  static const String radioName = 'Радио J-Rock';
  static const String radioTitle = 'Радио J-Rock';
  static const String radioAlbum = 'Онлайн радио';
  static const String radioArtist = '';
  static const String stringPlaying = 'СЕЙЧАС ИГРАЕТ';
  static const String appVersion = '1.0.0';

  // Tabs
  static const String articlesTab = 'Актуальное';
  static const String newsTab = 'Новости';
  static const String podcastsTab = 'Hora Bissexta';

  // ==================== ОБЩИЕ UI-СТРОКИ ====================
  static const String noInternet = 'Нет подключения к интернету';
  static const String noInternetShort = 'Нет интернета';
  static const String serverError = 'Ошибка сервера';
  static const String retry = 'Повторить';
  static const String tryAgain = 'Попробовать снова';
  static const String refresh = 'Обновить';
  static const String continueLabel = 'Продолжить';
  static const String cancel = 'Отмена';
  static const String loading = 'Загрузка...';
  static const String loadingSlow = 'Загрузка... (может занять время)';
  static const String loadMore = 'Загрузить еще';

  /// Месяцы в родительном падеже (индекс 1..12)
  static const List<String> monthsGenitive = [
    '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  // ==================== СТАТЬИ ====================
  static const String articleDefaultTitle = 'Статья';
  static const String articleDefaultCategory = 'Статья';
  static const String articleOpeningInBrowser =
      'Открываем статью в новой вкладке...';
  static const String articlesEmpty = 'Пусто';
  static const String articlesNewHeader = 'НОВЫЕ МАТЕРИАЛЫ';
  static const String articlesAll = 'Все материалы';
  static const String articlesNoMore = 'Больше нет';
  static const String articlesNothingYet = 'Пока ничего нет';
  static const String readMore = 'Читать далее';

  static const String articleFallbackImage = 'https://jrock.ru/favicon-32.png';
  static const String articleLegacyFallbackImage =
      'https://jrock.pro/wp-content/uploads/2023/01/jrock-logo.png';

  // ==================== НОВОСТИ ====================
  static const String newsLoadError = 'Не удалось загрузить новости';
  static const String newsNoSources = 'Не удалось загрузить ни одного источника';
  static const String newsEmpty = 'Новости не найдены';

  // ==================== ПОДКАСТЫ ====================
  static const String podcastChannelId = 'jrr_podcast_channel';
  static const String podcastChannelTitle = 'Подкасты';
  static const String podcastLoadingCache = 'Загрузка из кэша...';
  static const String podcastEmptyResponse =
      'Не удалось загрузить подкасты (пустой ответ)';
  static const String podcastUpdateFailedCached =
      'Обновление не удалось, показаны кешированные данные';
  static const String podcastLoadError = 'Ошибка загрузки';
  static const String podcastShowingCache = 'Не удалось обновить, показан кеш';
  static const String podcastSlowMode =
      'Используется оптимизированный режим для медленного соединения';
  static const String podcastsEmpty = 'Нет доступных подкастов';
  static const String podcastsConnectHint =
      'Подключитесь к интернету для загрузки';
  static const String podcastsCheckConnection =
      'Проверьте соединение и попробуйте снова';
  static const String podcastsLoad = 'Загрузить подкасты';
  static const List<String> podcastStatusMessages = [
    'Оптимизация загрузки...',
    'Обработка данных...',
    'Подготовка к воспроизведению...',
    'Настройка качества звука...',
    'Проверка доступности...',
  ];

  // ==================== МЕНЮ / О РАДИО ====================
  static const String menuAbout = 'О радио';
  static const String menuSettings = 'Настройки';
  static const String aboutVersionLabel = 'Версия';
  static const String aboutDescription =
      'Слушать, думать, жить\n'
      'Человеку нужно место, где можно остановиться и подумать. '
      'Без готовых ответов, правильных слов и необходимости соглашаться. '
      'Здесь музыка соседствует с разговорами о человеке, Библии, истории, науке и жизни. '
      'О том, что действительно важно, когда остаёшься один на один с собой. '
      'Можно просто слушать. А можно вместе искать свои ответы.';
  static const String aboutCopyright = 'Все права защищены';
  static const String aboutDeveloper = 'Разработчик';
  static const String aboutDeveloperName = 'Команда';
  static const String aboutWebsite = 'Сайт';
  static const String aboutTelegram = 'Telegram';
  static const String aboutVkontakte = 'ВКонтакте';

  // ==================== НАСТРОЙКИ ====================
  static const String settingsPlayback = 'Воспроизведение';
  static const String settingsAutoPlay = 'Автовоспроизведение';
  static const String settingsAutoPlayHint =
      'Запускать радио при открытии приложения';
  static const String settingsHighQuality = 'Высокое качество звука';
  static const String settingsHighQualityHint =
      'Использовать поток с более высоким битрейтом';
  static const String settingsDefaultVolume = 'Громкость по умолчанию';
  static const String settingsNotifications = 'Уведомления';
  static const String settingsShowNotifications = 'Показывать уведомления';
  static const String settingsShowNotificationsHint =
      'Отображать информацию о треке в шторке';
  static const String settingsReset = 'Сброс';
  static const String settingsResetTitle = 'Сбросить настройки';
  static const String settingsResetHint =
      'Вернуть все параметры к значениям по умолчанию';
  static const String settingsResetConfirmTitle = 'Сбросить настройки?';
  static const String settingsResetConfirmBody =
      'Все параметры будут возвращены к значениям по умолчанию.';
  static const String settingsResetConfirm = 'Сбросить';
  static const String settingsResetDone = 'Настройки сброшены';

  // ==================== APPBAR / СИГНАЛ ====================
  static const String ok = 'OK';
  static const String signalStatusTitle = 'Статус сигнала';
  static const String signalConnected = 'Подключено';
  static const String signalDisconnected = 'Нет соединения';

  // ==================== ПЛЕЕР ====================
  static const String volumeUnmute = 'Включить звук';
  static const String volumeMute = 'Выключить звук';
  static const String playbackError = 'Ошибка воспроизведения';
  static const String volumeError = 'Не удалось изменить громкость';
  static const String nextEpisodeError = 'Не удалось включить следующий выпуск';
  static const String previousEpisodeError =
      'Не удалось включить предыдущий выпуск';

  // ==================== ФОНОВОЕ АУДИО / УВЕДОМЛЕНИЕ ====================
  static const String notificationChannelId = 'com.jrrplayerapp.channel.audio';
  static const String notificationIcon = 'mipmap/ic_launcher';
  static const String lifecycleChannel = 'com.jrrplayerapp/app_lifecycle';
  static const String radioMediaId = 'jrr_live_stream';
  static const String podcastArtist = 'Подкаст J-Rock';
  static const String httpUserAgent = 'JRRPlayer/1.0';

  // Подписи кнопок в уведомлении
  static const String ctrlPrevious = 'Предыдущий';
  static const String ctrlRewind = '30 секунд назад';
  static const String ctrlPlay = 'Воспроизвести';
  static const String ctrlPause = 'Пауза';
  static const String ctrlForward = '30 секунд вперед';
  static const String ctrlNext = 'Следующий';
  static const String ctrlStop = 'Стоп';

  // URLs
  static const String livestreamUrl = 'https://nradio.net/jrock';
  static const String vkontakteUrl = 'https://vk.com/jrockradio';
  static const String telegramUrl = 'https://telegram.me/jrockradio';
  static const String wwweblinkUrl = 'https://jrock.ru';
  static const String articlesFeedUrl = 'https://jrock.ru/lenta';
  static const String newsFeedUrl = 'https://telegram.me/s/jrr_news';
  static const List<String> newsFeedUrls = [
    'https://app.diri.su/rss/posting/32266eefb24e7cb14e1d954719dd2953.xml',
    'https://app.diri.su/rss/posting/3f059a15f6b3e63b8783fa88ecdf9855.xml',
    'https://app.diri.su/rss/posting/0adfd68a63caa61374c28de3a92e2677.xml',
  ];

  // Базовый URL для отдельных новостей (по ID)
  //static const String telegramNewsBaseUrl = 'https://telegram.me/jrr_news/';
  // Podcast RSS Feed mit Proxy-Optionen
  static const String podcastRssOriginalUrl = 'https://cloud.mave.digital/61074';

  /// Icecast status (метаданные радио в веб-версии)
  static const String icecastStatusUrl = 'https://nradio.net/status-json.xsl';

  /// Поиск обложек
  static const String itunesSearchUrl = 'https://itunes.apple.com/search';
  static const List<String> corsProxies = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
    'https://api.codetabs.com/v1/proxy?quest=',
    'https://proxy.cors.sh/',
    'https://cors-anywhere.herokuapp.com/'
  ];

  // Deezer API mit mehreren Proxy-Optionen
  static List<String> getDeezerApiUrls(String query) {
    final originalUrl = 'https://api.deezer.com/search?q=$query&limit=1';
    return AppStrings.corsProxies
        .map((proxy) => '$proxy${Uri.encodeFull(originalUrl)}')
        .toList();
  }

  // ==================== CORS PROXY ДЛЯ ВЕБА ====================
  static String proxyUrl(String url) {
    if (kIsWeb) {
      // Самый надёжный прокси на декабрь 2025
      return 'https://api.allorigins.win/raw?url=${Uri.encodeFull(url)}';
    }
    return url;
  }

  // Более умная версия с fallback (если вдруг основной упадёт)
  static Future<http.Response> getWithProxy(String url) async {
    if (!kIsWeb) {
      return await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    }

    const proxies = [
      'https://api.allorigins.win/raw?url=',
      'https://corsproxy.io/?',
      'https://thingproxy.freeboard.io/fetch/',
      'https://cors.bridged.cc/',
    ];

    for (final proxyBase in proxies) {
      try {
        final full = '$proxyBase${Uri.encodeFull(url)}';
        final resp = await http
            .get(Uri.parse(full))
            .timeout(const Duration(seconds: 18));

        // allorigins иногда возвращает 200 с пустым телом или ошибкой в JSON
        if (resp.statusCode == 200 && resp.body.length > 500) {
          return resp;
        }
      } catch (_) {
        continue;
      }
    }
    throw Exception('Все CORS-прокси временно недоступны');
  }
}

/// Пути к ассетам (должны совпадать с pubspec.yaml).
class AppAssets {
  AppAssets._();

  /// Логотип-кнопка радио на главном экране
  static const String radioButtonIcon =
      'assets/images/icon_jrockradio_custom_style.png';

  /// Иконка «веб» (ссылка на сайт под кнопкой меню), SVG
  static const String webIcon = 'assets/icon/icon_wwweblink.svg';
  static const String telegramIcon = 'assets/icon/icon_telegram.svg';
  static const String vkontakteIcon = 'assets/icon/icon_vkontakte.svg';

  /// Обложка по умолчанию в плеере
  static const String defaultCover = 'assets/images/default_cover.png';

  /// Та же обложка в виде asset://-URI (для уведомления / audio_service)
  static const String defaultCoverAssetUri = 'asset:///$defaultCover';
}
