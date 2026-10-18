import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Flat vector drawing of a sporty girl drinking water beside a big
/// "PURE WATER" bottle. Drawn in code so it scales without image assets.
class SportyGirlIllustration extends StatelessWidget {
  const SportyGirlIllustration({super.key, this.height = 190});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: height * _Painter.width / _Painter.height,
        height: height,
        child: CustomPaint(painter: _Painter()),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  static const width = 170.0;
  static const height = 190.0;

  static const _skin = Color(0xFFE6A47E);
  static const _skinShade = Color(0xFFCC8A64);
  static const _hair = Color(0xFF4A2C1F);
  static const _outfit = Color(0xFF1D2B4F);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / width, size.height / height);
    _ground(canvas);
    _bottle(canvas);
    _girl(canvas);
  }

  void _ground(Canvas canvas) {
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(86, 181), width: 166, height: 16),
        Paint()..color = AppColors.sky.withValues(alpha: 0.55));
    final drop = Paint()..color = AppColors.blue.withValues(alpha: 0.8);
    _drop(canvas, const Offset(4, 172), 4, drop);
    _drop(canvas, const Offset(80, 168), 3, drop);
    _drop(canvas, const Offset(162, 166), 4.5, drop);
    _drop(canvas, const Offset(152, 150), 2.5, drop);
  }

  void _bottle(Canvas canvas) {
    final body = Path()
      ..moveTo(30, 34)
      ..lineTo(30, 40)
      ..quadraticBezierTo(10, 46, 10, 62)
      ..lineTo(10, 164)
      ..quadraticBezierTo(10, 176, 22, 176)
      ..lineTo(58, 176)
      ..quadraticBezierTo(70, 176, 70, 164)
      ..lineTo(70, 62)
      ..quadraticBezierTo(70, 46, 50, 40)
      ..lineTo(50, 34)
      ..close();

    canvas.drawPath(body, Paint()..color = const Color(0xFFDDEFFF));
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      const Rect.fromLTRB(0, 66, 80, 180),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF64B5F6), AppColors.blueDeep],
        ).createShader(const Rect.fromLTRB(0, 66, 80, 180)),
    );
    // Moulded ridges near the bottom.
    final ridge = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (final y in [150.0, 160.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(8, y)
            ..quadraticBezierTo(40, y + 5, 72, y),
          ridge);
    }
    canvas.restore();
    canvas.drawPath(
        body,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    // Cap.
    canvas.drawRRect(RRect.fromLTRBR(26, 6, 54, 26, const Radius.circular(5)),
        Paint()..color = AppColors.blueNight);
    final grip = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    for (final x in [33.0, 40.0, 47.0]) {
      canvas.drawLine(Offset(x, 10), Offset(x, 22), grip);
    }

    // Label.
    canvas.drawRect(const Rect.fromLTRB(11.5, 92, 68.5, 132),
        Paint()..color = Colors.white);
    _text(canvas, 'PURE', 40, 96, 13, AppColors.blueDeep);
    _text(canvas, 'WATER', 40, 111, 15, AppColors.blue);

    // Shine.
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(19, 62), const Offset(19, 84), shine);
    canvas.drawLine(const Offset(19, 140), const Offset(19, 162), shine);
  }

  void _girl(Canvas canvas) {
    Paint limb(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Path line(List<Offset> pts) => Path()..addPolygon(pts, false);

    // Ponytail, behind everything.
    canvas.drawPath(
        Path()
          ..moveTo(126, 38)
          ..quadraticBezierTo(146, 40, 144, 62)
          ..quadraticBezierTo(140, 56, 130, 52)
          ..close(),
        Paint()..color = _hair);

    // Legs in leggings.
    final leg = limb(_outfit, 12);
    canvas.drawPath(
        line(const [Offset(112, 116), Offset(108, 146), Offset(104, 170)]),
        leg);
    canvas.drawPath(
        line(const [Offset(124, 116), Offset(130, 145), Offset(132, 170)]),
        leg);

    // Sneakers: white with coral soles.
    for (final r in [
      RRect.fromLTRBR(92, 167, 112, 178, const Radius.circular(6)),
      RRect.fromLTRBR(126, 167, 146, 178, const Radius.circular(6)),
    ]) {
      canvas.drawRRect(r, Paint()..color = Colors.white);
      canvas.drawRect(
          Rect.fromLTRB(r.left + 1, r.bottom - 3.5, r.right - 1, r.bottom),
          Paint()..color = AppColors.coral);
    }

    // Waistband, midriff, crop top with a coral trim.
    canvas.drawRRect(
        RRect.fromLTRBR(105, 102, 131, 122, const Radius.circular(5)),
        Paint()..color = _outfit);
    canvas.drawRect(
        const Rect.fromLTRB(108, 90, 128, 104), Paint()..color = _skin);
    canvas.drawRRect(
        RRect.fromLTRBAndCorners(103, 68, 133, 92,
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: const Radius.circular(4),
            bottomRight: const Radius.circular(4)),
        Paint()..color = _outfit);
    canvas.drawRect(const Rect.fromLTRB(104, 87, 132, 91),
        Paint()..color = AppColors.coral);

    // Far arm, hand on hip.
    canvas.drawPath(
        line(const [Offset(130, 74), Offset(140, 90), Offset(131, 104)]),
        limb(_skinShade, 7));

    // Neck and head, tipped back to drink.
    canvas.drawRect(
        const Rect.fromLTRB(113, 56, 122, 70), Paint()..color = _skinShade);
    canvas.drawCircle(const Offset(121, 44), 13, Paint()..color = _hair);
    canvas.drawCircle(const Offset(116, 49), 11.5, Paint()..color = _skin);
    canvas.drawCircle(const Offset(124, 50), 3, Paint()..color = _skinShade);
    canvas.drawPath(
        Path()
          ..moveTo(108, 44)
          ..quadraticBezierTo(111, 41, 114, 43),
        limb(AppColors.ink, 1.8));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(113, 53), width: 6, height: 3.5),
        Paint()..color = AppColors.coral.withValues(alpha: 0.45));

    // Small bottle tipped up to her mouth.
    canvas.drawLine(
        const Offset(104, 50), const Offset(87, 33), limb(AppColors.blue, 10));
    canvas.drawLine(const Offset(97, 43), const Offset(93, 39),
        limb(Colors.white, 10)..strokeCap = StrokeCap.butt);
    canvas.drawLine(
        const Offset(105, 51), const Offset(107, 53), limb(Colors.white, 6));

    // Near arm holding it.
    canvas.drawPath(
        line(const [Offset(106, 74), Offset(92, 66), Offset(98, 47)]),
        limb(_skin, 7.5));
    canvas.drawCircle(const Offset(98, 46), 4.5, Paint()..color = _skin);
  }

  static void _text(
      Canvas canvas, String s, double cx, double top, double size, Color c) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontFamily: AppTheme.display,
              fontSize: size,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: c)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, top));
  }

  static void _drop(Canvas canvas, Offset c, double r, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r * 2.1)
        ..quadraticBezierTo(c.dx + r * 1.15, c.dy - r * 0.7, c.dx + r, c.dy)
        ..arcToPoint(Offset(c.dx - r, c.dy), radius: Radius.circular(r))
        ..quadraticBezierTo(
            c.dx - r * 1.15, c.dy - r * 0.7, c.dx, c.dy - r * 2.1)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_Painter old) => false;
}
