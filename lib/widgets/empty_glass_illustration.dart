import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Outline drawing of an empty glass tipped on its side, with a last few
/// drops spilling out. Drawn in code so it scales and follows the theme.
class EmptyGlassIllustration extends StatelessWidget {
  const EmptyGlassIllustration({super.key, this.width = 200});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.6,
      child: CustomPaint(
        painter: _TippedGlassPainter(
            line: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _TippedGlassPainter extends CustomPainter {
  _TippedGlassPainter({required this.line});

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    // Designed on a 200 x 120 grid.
    canvas.scale(size.width / 200, size.height / 120);

    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Floor.
    canvas.drawLine(const Offset(14, 100), const Offset(186, 100),
        stroke..color = line.withValues(alpha: 0.35));
    stroke.color = line;

    // Glass lying on its side, rocked slightly back: narrow base on the left,
    // open mouth on the right.
    canvas.save();
    canvas.translate(88, 74);
    canvas.rotate(-0.12);
    final glass = Path()
      ..moveTo(52, -30) // mouth top
      ..lineTo(-46, -20) // base top
      ..quadraticBezierTo(-52, -19, -52, -13)
      ..lineTo(-52, 13)
      ..quadraticBezierTo(-52, 19, -46, 20) // base bottom
      ..lineTo(52, 30); // mouth bottom
    canvas.drawPath(glass, stroke);
    // Thick base of the glass.
    canvas.drawLine(const Offset(-40, -18), const Offset(-40, 18), stroke);
    // Open rim.
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(52, 0), width: 14, height: 60),
        stroke);
    // A highlight along the glass.
    canvas.drawLine(const Offset(-26, -10), const Offset(24, -17),
        stroke..color = line.withValues(alpha: 0.35));
    canvas.restore();

    // Puddle.
    final water = Paint()..color = AppColors.sky.withValues(alpha: 0.7);
    final puddle = Path()
      ..moveTo(128, 100)
      ..cubicTo(132, 92, 150, 94, 158, 96)
      ..cubicTo(168, 92, 182, 95, 180, 100)
      ..close();
    canvas.drawPath(puddle, water);

    // Last drops.
    final drop = Paint()..color = AppColors.blue;
    _drop(canvas, const Offset(160, 70), 5, drop);
    _drop(canvas, const Offset(174, 82), 3.5, drop);
  }

  void _drop(Canvas canvas, Offset bottom, double r, Paint paint) {
    final c = bottom.translate(0, -r);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r * 2.2)
        ..quadraticBezierTo(c.dx + r * 1.1, c.dy - r * 0.6, c.dx + r, c.dy)
        ..arcToPoint(Offset(c.dx - r, c.dy),
            radius: Radius.circular(r), clockwise: true)
        ..quadraticBezierTo(
            c.dx - r * 1.1, c.dy - r * 0.6, c.dx, c.dy - r * 2.2)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TippedGlassPainter old) => old.line != line;
}
