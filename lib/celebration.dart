import 'dart:math';

import 'package:flutter/material.dart';

// Shows a short confetti burst over the whole
// screen. It removes itself when it finishes.
void showConfetti(BuildContext context) {
  final overlay = Overlay.maybeOf(context);

  if (overlay == null) {
    return;
  }

  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _ConfettiBurst(
      onDone: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _ConfettiPiece {
  final double startX;
  final double driftX;
  final double speed;
  final double size;
  final double spin;
  final Color color;

  const _ConfettiPiece({
    required this.startX,
    required this.driftX,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
  });
}

class _ConfettiBurst extends StatefulWidget {
  final VoidCallback onDone;

  const _ConfettiBurst({
    required this.onDone,
  });

  @override
  State<_ConfettiBurst> createState() =>
      _ConfettiBurstState();
}

class _ConfettiBurstState
    extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const colors = [
    Color(0xFF5E6AD2),
    Color(0xFF00A896),
    Color(0xFFFFB300),
    Color(0xFFE91E63),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
  ];

  late final AnimationController controller;

  late final List<_ConfettiPiece> pieces;

  @override
  void initState() {
    super.initState();

    final random = Random();

    pieces = List.generate(
      90,
      (_) => _ConfettiPiece(
        startX: random.nextDouble(),
        driftX:
            (random.nextDouble() - 0.5) * 0.4,
        speed:
            0.7 + random.nextDouble() * 0.6,
        size:
            6 + random.nextDouble() * 6,
        spin:
            (random.nextDouble() - 0.5) * 12,
        color: colors[
            random.nextInt(colors.length)],
      ),
    );

    controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2200,
      ),
    )
      ..addStatusListener((status) {
        if (status ==
            AnimationStatus.completed) {
          widget.onDone();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              pieces: pieces,
              progress: controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter({
    required this.pieces,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fade out over the last 30% of the animation.
    final opacity = progress < 0.7
        ? 1.0
        : (1 - (progress - 0.7) / 0.3)
            .clamp(0.0, 1.0);

    final paint = Paint();

    for (final piece in pieces) {
      final t = progress * piece.speed;

      final x = (piece.startX +
              piece.driftX * t +
              sin(t * 8 + piece.startX * 10) *
                  0.02) *
          size.width;

      // Start just above the screen and fall
      // with a little gravity.
      final y = -20 +
          (t + t * t) *
              size.height *
              0.75;

      paint.color = piece.color.withValues(
        alpha: opacity,
      );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * piece.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.55,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(
    _ConfettiPainter oldDelegate,
  ) =>
      oldDelegate.progress != progress;
}
