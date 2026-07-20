import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Le logo officiel de MediCall Pro.
///
/// Concept : la croix médicale est formée de 4 pavillons de porte-voix
/// diffusant le son dans toutes les directions — l'annonce vocale et le
/// soin ne sont plus deux idées séparées, mais une seule forme. Deux arcs
/// représentent les ondes sonores qui s'en échappent.
///
/// Dessiné entièrement en code (CustomPainter) : net à n'importe quelle
/// taille (icône d'app comme grand format), aucun fichier image à gérer
/// ni à régénérer si la couleur doit changer.
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
  final Color color;
  final bool showSoundWaves;

  _AppLogoPainter({required this.color, required this.showSoundWaves});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 260;
    final center = Offset(size.width / 2, size.height / 2);
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path hornPath() {
      final p = Path();
      p.moveTo(116 * s, 100 * s);
      p.lineTo(102 * s, 30 * s);
      p.lineTo(158 * s, 30 * s);
      p.lineTo(144 * s, 100 * s);
      p.close();
      return p;
    }

    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 2);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(hornPath(), fillPaint);
      canvas.restore();
    }

    canvas.drawCircle(center, 21 * s, fillPaint);

    if (showSoundWaves) {
      final wavePaint1 = Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * s
        ..strokeCap = StrokeCap.round;
      final wavePaint2 = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * s
        ..strokeCap = StrokeCap.round;

      final rect1 = Rect.fromCircle(center: center, radius: 124 * s);
      final rect2 = Rect.fromCircle(center: center, radius: 148 * s);
      const startAngle = -70 * math.pi / 180;
      const sweepAngle = 50 * math.pi / 180;
      canvas.drawArc(rect1, startAngle, sweepAngle, false, wavePaint1);
      canvas.drawArc(rect2, startAngle, sweepAngle, false, wavePaint2);
    }
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.showSoundWaves != showSoundWaves;
  }
}
