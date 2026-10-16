import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/services/audio_player_service.dart';
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
  late final ValueNotifier<Duration?> _positionNotifier;
  late final ValueNotifier<Duration?> _durationNotifier;
  late final ValueNotifier<AudioMetadata?> _metadataNotifier;
  late final ValueNotifier<int> _imageUpdateNotifier;
  late final ValueNotifier<double> _volumeNotifier;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();

    _audioService = Provider.of<AudioPlayerService>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSyncState();
      _printRadioState();
    });

    _audioService.playbackStateStream.listen((isPlaying) {
      if (mounted) {
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

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _syncPlayerState();
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

    _positionNotifier = _StreamValueNotifier<Duration?>(
      player?.positionStream ?? Stream.value(Duration.zero),
      player?.position ?? Duration.zero,
    );

    _durationNotifier = _StreamValueNotifier<Duration?>(
      player?.durationStream ?? Stream.value(null),
      player?.duration,
    );

    _volumeNotifier = _StreamValueNotifier<double>(
      player?.volumeStream ?? Stream.value(1.0),
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

    final currentPlayingState = _audioService.isPlaying;
    _playingNotifier.value = currentPlayingState;

    _syncPlayerState();

    final newMetadata = _audioService.currentMetadata;
    if (_metadataNotifier.value != newMetadata) {
      _metadataNotifier.value = newMetadata;
      _imageUpdateNotifier.value++;
    }

    if (mounted) {
      setState(() {
        _playingNotifier.value = _audioService.isPlaying;
      });
    }
  }

  Future<void> _checkAndSyncState() async {
    if (!mounted) return;

    final player = _audioService.getPlayer();
    final isActuallyPlaying = player?.playing ?? false;
    final serviceSaysPlaying = _audioService.isPlaying;

    if (isActuallyPlaying != serviceSaysPlaying) {
      _playingNotifier.value = isActuallyPlaying;
      if (mounted) setState(() {});
    }

    Future.delayed(const Duration(seconds: 2), _checkAndSyncState);
  }

  Future<void> _togglePlayPause() async {
    if (_isToggling) {
      debugPrint('🎵 Toggle ignored: already toggling');
      return;
    }

    setState(() {
      _isToggling = true;
    });

    try {
      final isCurrentlyPlaying = _audioService.isPlaying;

      if (isCurrentlyPlaying) {
        debugPrint('🎵 Switching to PAUSE');
        unawaited(_audioService.pause());
      } else {
        debugPrint('🎵 Switching to PLAY');

        if (_audioService.isPodcastMode &&
            _audioService.currentEpisode != null) {
          unawaited(_audioService.playPodcast(_audioService.currentEpisode!));
        } else {
          _audioService.getPlayer();
          final isRadioPaused = _audioService.isRadioPaused;

          debugPrint('🎵 Radio state: paused=$isRadioPaused');

          if (isRadioPaused) {
            unawaited(_audioService.resumeRadioFromPause());
          } else {
            unawaited(_audioService.playRadio());
          }
        }
      }

      if (mounted) {
        setState(() {
          _playingNotifier.value = !isCurrentlyPlaying;
        });
      }
    } catch (e) {
      debugPrint('🎵 Error in toggle play/pause: $e');
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      } else {
        _isToggling = false;
      }
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
    if (player != null) {
      final isPlaying = player.playing;
      final position = player.position;
      final duration = player.duration;

      bool actualPlayingState = isPlaying;
      if (!_audioService.isPodcastMode) {
        actualPlayingState = _audioService.isRadioPlaying;
      }

      _playingNotifier.value = actualPlayingState;

      if (_positionNotifier.value != position) {
        _positionNotifier.value = position;
      }

      if (_durationNotifier.value != duration) {
        _durationNotifier.value = duration;
      }

      final newMetadata = _audioService.currentMetadata;
      if (_metadataNotifier.value != newMetadata) {
        _metadataNotifier.value = newMetadata;
      }
    }
  }

  Future<void> _setVolume(double volume) async {
    try {
      final player = _audioService.getPlayer();
      await player?.setVolume(volume);
      _volumeNotifier.value = volume;
    } catch (e) {
      _showErrorSnackBar('Error setting volume: $e');
    }
  }

  Future<void> _increaseVolume() async {
    try {
      final currentVolume = _volumeNotifier.value;
      final newVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
      await _setVolume(newVolume);
    } catch (e) {
      _showErrorSnackBar('Error increasing volume: $e');
    }
  }

  Future<void> _decreaseVolume() async {
    try {
      final currentVolume = _volumeNotifier.value;
      final newVolume = (currentVolume - 0.1).clamp(0.0, 1.0);
      await _setVolume(newVolume);
    } catch (e) {
      _showErrorSnackBar('Error decreasing volume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxPlayerHeight = screenHeight * 0.6;
    final bool isCompact = maxPlayerHeight < 400;

    final double playButtonSize = isCompact ? 68.0 : 84.0;
    final double skipIconSize = isCompact ? 32.0 : 38.0;
    final double coverSize = isCompact ? 72.0 : 88.0;

    final double smallSpacing = isCompact ? 4.0 : 8.0;
    final double mediumSpacing = isCompact ? 10.0 : 16.0;
    final double largeSpacing = isCompact ? 14.0 : 20.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxPlayerHeight),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==================== PLAYBACK CONTROLS ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous, size: skipIconSize),
                  onPressed:
                      _audioService.isPodcastMode ? _playPreviousPodcast : null,
                  color: _audioService.isPodcastMode
                      ? AppColors.customWhite
                      : AppColors.customGrey,
                ),
                SizedBox(width: mediumSpacing),

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
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: _isToggling
                            ? SizedBox(
                                width: playButtonSize * 0.4,
                                height: playButtonSize * 0.4,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
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
                SizedBox(width: mediumSpacing),

                IconButton(
                  icon: Icon(Icons.skip_next, size: skipIconSize),
                  onPressed:
                      _audioService.isPodcastMode ? _playNextPodcast : null,
                  color: _audioService.isPodcastMode
                      ? AppColors.customWhite
                      : AppColors.customGrey,
                ),
              ],
            ),
            SizedBox(height: largeSpacing),

            // ============ ALBUM COVER + TRACK INFO (FIXED LAYOUT) ============
            Padding(
              padding: EdgeInsets.symmetric(horizontal: largeSpacing),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ---- ALBUM COVER (фиксированная ширина) ----
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
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.customTransp,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _buildCoverImage(metadata, imageVersion),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(width: mediumSpacing),

                  // ---- TRACK INFO (занимает всё оставшееся место) ----
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "СЕЙЧАС В ЭФИРЕ"
                        Row(
                          children: [
                            const Icon(
                              Icons.bar_chart,
                              color: AppColors.customStyle,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'СЕЙЧАС В ЭФИРЕ',
                              style: TextStyle(
                                color: AppColors.customStyle
                                    .withValues(alpha: 0.85),
                                fontSize: AppFontSizes.small,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Track title
                        ValueListenableBuilder<AudioMetadata?>(
                          valueListenable: _metadataNotifier,
                          builder: (_, metadata, __) {
                            final title =
                                metadata?.title ?? 'Радио J-Rock';
                            return Text(
                              title,
                              style: TextStyle(
                                fontSize: isCompact ? AppFontSizes.compactLarge : AppFontSizes.large,
                                fontWeight: FontWeight.bold,
                                color: AppColors.customWhite,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                        const SizedBox(height: 4),

                        // Artist
                        ValueListenableBuilder<AudioMetadata?>(
                          valueListenable: _metadataNotifier,
                          builder: (_, metadata, __) {
                            return Text(
                              metadata?.artist ?? 'Онлайн радио',
                              style: TextStyle(
                                fontSize: isCompact ? AppFontSizes.medium : AppFontSizes.compactLarge,
                                color: AppColors.customWhite
                                    .withValues(alpha: 0.6),
                              ),
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

            // ==================== SINGLE VOLUME SLIDER ====================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: largeSpacing),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_mute),
                    onPressed: _decreaseVolume,
                    color: AppColors.customWhite.withValues(alpha: 0.7),
                    iconSize: 20,
                    tooltip: 'Тише',
                  ),
                  SizedBox(width: smallSpacing),

                  Expanded(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _volumeNotifier,
                      builder: (_, volume, __) {
                        return SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.customStyle,
                            inactiveTrackColor:
                                const Color(0xFF1C212B),
                            thumbColor: AppColors.customStyle,
                            overlayColor: AppColors.customStyle
                                .withValues(alpha: 0.2),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
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
                  SizedBox(width: smallSpacing),

                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: _increaseVolume,
                    color: AppColors.customWhite.withValues(alpha: 0.7),
                    iconSize: 20,
                    tooltip: 'Громче',
                  ),
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
    String? imageUrl = _getImageUrl(metadata);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        key: ValueKey('$imageUrl$imageVersion'),
        cacheWidth: 200,
        filterQuality: FilterQuality.low,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCover();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.customWhite,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      );
    } else {
      return _buildDefaultCover();
    }
  }

  String? _getImageUrl(AudioMetadata? metadata) {
    if (metadata?.artUrl != null && metadata!.artUrl.isNotEmpty) {
      return metadata.artUrl;
    }

    final episode = _audioService.currentEpisode;
    if (episode != null) {
      if (episode.imageUrl != null && episode.imageUrl!.isNotEmpty) {
        return episode.imageUrl;
      }
      if (episode.channelImageUrl != null &&
          episode.channelImageUrl!.isNotEmpty) {
        return episode.channelImageUrl;
      }
    }

    return null;
  }

  Widget _buildDefaultCover() {
    return Image.asset(
      'assets/images/default_cover.png',
      fit: BoxFit.cover,
    );
  }

  Future<void> _playNextPodcast() async {
    try {
      await _audioService.playNextPodcast();
    } catch (e) {
      _showErrorSnackBar('Error playing next podcast: $e');
    }
  }

  Future<void> _playPreviousPodcast() async {
    try {
      await _audioService.playPreviousPodcast();
    } catch (e) {
      _showErrorSnackBar('Error playing previous podcast: $e');
    }
  }

  @override
  void dispose() {
    _playingNotifier.dispose();
    _positionNotifier.dispose();
    _durationNotifier.dispose();
    _metadataNotifier.dispose();
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