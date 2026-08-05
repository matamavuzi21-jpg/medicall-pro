import 'package:flutter/material.dart';

/// Ligne de pouls (ECG) décorative, discrète, en bas de l'écran de
/// connexion — clin d'œil médical, dans l'esprit de la maquette de
/// référence.
class HeartbeatLine extends StatelessWidget {
  final double height;
  final Color color;

  const HeartbeatLine({super.key, this.height = 40, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _HeartbeatPainter(color: color),
      ),
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  final Color color;
  _HeartbeatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final midY = size.height / 2;
    final path = Path();
    path.moveTo(0, midY);
    path.lineTo(size.width * 0.22, midY);
    path.lineTo(size.width * 0.30, midY - size.height * 0.15);
    path.lineTo(size.width * 0.37, midY + size.height * 0.45);
    path.lineTo(size.width * 0.44, midY - size.height * 0.85);
    path.lineTo(size.width * 0.51, midY + size.height * 0.3);
    path.lineTo(size.width * 0.58, midY);
    path.lineTo(size.width * 0.78, midY);
    path.lineTo(size.width * 0.85, midY - size.height * 0.15);
    path.lineTo(size.width * 0.90, midY + size.height * 0.15);
    path.lineTo(size.width, midY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter oldDelegate) =>
      oldDelegate.color != color;
}
