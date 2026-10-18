import 'package:flutter/material.dart';

import '../data/cups.dart';
import '../theme/app_theme.dart';

/// A small drawing of a cup with water in it. Sizes differ by [CupShape] so
/// the presets are told apart at a glance.
class CupIcon extends StatelessWidget {
  const CupIcon(this.shape, {super.key, this.size = 32});

  final CupShape shape;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _CupPainter(shape)),
      );
}

class _CupPainter extends CustomPainter {
  _CupPainter(this.shape);

  final CupShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    // Designed on a 48 x 48 grid.
    canvas.scale(size.width / 48, size.height / 48);
    final outline = Paint()
      ..color = AppColors.blueDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round;
    final glass = Paint()..color = const Color(0xFFEAF5FF);
    final water = Paint()..color = AppColors.blue;

    final Path body;
    final double top, bottom;
    switch (shape) {
      case CupShape.smallGlass:
        (top, bottom) = (18, 42);
        body = _tumbler(top, bottom, 13, 35, 4);
      case CupShape.mediumGlass:
        (top, bottom) = (11, 42);
        body = _tumbler(top, bottom, 11, 37, 4);
      case CupShape.largeGlass:
        (top, bottom) = (4, 44);
        body = _tumbler(top, bottom, 9, 39, 5);
      case CupShape.bottle:
        (top, bottom) = (16, 46);
        body = Path()
          ..moveTo(20, 9)
          ..lineTo(28, 9)
          ..quadraticBezierTo(28, 14, 34, 16)
          ..quadraticBezierTo(37, 17, 37, 21)
          ..lineTo(37, 42)
          ..quadraticBezierTo(37, 46, 33, 46)
          ..lineTo(15, 46)
          ..quadraticBezierTo(11, 46, 11, 42)
          ..lineTo(11, 21)
          ..quadraticBezierTo(11, 17, 14, 16)
          ..quadraticBezierTo(20, 14, 20, 9)
          ..close();
    }

    canvas.drawPath(body, glass);
    canvas.save();
    canvas.clipPath(body);
    final waterTop = bottom - (bottom - top) * 0.62;
    canvas.drawRect(Rect.fromLTRB(0, waterTop, 48, 48), water);
    canvas.drawRect(Rect.fromLTRB(0, waterTop, 48, waterTop + 2.5),
        Paint()..color = AppColors.sky);
    canvas.restore();
    canvas.drawPath(body, outline);

    if (shape == CupShape.bottle) {
      canvas.drawRRect(
          RRect.fromLTRBR(18.5, 3, 29.5, 9.5, const Radius.circular(2)),
          Paint()..color = AppColors.blueDeep);
      canvas.drawRect(Rect.fromLTRB(11.5, 25, 36.5, 31),
          Paint()..color = Colors.white.withValues(alpha: 0.85));
    } else {
      canvas.drawLine(
          Offset(16, top + 4),
          Offset(17.5, bottom - 8),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.8)
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round);
    }
  }

  /// A glass that narrows towards the bottom.
  static Path _tumbler(
      double top, double bottom, double left, double right, double taper) {
    return Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(right - taper, bottom - 3)
      ..quadraticBezierTo(
          right - taper - 0.5, bottom, right - taper - 3.5, bottom)
      ..lineTo(left + taper + 3.5, bottom)
      ..quadraticBezierTo(left + taper + 0.5, bottom, left + taper, bottom - 3)
      ..close();
  }

  @override
  bool shouldRepaint(_CupPainter old) => old.shape != shape;
}
