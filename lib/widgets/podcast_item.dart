import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:jrrplayerapp/models/podcast.dart';
import 'package:jrrplayerapp/services/audio_player_service.dart';
import 'package:jrrplayerapp/repositories/podcast_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';

class PodcastItem extends StatefulWidget {
  final PodcastEpisode podcast;

  const PodcastItem({super.key, required this.podcast});

  @override
  State<PodcastItem> createState() => _PodcastItemState();
}

class _PodcastItemState extends State<PodcastItem> {
  bool _isLoading = false;
  bool _isSeeking = false;
  double _sliderValue = 0.0;
  Duration _currentPosition = Duration.zero;
  late AudioPlayerService _audioService;
  late PodcastRepository _podcastRepo;
  Duration? _cachedDuration;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _audioService = Provider.of<AudioPlayerService>(context, listen: false);
    _podcastRepo = Provider.of<PodcastRepository>(context, listen: false);

    _loadSavedPosition();

    _audioService.addListener(_onAudioServiceUpdate);
    _podcastRepo.addListener(_onPodcastRepoUpdate);
  }

  Future<void> _loadSavedPosition() async {
    final savedPosition = _podcastRepo.getEpisodePosition(widget.podcast.id);
    if (mounted) {
      setState(() {
        _currentPosition = savedPosition;
        final actualDuration = _getActualDuration();
        if (actualDuration != null && actualDuration.inMilliseconds > 0) {
          _sliderValue =
              savedPosition.inMilliseconds / actualDuration.inMilliseconds;
        }
      });
    }
  }

  void _onPodcastRepoUpdate() {
    final savedPosition = _podcastRepo.getEpisodePosition(widget.podcast.id);
    if (savedPosition != _currentPosition && !_isSeeking) {
      setState(() {
        _currentPosition = savedPosition;
        final actualDuration = _getActualDuration();
        if (actualDuration != null && actualDuration.inMilliseconds > 0) {
          _sliderValue =
              savedPosition.inMilliseconds / actualDuration.inMilliseconds;
        }
      });
    }
  }

  void _onAudioServiceUpdate() {
    if (!mounted) return;
    if (_audioService.currentEpisode?.id == widget.podcast.id) {
      final currentDuration = _audioService.currentEpisode?.duration;
      if (currentDuration != null && currentDuration > Duration.zero) {
        setState(() {
          _cachedDuration = currentDuration;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioServiceUpdate);
    _podcastRepo.removeListener(_onPodcastRepoUpdate);
    _positionSubscription?.cancel();
    super.dispose();
  }

  // ==================== COVER IMAGE ====================
  Widget _buildCover() {
    const double size = 80.0;
    if (widget.podcast.imageUrl != null &&
        widget.podcast.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: widget.podcast.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _buildDefaultCover(size),
          placeholder: (context, url) => _buildDefaultCover(size),
        ),
      );
    }
    return _buildDefaultCover(size);
  }

  Widget _buildDefaultCover(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF232A36),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.podcasts,
        color: AppColors.customStyle,
        size: 32,
      ),
    );
  }

  // ==================== PLAYBACK ====================
  Future<void> _togglePlayPause(AudioPlayerService audioService) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isCurrentPodcastPlaying = _isPodcastPlaying(audioService);

      if (isCurrentPodcastPlaying) {
        await audioService.pause();
      } else {
        await audioService.playPodcastFromPosition(
          widget.podcast,
          _currentPosition,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ошибка воспроизведения: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.medium,
        ),
        backgroundColor: AppColors.customRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _seekPodcast(double value, AudioPlayerService audioService) {
    final Duration? actualDuration = _getActualDuration();
    if (actualDuration == null || actualDuration.inMilliseconds == 0) return;

    final newPosition = Duration(
      milliseconds: (value * actualDuration.inMilliseconds).round(),
    );

    setState(() {
      _currentPosition = newPosition;
      _sliderValue = value;
    });

    _podcastRepo.updateEpisodePosition(widget.podcast.id, newPosition);
    audioService.seekPodcast(newPosition);
  }

  /// Renders the episode title with the segment before '|' on the first
  /// line in the accent color, and the segment after '|' on the second
  /// line in white. The '|' itself is hidden.
  /// Falls back to plain white (single line) if there's no '|'.
  Widget _buildHighlightedTitle(String title) {
    final TextStyle baseStyle = AppTextStyles.podcastTitle.copyWith(
      height: 1.5,   // ← больше вертикального расстояния между строками
    );

    final int barIndex = title.indexOf('|');

    if (barIndex == -1) {
      // No separator — render the whole title in white.
      return Text(
        title,
        style: baseStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Prefix = everything BEFORE the '|' (trimmed).
    final String prefix = title.substring(0, barIndex).trimRight();
    // Suffix = everything AFTER the '|' (trimmed).
    final String suffix = title.substring(barIndex + 1).trimLeft();

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (prefix.isNotEmpty)
            TextSpan(
              text: prefix,
              style: baseStyle.copyWith(color: AppColors.customStyle),
            ),
          if (prefix.isNotEmpty && suffix.isNotEmpty)
            // Line break replaces the hidden '|'.
            const TextSpan(text: '\n'),
          if (suffix.isNotEmpty)
            TextSpan(
              text: suffix,
              style: baseStyle.copyWith(color: Colors.white),
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
    }
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  Duration? _getActualDuration() {
    if (_cachedDuration != null && _cachedDuration! > Duration.zero) {
      return _cachedDuration;
    }
    if (widget.podcast.duration != null &&
        widget.podcast.duration! > Duration.zero) {
      return widget.podcast.duration;
    }
    return null;
  }

  bool _isPodcastPlaying(AudioPlayerService audioService) {
    return audioService.currentEpisode?.id == widget.podcast.id &&
        audioService.isPodcastMode &&
        audioService.playerState?.playing == true;
  }

  bool _isPodcastBuffering(AudioPlayerService audioService) {
    return audioService.currentEpisode?.id == widget.podcast.id &&
        audioService.isPodcastMode &&
        (audioService.playerState?.processingState == ProcessingState.buffering ||
            audioService.playerState?.processingState == ProcessingState.loading ||
            audioService.isBuffering);
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioPlayerService>(context, listen: true);

    final podcast = _podcastRepo.getEpisodeById(widget.podcast.id);
    if (podcast == null) {
      return const SizedBox();
    }

    final bool isPlaying = _isPodcastPlaying(audioService);
    final bool isBuffering = _isPodcastBuffering(audioService);
    final Duration? actualDuration = _getActualDuration();

    // Attach position stream when this episode is playing
    if (isPlaying && _positionSubscription == null) {
      _positionSubscription = audioService.positionStream.listen((position) {
        if (!_isSeeking && mounted) {
          setState(() {
            _currentPosition = position;
            if (actualDuration != null && actualDuration.inMilliseconds > 0) {
              _sliderValue =
                  position.inMilliseconds / actualDuration.inMilliseconds;
            }
          });
          if (position.inSeconds % 5 == 0) {
            _podcastRepo.updateEpisodePosition(widget.podcast.id, position);
          }
        }
      });
    } else if (!isPlaying && _positionSubscription != null) {
      _podcastRepo.updateEpisodePosition(widget.podcast.id, _currentPosition);
      _positionSubscription?.cancel();
      _positionSubscription = null;
    }

    final progress = actualDuration != null && actualDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / actualDuration.inMilliseconds
        : 0.0;

    if (!_isSeeking) {
      _sliderValue = progress.clamp(0.0, 1.0);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F29),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== COVER =====
            _buildCover(),
            const SizedBox(width: 12),

            // ===== INFO + PROGRESS =====
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode title with the segment before '|' highlighted in teal
                  _buildHighlightedTitle(widget.podcast.title),
                  const SizedBox(height: 6),

                  // Progress bar (thin, teal, tappable via Slider)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: AppColors.customStyle,
                      inactiveTrackColor: const Color(0xFF2A3242),
                      thumbColor: AppColors.customStyle,
                      overlayColor: AppColors.customStyle.withValues(alpha: 0.15),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: _sliderValue,
                      min: 0.0,
                      max: 1.0,
                      onChanged: actualDuration != null &&
                              actualDuration.inMilliseconds > 0
                          ? (value) {
                              setState(() {
                                _isSeeking = true;
                                _sliderValue = value;
                              });
                            }
                          : null,
                      onChangeEnd: actualDuration != null &&
                              actualDuration.inMilliseconds > 0
                          ? (value) {
                              _seekPodcast(value, audioService);
                              setState(() {
                                _isSeeking = false;
                              });
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Time labels row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_currentPosition),
                        style: AppTextStyles.podcastMeta,
                      ),
                      Text(
                        _formatDuration(actualDuration),
                        style: AppTextStyles.podcastMeta,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ===== PLAY / PAUSE CIRCLE =====
            _buildPlayButton(
              isPlaying: isPlaying,
              isBuffering: isBuffering,
              onTap: () => _togglePlayPause(audioService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton({
    required bool isPlaying,
    required bool isBuffering,
    required VoidCallback onTap,
  }) {
    const double size = 52.0;

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.customStyle, width: 2),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: (_isLoading || isBuffering) ? null : onTap,
          child: Center(
            child: (_isLoading || isBuffering)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.customStyle,
                      ),
                    ),
                  )
                : Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: AppColors.customStyle,
                    size: 30,
                  ),
          ),
        ),
      ),
    );
  }
}