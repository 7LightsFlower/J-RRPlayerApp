import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_strings.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/services/audio_player_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

/// A tiny wrapper that turns a [Stream<T>] into a [ValueListenable<T>].
class _StreamValueNotifier<T> extends ValueNotifier<T> {
  final Stream<T> _stream;
  late final StreamSubscription<T> _subscription;

  _StreamValueNotifier(this._stream, T initialValue) : super(initialValue) {
    _subscription = _stream.listen((value) => this.value = value);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayerService _audioService;
  late final ValueNotifier<bool> _playingNotifier;
  late ValueNotifier<Duration?> _positionNotifier;
  late ValueNotifier<Duration?> _durationNotifier;
  late final ValueNotifier<AudioMetadata?> _metadataNotifier;
  late final ValueNotifier<int> _imageUpdateNotifier;
  late ValueNotifier<double> _volumeNotifier;

  AudioPlayer? _lastPlayer;

  /// Подписка на состояние воспроизведения и таймер синхронизации —
  /// храним, чтобы отменить в dispose() (раньше они жили вечно).
  StreamSubscription<dynamic>? _playbackSub;
  Timer? _syncTimer;

  bool _isToggling = false;

  @override
  void initState() {
    super.initState();

    _audioService = Provider.of<AudioPlayerService>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _printRadioState();
    });

    _playbackSub = _audioService.playbackStateStream.listen((isPlaying) {
      if (mounted && !_isToggling) {
        setState(() {
          _playingNotifier.value = isPlaying;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncPlayerState();
      }
    });

    _initializeNotifiers();
    _setupDurationSync();
    _setupPlayerStateListener();

    _syncTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _syncPlayerState();
    });
  }

  void _printRadioState() {
    if (!_audioService.isPodcastMode) {
      final player = _audioService.getPlayer();
      debugPrint('=== RADIO STATE DEBUG ===');
      debugPrint('🎵 player.playing: ${player?.playing}');
      debugPrint('🎵 service.isPlaying: ${_audioService.isPlaying}');
      debugPrint('🎵 isRadioPlaying: ${_audioService.isRadioPlaying}');
      debugPrint('🎵 isRadioPaused: ${_audioService.isRadioPaused}');
      debugPrint('🎵 isRadioStopped: ${_audioService.isRadioStopped}');
      debugPrint('🎵 processingState: ${player?.processingState}');
      debugPrint('=== END DEBUG ===');
    }
  }

  void _setupPlayerStateListener() {
    final player = _audioService.getPlayer();
    if (player != null) {
      // reserved for direct player listeners
    }
  }

  void _initializeNotifiers() {
    final player = _audioService.getPlayer();

    _playingNotifier = ValueNotifier<bool>(_audioService.isPlaying);

    // Если player уже есть — берём его стримы, иначе — пустые стримы сервиса,
    // которые начнут эмитить, как только player появится (они читают _player каждый раз).
    _positionNotifier = _StreamValueNotifier<Duration?>(
      player?.positionStream ?? _audioService.positionStream,
      player?.position ?? Duration.zero,
    );

    _durationNotifier = _StreamValueNotifier<Duration?>(
      player?.durationStream ?? _audioService.durationStream,
      player?.duration,
    );

    _volumeNotifier = _StreamValueNotifier<double>(
      player?.volumeStream ?? _audioService.getVolumeStream(),
      player?.volume ?? 1.0,
    );

    _metadataNotifier = ValueNotifier(_audioService.currentMetadata);
    _imageUpdateNotifier = ValueNotifier(0);

    _audioService.addListener(_onAudioServiceUpdate);
  }

  void _setupDurationSync() {
    _durationNotifier.addListener(() {
      final duration = _durationNotifier.value;
      if (duration != null && duration > Duration.zero) {
        _audioService.updatePodcastDuration(duration);
      }
    });
  }

  void _onAudioServiceUpdate() {
    if (!mounted) return;

    // Если player только что появился — пересоздаём подписки на его стримы
    final player = _audioService.getPlayer();
    if (player != null && _lastPlayer != player) {
      _lastPlayer = player;
      _rebindStreams(player);
    }

    _syncPlayerState();
  }

  void _rebindStreams(AudioPlayer player) {
    _positionNotifier.dispose();
    _durationNotifier.dispose();
    _volumeNotifier.dispose();

    _positionNotifier = _StreamValueNotifier<Duration?>(
      player.positionStream,
      player.position,
    );
    _durationNotifier = _StreamValueNotifier<Duration?>(
      player.durationStream,
      player.duration,
    );
    _volumeNotifier = _StreamValueNotifier<double>(
      player.volumeStream,
      player.volume,
    );

    // ⚠️ ВАЖНО: переподписываемся на duration для podcast-режима,
    // потому что старый listener умер вместе со старым _durationNotifier.
    _setupDurationSync();
  }

  Future<void> _togglePlayPause() async {
    if (_isToggling) return;

    setState(() {
      _isToggling = true;
    });

    final isCurrentlyPlaying = _audioService.isPlaying;

    // Оптимистичное обновление UI (иконка меняется сразу)
    _playingNotifier.value = !isCurrentlyPlaying;

    try {
      if (isCurrentlyPlaying) {
        unawaited(_audioService.pause());
      } else {
        if (_audioService.isPodcastMode && _audioService.currentEpisode != null) {
          unawaited(_audioService.playPodcast(_audioService.currentEpisode!));
        } else {
          if (_audioService.isRadioPaused) {
            unawaited(_audioService.resumeRadioFromPause());
          } else {
            unawaited(_audioService.playRadio());
          }
        }
      }
    } catch (e) {
      debugPrint('🎵 Error in toggle play/pause: $e');
      _showErrorSnackBar('${AppStrings.playbackError}: $e');
      _playingNotifier.value = isCurrentlyPlaying; // Откат
    } finally {
      // Снимаем спиннер через 500 мс, не дожидаясь окончания загрузки
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isToggling = false;
          });
          _syncPlayerState(); // Принудительно синхронизируем
        }
      });
    }
  }

  void _showErrorSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _syncPlayerState() {
    final player = _audioService.getPlayer();
    if (player == null) return;

    final position = player.position;
    final duration = player.duration;

    // Не блокируем обновление UI стейтом idle или buffering
    if (!_isToggling) {
      bool actualPlayingState = player.playing;
      if (!_audioService.isPodcastMode) {
        actualPlayingState = _audioService.isRadioPlaying;
      }
      if (_playingNotifier.value != actualPlayingState) {
        _playingNotifier.value = actualPlayingState;
      }
    }

    if (_positionNotifier.value != position) _positionNotifier.value = position;
    if (_durationNotifier.value != duration) _durationNotifier.value = duration;

    final newMeta = _audioService.currentMetadata;
    final oldMeta = _metadataNotifier.value;
    
    if (oldMeta?.title != newMeta?.title || oldMeta?.artUrl != newMeta?.artUrl) {
      _metadataNotifier.value = newMeta;
    }
  }

  Future<void> _setVolume(double volume) async {
    try {
      final player = _audioService.getPlayer();
      await player?.setVolume(volume);
      _volumeNotifier.value = volume;
    } catch (e) {
      _showErrorSnackBar('${AppStrings.volumeError}: $e');
    }
  }

  // ignore: unused_element
  Future<void> _increaseVolume() async {
    try {
      final currentVolume = _volumeNotifier.value;
      final newVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
      await _setVolume(newVolume);
    } catch (e) {
      _showErrorSnackBar('${AppStrings.volumeError}: $e');
    }
  }

  String? _lastArtUrl;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxPlayerHeight = screenHeight * AppDimens.playerMaxHeightFactor;
    final bool isCompact = maxPlayerHeight < AppDimens.playerCompactThreshold;

    final double playButtonSize = isCompact
        ? AppDimens.playerPlayButtonCompact
        : AppDimens.playerPlayButton;
    final double skipIconSize =
        isCompact ? AppDimens.playerSkipIconCompact : AppDimens.playerSkipIcon;
    final double coverSize =
        isCompact ? AppDimens.playerCoverCompact : AppDimens.playerCover;

    final double smallSpacing =
        isCompact ? AppSpacing.xxsmall : AppSpacing.xsmall;
    final double mediumSpacing =
        isCompact ? AppSpacing.xsmallPlus : AppSpacing.small;
    final double largeSpacing =
        isCompact ? AppSpacing.smallMid : AppSpacing.smallPlus;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxPlayerHeight),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==================== PLAYBACK CONTROLS ====================
            // Кнопки «предыдущий / следующий» есть только у подкастов.
            // В режиме live-радио они скрыты, Play остаётся по центру.
            // ListenableBuilder перерисовывает ряд при смене режима.
            ListenableBuilder(
              listenable: _audioService,
              builder: (context, _) {
                final bool isPodcast = _audioService.isPodcastMode;
                return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isPodcast) ...[
                  IconButton(
                    icon: Icon(Icons.skip_previous, size: skipIconSize),
							
                    onPressed: _playPreviousPodcast,
													
                    color: AppColors.customWhite,
											 
                  ),
                  SizedBox(width: mediumSpacing),
                ],

                // ===== LARGER PLAY / PAUSE BUTTON =====
                ValueListenableBuilder<bool>(
                  valueListenable: _playingNotifier,
                  builder: (context, playing, __) {
                    return Container(
                      width: playButtonSize,
                      height: playButtonSize,
                      decoration: BoxDecoration(
                        color: _isToggling
                            ? AppColors.customStyle.withValues(alpha: 0.6)
                            : AppColors.customStyle,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.customStyle.withValues(alpha: 0.35),
                            blurRadius: AppDimens.playerGlowBlur,
                            spreadRadius: AppDimens.playerGlowSpread,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: _isToggling
                            ? SizedBox(
                                width: playButtonSize * 0.4,
                                height: playButtonSize * 0.4,
                                child: const CircularProgressIndicator(
                                  strokeWidth: AppDimens.progressStroke,
                                  color: AppColors.customWhite,
                                ),
                              )
                            : Icon(
                                playing ? Icons.pause : Icons.play_arrow,
                                size: playButtonSize * 0.5,
                              ),
                        onPressed: _isToggling
                            ? null
                            : () async {
                                await _togglePlayPause();
                              },
                        color: AppColors.customBackgr,
                        padding: EdgeInsets.zero,
                      ),
                    );
                  },
                ),
                if (isPodcast) ...[
                  SizedBox(width: mediumSpacing),

                  IconButton(
                    icon: Icon(Icons.skip_next, size: skipIconSize),
							
                    onPressed: _playNextPodcast,
													
                    color: AppColors.customWhite,
											 
                  ),
                ],
              ],
                );
              },
            ),
            SizedBox(height: largeSpacing),

            // ============ ALBUM COVER + TRACK INFO ============
            Padding(
              padding: EdgeInsets.symmetric(horizontal: largeSpacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Центрируем весь блок
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ---- ALBUM COVER ----
                  ValueListenableBuilder<int>(
                    valueListenable: _imageUpdateNotifier,
                    builder: (_, imageVersion, __) {
                      return ValueListenableBuilder<AudioMetadata?>(
                        valueListenable: _metadataNotifier,
                        builder: (_, metadata, __) {
                          return Container(
                            width: coverSize,
                            height: coverSize,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.small),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.small),
                              child: _buildCoverImage(metadata, imageVersion),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  SizedBox(width: mediumSpacing),

                  // ---- TRACK INFO ----
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.stringPlaying,
                          style: AppTextStyles.playerHeader,
                        ),
                        const SizedBox(height: AppSpacing.xxsmall),

                        ValueListenableBuilder<AudioMetadata?>(
                          valueListenable: _metadataNotifier,
                          builder: (_, metadata, __) {
                            final title = metadata?.title ?? AppStrings.radioTitle;
                            return Text(
                              title,
                              style: AppTextStyles.playerTrackTitle.copyWith(
                                fontSize: isCompact
                                    ? AppFontSizes.playerTitle
                                    : AppFontSizes.largeTitle,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxsmall),

                        ValueListenableBuilder<AudioMetadata?>(
                          valueListenable: _metadataNotifier,
                          builder: (_, metadata, __) {
                            return Text(
                              metadata?.artist ?? AppStrings.radioArtist,
                              style: AppTextStyles.playerTrackArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: largeSpacing),

            // ==================== VOLUME SLIDER ====================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: largeSpacing),
              child: Row(
                children: [
                  // Иконка громкости (контурная, светло-серая)
                  ValueListenableBuilder<double>(
                    valueListenable: _volumeNotifier,
                    builder: (_, volume, __) {
                      return IconButton(
                        icon: Icon(
                          volume == 0.0 
                              ? Icons.volume_off_outlined 
                              : Icons.volume_up_outlined, 
                        ),
                        onPressed: () {
                          if (volume == 0.0) {
                            _setVolume(1.0); 
                          } else {
                            _setVolume(0.0); 
                          }
                        },
                        color: AppColors.iconMuted,
                        iconSize: AppIconSizes.mediumPlus,
                        tooltip: volume == 0.0
                            ? AppStrings.volumeUnmute
                            : AppStrings.volumeMute,
                      );
                    },
                  ),
                  SizedBox(width: smallSpacing),

                  // Ползунок
                  Expanded(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _volumeNotifier,
                      builder: (_, volume, __) {
                        return SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            overlayShape: SliderComponentShape.noOverlay,
                            activeTrackColor: AppColors.customStyle,
                            inactiveTrackColor: AppColors.volumeTrackInactive,
                            thumbColor: AppColors.customStyle,
                            trackShape: const CustomRoundedSliderTrackShape(
                              borderColor: AppColors.iconMuted,
                            ),
                            trackHeight: AppDimens.volumeTrackHeight,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: AppDimens.volumeThumbRadius,
                              elevation: 0,
                              pressedElevation: 0,
                            ),
                          ),
                          child: Slider(
                            value: volume.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            divisions: null,
                            onChanged: (value) {
                              _volumeNotifier.value = value;
                            },
                            onChangeEnd: (value) {
                              _setVolume(value);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimens.volumeRightInset),
                ],
              ),
            ),
            SizedBox(height: smallSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(AudioMetadata? metadata, int imageVersion) {
    // Podcast
    if (_audioService.isPodcastMode && _audioService.currentEpisode != null) {
      final episode = _audioService.currentEpisode!;
      final imageUrl = episode.imageUrl ?? episode.channelImageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        _lastArtUrl = imageUrl;
        return _buildNetworkImage(imageUrl, imageVersion);
      }
      return _buildDefaultCover();
    }

    // Radio: только настоящий URL (http/https) считаем "настоящей" обложкой
    final artUrl = metadata?.artUrl;
    final isRealUrl = artUrl != null &&
        (artUrl.startsWith('http://') || artUrl.startsWith('https://'));

    if (isRealUrl) {
      _lastArtUrl = artUrl;
      return _buildNetworkImage(artUrl, imageVersion);
    }

    // Дефолтная обложка / metadata == null → «липкая» последняя реальная
    if (_lastArtUrl != null) {
      return _buildNetworkImage(_lastArtUrl!, imageVersion);
    }

    // Совсем нет ничего (первый запуск) → asset
    return _buildRadioPlaceholder();
  }

  Widget _buildNetworkImage(String imageUrl, int imageVersion) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      key: ValueKey(imageUrl),          // ← без '$'
      gaplessPlayback: true,
      cacheWidth: 200,
      filterQuality: FilterQuality.low,
      errorBuilder: (context, error, stackTrace) {
        return _audioService.isPodcastMode
            ? _buildDefaultCover()
            : _buildRadioPlaceholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        // Пока грузится новая — держим последнюю известную
        if (_lastArtUrl != null && _lastArtUrl != imageUrl) {
          return _buildNetworkImage(_lastArtUrl!, 0);
        }
        return const SizedBox.expand();
      },
    );
  }
  // Бледная иконка радио для состояния "нет метаданных"
  // Бледная (серая) иконка радио для состояния "нет метаданных"
  Widget _buildRadioPlaceholder() {
    return Container(
      // Убрали черный цвет фона AppColors.appBarBackground, 
      // теперь если картинка прозрачная, будет виден фон плеера.
      color: AppColors.customTransp,
      child: Center(
        child: Image.asset(
          AppAssets.defaultCover,
          fit: BoxFit.contain,
          gaplessPlayback: true, 
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      color: AppColors.cardBackground, // Для подкастов оставили темный фон
      child: Center(
        child: Image.asset(
          AppAssets.defaultCover,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  Future<void> _playNextPodcast() async {
    try {
      await _audioService.playNextPodcast();
    } catch (e) {
      _showErrorSnackBar('${AppStrings.nextEpisodeError}: $e');
    }
  }

  Future<void> _playPreviousPodcast() async {
    try {
      await _audioService.playPreviousPodcast();
    } catch (e) {
      _showErrorSnackBar('${AppStrings.previousEpisodeError}: $e');
    }
  }

  @override
  void dispose() {
    _playbackSub?.cancel();
    _syncTimer?.cancel();
    _metadataNotifier.dispose();
    _playingNotifier.dispose();
    _positionNotifier.dispose();
    _durationNotifier.dispose();
    _imageUpdateNotifier.dispose();
    _volumeNotifier.dispose();
    _audioService.removeListener(_onAudioServiceUpdate);
    super.dispose();
  }
}

// Вспомогательный класс для двух ValueNotifier
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, __) {
            return builder(context, a, b, child);
          },
        );
      },
    );
  }
}

// =============================================================
// КАСТОМНЫЙ ТРЕК ДЛЯ ПОЛЗУНКА (С ОБВОДКОЙ)
// =============================================================
class CustomRoundedSliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  final Color borderColor;

  const CustomRoundedSliderTrackShape({required this.borderColor});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    final Rect trackRect = Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
    final double radius = trackHeight / 2;

    // 1. Рисуем обводку (контур) на весь трек
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final canvas = context.canvas;
    final RRect rrect = RRect.fromRectAndRadius(trackRect, Radius.circular(radius));
    canvas.drawRRect(rrect, borderPaint);

    // 2. Рисуем неактивную часть (правую)
    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? AppColors.customTransp
      ..style = PaintingStyle.fill;

    final Rect rightTrackRect = Rect.fromLTRB(
      thumbCenter.dx,
      trackTop + 1,
      trackRect.right,
      trackRect.bottom - 1,
    );
    final RRect rightRRect = RRect.fromRectAndRadius(rightTrackRect, Radius.circular(radius - 1));
    context.canvas.drawRRect(rightRRect, inactivePaint);

    // 3. Рисуем активную часть (левую)
    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? AppColors.customTransp
      ..style = PaintingStyle.fill;

    final Rect leftTrackRect = Rect.fromLTRB(
      trackRect.left + 1,
      trackTop + 1,
      thumbCenter.dx,
      trackRect.bottom - 1,
    );
    final RRect leftRRect = RRect.fromRectAndRadius(leftTrackRect, Radius.circular(radius - 1));
    context.canvas.drawRRect(leftRRect, activePaint);
  }

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}