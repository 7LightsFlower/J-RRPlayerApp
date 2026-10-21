import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/services/audio_player_service.dart';

class AnimatedRadioButton extends StatelessWidget {
  final double screenWidth;

  const AnimatedRadioButton({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final double buttonSize = screenWidth * 0.5;

    return Consumer<AudioPlayerService>(
      builder: (context, service, _) {
        final bool hasConnection = service.hasNetworkConnection ?? true;
        final player = service.getPlayer();    // ← ВНУТРИ, перечитывается при каждом rebuild

        if (player == null) {
          return _buildStaticButton(context, service, buttonSize, hasConnection);
        }

        return StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final bool isPlaying = state?.playing ?? false;
            final bool isBuffering =
                state?.processingState == ProcessingState.loading ||
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

  Widget _buildButton(
    BuildContext context,
    AudioPlayerService service,
    double buttonSize, {
    required bool isPlaying,
    required bool isBuffering,
    required bool hasConnection,
  }) {
    // 1. Тонкая бледная полоса (4% от размера кнопки)
    final double paleRingWidth = buttonSize * 0.04; 

    // 2. Отступ до пунктира (равен двум ширинам полосы)
    final double gapToDashed = paleRingWidth * 2;

    // 3. Радиус заливки (иконка + тонкая полоса)
    final double bgRadius = (buttonSize / 2) + paleRingWidth;

    // 4. Общий размер холста для пунктира
    final double dashedCircleSize = buttonSize + (paleRingWidth + gapToDashed) * 2;

    // Цвет фона и пунктира
    final Color accentColor = hasConnection 
        ? AppColors.customStyle.withValues(alpha: isPlaying ? 0.15 : 0.05)
        : AppColors.customRed.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ============ СПЛОШНОЙ БЛЕДНЫЙ ФОН ============
          IgnorePointer(
            child: Container(
              width: bgRadius * 2,
              height: bgRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor, // Тот же бледный цвет, что был у кольца
              ),
            ),
          ),

          // ============ ПУНКТИРНАЯ ОКРУЖНОСТЬ ============
          IgnorePointer(
            child: _RotatingDashedCircle(
              size: dashedCircleSize, 
              color: hasConnection ? AppColors.customStyle : AppColors.customRed,
              isPlaying: isPlaying,
            ),
          ),

          // ============ ПЕРЕЧЁРКНУТО ПРИ ОБРЫВЕ СЕТИ ============
          if (!hasConnection && !isBuffering)
            _CrossLine(
              size: buttonSize * 0.75,
              verticalOffset: 0,
            ),

          // ============ КНОПКА ============
          _StaticIconButton(
            size: buttonSize,
            hasConnection: hasConnection,
            isBuffering: isBuffering,
            onPressed: () => service.toggleRadioOrPodcast(),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ВРАЩАЮЩАЯСЯ ПУНКТИРНАЯ ОКРУЖНОСТЬ
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

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_scaleController);

    if (widget.isPlaying) {
      _rotationController.repeat();
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(_RotatingDashedCircle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isPlaying && widget.isPlaying) {
      _scaleController.forward(from: 0);
      _rotationController.repeat();
    } else if (oldWidget.isPlaying && !widget.isPlaying) {
      _rotationController.stop();
      _scaleController.stop();
      _scaleController.value = 0;
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
        final double currentAngle = widget.isPlaying 
            ? _rotationController.value * 2 * pi 
            : 0.0;

        final double currentScale = widget.isPlaying 
            ? _scaleAnimation.value 
            : 1.0;

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
      ..strokeWidth = 2.5 // <-- СДЕЛАЛИ ЛИНИЮ ТОЛЩЕ (было 1.5)
      ..strokeCap = StrokeCap.round;

    final double radius = (size.width / 2) - 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    
    const int dashCount = 60; 
    const double dashAngle = (2 * pi) / dashCount;
    const double dashSweep = dashAngle * 0.3; 

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
// СТАТИЧНАЯ КНОПКА (БЕЗ СВЕЧЕНИЯ)
// =============================================================
class _StaticIconButton extends StatelessWidget {
  final double size;
  final bool hasConnection;
  final bool isBuffering;
  final VoidCallback onPressed;

  const _StaticIconButton({
    required this.size,
    required this.hasConnection,
    required this.isBuffering,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
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
            if (isBuffering)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  hasConnection
                      ? AppColors.customStyle
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
// КРЕСТ ПРИ ОБРЫВЕ СЕТИ
// =============================================================
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