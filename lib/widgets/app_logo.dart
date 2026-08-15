import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Le logo officiel de MediCall Pro.
///
/// Un anneau fin, une croix médicale simple au centre, et deux arcs
/// verts représentant l'onde sonore de l'annonce vocale — toujours en
/// vert, quel que soit le fond, pour rester un repère de marque unique
/// et reconnaissable.
class AppLogo extends StatelessWidget {
  final double size;
  final Color color;
  final bool showSoundWaves;

  const AppLogo({
    super.key,
    this.size = 64,
    this.color = Colors.white,
    this.showSoundWaves = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AppLogoPainter(color: color, showSoundWaves: showSoundWaves),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  static const _wagenia = Color(0xFF2FC090);

  final Color color;
  final bool showSoundWaves;

  _AppLogoPainter({required this.color, required this.showSoundWaves});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 260;
    final center = Offset(size.width / 2, size.height / 2);

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * s;
    canvas.drawCircle(center, 92 * s, ringPaint);

    final crossPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final vBar = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 32 * s, height: 96 * s),
      Radius.circular(9 * s),
    );
    final hBar = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 96 * s, height: 32 * s),
      Radius.circular(9 * s),
    );
    canvas.drawRRect(vBar, crossPaint);
    canvas.drawRRect(hBar, crossPaint);

    if (showSoundWaves) {
      final wave1 = Paint()
        ..color = _wagenia
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * s
        ..strokeCap = StrokeCap.round;
      final wave2 = Paint()
        ..color = _wagenia.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * s
        ..strokeCap = StrokeCap.round;

      final rect1 = Rect.fromCircle(center: center, radius: 124 * s);
      final rect2 = Rect.fromCircle(center: center, radius: 148 * s);
      const startAngle = -70 * math.pi / 180;
      const sweepAngle = 50 * math.pi / 180;
      canvas.drawArc(rect1, startAngle, sweepAngle, false, wave1);
      canvas.drawArc(rect2, startAngle, sweepAngle, false, wave2);
    }
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.showSoundWaves != showSoundWaves;
  }
}
