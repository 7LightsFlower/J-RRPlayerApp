import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/services/audio_player_service.dart';

class RadioButtonWithWaves extends StatelessWidget {
  final double screenWidth;

  const RadioButtonWithWaves({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final double buttonSize = screenWidth * 0.5;
    final audioService = context.read<AudioPlayerService>();
    final player = audioService.getPlayer();

    return Consumer<AudioPlayerService>(
      builder: (context, service, _) {
        final bool hasConnection = service.hasNetworkConnection ?? true;

        // Если плеер ещё не создан — рисуем кнопку в «спокойном» состоянии.
        if (player == null) {
          return _buildStaticButton(context, service, buttonSize, hasConnection);
        }

        // Слушаем реальные события just_audio напрямую.
        return StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final bool isPlaying = state?.playing ?? false;
            final bool isBuffering = state?.processingState == ProcessingState.loading ||
                state?.processingState == ProcessingState.buffering;

            return _buildButton(
              context,
              service,
              buttonSize,
              isPlaying: isPlaying,
              isBuffering: isBuffering,
              hasConnection: hasConnection,
            );
          },
        );
      },
    );
  }

  // -------------------- СТАТИЧНАЯ КНОПКА (плеер ещё не готов) --------------------
  Widget _buildStaticButton(
    BuildContext context,
    AudioPlayerService service,
    double buttonSize,
    bool hasConnection,
  ) {
    return _buildButton(
      context,
      service,
      buttonSize,
      isPlaying: false,
      isBuffering: false,
      hasConnection: hasConnection,
    );
  }

  // -------------------- ОБЩИЙ BUILD --------------------
  Widget _buildButton(
    BuildContext context,
    AudioPlayerService service,
    double buttonSize, {
    required bool isPlaying,
    required bool isBuffering,
    required bool hasConnection,
  }) {
    // Свечение — только когда реально играет, не грузится и есть сеть.
    final bool showGlow = isPlaying && !isBuffering && hasConnection;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ============ ВОЛНЫ ============
          if (!isBuffering)
            ..._buildWaveLayers(buttonSize, isPlaying, hasConnection)
                .map((w) => IgnorePointer(child: w)),

          // ============ ПЕРЕЧЁРКНУТО ПРИ ОБРЫВЕ СЕТИ ============
          if (!hasConnection && !isBuffering)
            _CrossLine(
              size: buttonSize * 0.75,
              verticalOffset: -buttonSize * 0.15,
            ),

          // ============ КНОПКА СО СВЕЧЕНИЕМ ============
          _GlowingIconButton(
            size: buttonSize,
            showGlow: showGlow,
            hasConnection: hasConnection,
            isBuffering: isBuffering,
            onPressed: () => service.toggleRadioOrPodcast(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWaveLayers(
    double buttonSize,
    bool isPlaying,
    bool hasConnection,
  ) {
    final waveColor = _getWaveColor(hasConnection);
    return [
      _AnimatedWave(
        color: waveColor,
        size: buttonSize * 0.50,
        delay: 0,
        verticalOffset: -buttonSize * 0.15,
        isPlaying: isPlaying,
      ),
      _AnimatedWave(
        color: waveColor,
        size: buttonSize * 0.30,
        delay: 500,
        verticalOffset: -buttonSize * 0.15,
        isPlaying: isPlaying,
      ),
      _AnimatedWave(
        color: waveColor,
        size: buttonSize * 0.10,
        delay: 1000,
        verticalOffset: -buttonSize * 0.15,
        isPlaying: isPlaying,
      ),
    ];
  }

  Color _getWaveColor(bool hasConnection) =>
      hasConnection ? AppColors.customGreen : AppColors.customRed;
}

// =============================================================
// КНОПКА С ПУЛЬСИРУЮЩИМ СВЕЧЕНИЕМ
// =============================================================
class _GlowingIconButton extends StatefulWidget {
  final double size;
  final bool showGlow;
  final bool hasConnection;
  final bool isBuffering;
  final VoidCallback onPressed;

  const _GlowingIconButton({
    required this.size,
    required this.showGlow,
    required this.hasConnection,
    required this.isBuffering,
    required this.onPressed,
  });

  @override
  State<_GlowingIconButton> createState() => _GlowingIconButtonState();
}

class _GlowingIconButtonState extends State<_GlowingIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    if (widget.showGlow) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_GlowingIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGlow && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.showGlow && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final double t = widget.showGlow ? _pulse.value : 0.0;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.showGlow
                ? [
                    // Мягкое внешнее гало (без spreadRadius, чтобы не заходило под иконку)
                    BoxShadow(
                      color: AppColors.customStyle
                          .withValues(alpha: 0.15 + 0.15 * t),
                      blurRadius: 28 + 20 * t,
                      spreadRadius: 0,
                    ),
                    // Более широкое и совсем слабое свечение по краям
                    BoxShadow(
                      color: AppColors.customStyle
                          .withValues(alpha: 0.05 + 0.08 * t),
                      blurRadius: 55 + 25 * t,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.customTransp,
          foregroundColor: AppColors.customBackgr,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/icon_jrockradio_custom_style.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
            if (widget.isBuffering)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.hasConnection
                      ? AppColors.customGreen
                      : AppColors.customRed,
                ),
                strokeWidth: 2,
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================

// АНИМИРОВАННАЯ ВОЛНА
// =============================================================
class _AnimatedWave extends StatefulWidget {
  final Color color;
  final double size;
  final int delay;
  final double verticalOffset;
  final bool isPlaying;

  const _AnimatedWave({
    required this.color,
    required this.size,
    required this.delay,
    required this.verticalOffset,
    required this.isPlaying,
  });

  @override
  State<_AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<_AnimatedWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: false);

    // Сдвигаем старт анимации в зависимости от widget.delay.
    // delay = 0    → старт сразу (begin = 0.0)
    // delay = 500  → старт через 500 мс из 2000 (begin = 0.25)
    // delay = 1000 → старт через 1000 мс из 2000 (begin = 0.5)
    final double begin = (widget.delay / 2000).clamp(0.0, 1.0);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Волна видна только когда играет; иначе — alpha = 0.
        final double visible = widget.isPlaying ? 1.0 : 0.0;
        final double opacityValue = (0.7 - (_animation.value * 0.6)) * visible;
        final int alpha = (opacityValue * 255).round();
        final Color animatedColor = widget.color.withAlpha(alpha);

        return Transform.translate(
          offset: Offset(0, widget.verticalOffset),
          child: Opacity(
            opacity: (1.0 - _animation.value) * visible,
            child: Transform.rotate(
              angle: 120 * (pi / 180),
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _WaveArcPainter(
                  color: animatedColor,
                  startAngle: 120 * (pi / 180),
                  sweepAngle: 60 * (pi / 180),
                  animationValue: _animation.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveArcPainter extends CustomPainter {
  final Color color;
  final double startAngle;
  final double sweepAngle;
  final double animationValue;

  const _WaveArcPainter({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + (animationValue * 0.5)
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - paint.strokeWidth) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CrossLine extends StatelessWidget {
  final double size;
  final double verticalOffset;

  const _CrossLine({required this.size, required this.verticalOffset});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _CrossLinePainter()),
      ),
    );
  }
}

class _CrossLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.customRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}