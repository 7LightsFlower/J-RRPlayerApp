import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_strings.dart';
import 'package:jrrplayerapp/services/audio_player_service.dart';

class RadioButtonWithWaves extends StatelessWidget {
  final double screenWidth;

  const RadioButtonWithWaves({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final double buttonSize = screenWidth * AppDimens.radioButtonFactor;

    return Consumer<AudioPlayerService>(
      builder: (context, service, _) {
        final bool hasConnection = service.hasNetworkConnection ?? true;
        // Читаем плеер ВНУТРИ builder: иначе кнопка «залипает» в статичном
        // состоянии, если плеер создаётся позже первого build.
        final player = service.getPlayer();

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
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxsmall),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ============ ЗАЛИВКА ПРОСТРАНСТВА (УЗКОЕ КОЛЬЦО) ============
          IgnorePointer(
            child: CustomPaint(
              size: Size(buttonSize * 1.20, buttonSize * 1.20),
              painter: _RingFillPainter(
                innerRadius: buttonSize / 2, 
                // Заливаем только половину пространства. 
                // Если иконка buttonSize, а пунктир buttonSize * 1.20, 
                // то половина пути — это 1.10.
                outerRadius: (buttonSize * 1.10) / 2, 
                color: hasConnection 
                    ? AppColors.customStyle.withValues(alpha: isPlaying ? 0.15 : 0.05)
                    : AppColors.customRed.withValues(alpha: 0.15),
              ),
            ),
          ),
          // ============ ПУНКТИРНАЯ ОКРУЖНОСТЬ ============
          IgnorePointer(
            child: _RotatingDashedCircle(
              size: buttonSize * 1.20, // Сделал чуть больше (было 1.15), чтобы края не слипались
              color: hasConnection ? AppColors.customStyle : AppColors.customRed,
              isPlaying: isPlaying,
            ),
          ),

          // ============ ВОЛНЫ ============
          if (!isBuffering)
            ..._buildWaveLayers(buttonSize, isPlaying, hasConnection)
                .map((w) => IgnorePointer(child: w)),

          // ============ ПЕРЕЧЁРКНУТО ПРИ ОБРЫВЕ СЕТИ ============
          if (!hasConnection && !isBuffering)
            _CrossLine(
              size: buttonSize * 0.5,
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
      hasConnection ? AppColors.customWhite : AppColors.customRed;
}

// =============================================================
// ВРАЩАЮЩАЯСЯ ПУНКТИРНАЯ ОКРУЖНОСТЬ (С ПУЛЬСАЦИЕЙ)
// =============================================================
class _RotatingDashedCircle extends StatefulWidget {
  final double size;
  final Color color;
  final bool isPlaying;

  const _RotatingDashedCircle({
    required this.size,
    required this.color,
    required this.isPlaying,
  });

  @override
  State<_RotatingDashedCircle> createState() => _RotatingDashedCircleState();
}

class _RotatingDashedCircleState extends State<_RotatingDashedCircle>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Контроллер вращения
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    // 2. Контроллер пульсации
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_scaleController);

    // Если при инициализации уже играет — запускаем
    if (widget.isPlaying) {
      _rotationController.repeat();
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(_RotatingDashedCircle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isPlaying && widget.isPlaying) {
      // Включили: пульсация + вращение
      _scaleController.forward(from: 0);
      _rotationController.repeat();
    } else if (oldWidget.isPlaying && !widget.isPlaying) {
      // Выключили: останавливаем вращение
      _rotationController.stop();
      _scaleController.stop();
      _scaleController.value = 0; // Сбрасываем масштаб до 1.0
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _scaleController]),
      builder: (context, child) {
        // Если не играет — бледная и не вращается (угол 0)
        final double currentAngle = widget.isPlaying 
            ? _rotationController.value * 2 * pi 
            : 0.0;

        // Масштаб применяем только если играет
        final double currentScale = widget.isPlaying 
            ? _scaleAnimation.value 
            : 1.0;

        // Прозрачность: 0.8 если играет, 0.2 если на паузе
        final double opacity = widget.isPlaying ? 0.8 : 0.2;

        return Transform.rotate(
          angle: currentAngle,
          child: Transform.scale(
            scale: currentScale,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _DashedCirclePainter(
                color: widget.color,
                opacity: opacity,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double opacity;

  _DashedCirclePainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 // Можно сделать чуть тоньше (например, 1.2), чтобы смотрелось аккуратнее
      ..strokeCap = StrokeCap.round;

    final double radius = (size.width / 2) - 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    
    // БЫЛО: const int dashCount = 36;
    // СТАЛО: 
    const int dashCount = 60; // Увеличили количество штрихов (чем больше, тем мельче пунктир)
    
    const double dashAngle = (2 * pi) / dashCount;
    
    // БЫЛО: final double dashSweep = dashAngle * 0.5; 
    // СТАЛО:
    const double dashSweep = dashAngle * 0.3; // Штрих занимает 30% от шага, а 70% — это пробел

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashSweep,
        false,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}

// =============================================================
// ПЕЙНТЕР ДЛЯ ЗАЛИВКИ КОЛЬЦА МЕЖДУ ИКОНКОЙ И ПУНКТИРОМ
// =============================================================
class _RingFillPainter extends CustomPainter {
  final double innerRadius;
  final double outerRadius;
  final Color color;

  _RingFillPainter({
    required this.innerRadius,
    required this.outerRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Рисуем круг большего радиуса
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerRadius))
      // Вырезаем внутренний круг (где находится иконка)
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius))
      ..fillType = PathFillType.evenOdd; // Режим, при котором вырезается середина

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RingFillPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.innerRadius != innerRadius ||
        oldDelegate.outerRadius != outerRadius;
  }
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
                    BoxShadow(
                      color: AppColors.customStyle
                          .withValues(alpha: 0.15 + 0.15 * t),
                      blurRadius: 28 + 20 * t,
                      spreadRadius: 0,
                    ),
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
              AppAssets.radioButtonIcon,
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
            if (widget.isBuffering)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.hasConnection
                      ? AppColors.customWhite
                      : AppColors.customRed,
                ),
                strokeWidth: AppDimens.progressStroke,
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