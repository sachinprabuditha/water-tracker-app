import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The H2Go mascot: a winking cartoon glass that fills with animated water.
///
/// The water is two sine waves (a light back wave and a faster blue front
/// wave). Raising [progress] eases the level up and throws a few drops out of
/// the top. When [happy] is set (goal reached) both eyes squint with joy.
/// Animation stops when the system's "remove animations" setting is on.
class WaterGlass extends StatefulWidget {
  const WaterGlass({
    super.key,
    required this.progress,
    this.height = 240,
    this.happy = false,
    this.decorated = false,
  });

  /// 0.0 - 1.0 (values above 1 are clamped).
  final double progress;
  final double height;
  final bool happy;

  /// Adds a few static splash drops around the rim (used on the splash).
  final bool decorated;

  @override
  State<WaterGlass> createState() => _WaterGlassState();
}

class _WaterGlassState extends State<WaterGlass> with TickerProviderStateMixin {
  // One loop = 2 back-wave cycles and 3 front-wave cycles, so it repeats
  // seamlessly while the front wave moves 1.5x faster.
  late final _waves =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));

  /// Drops flying out after a drink is added. Rests at 1.0 (no drops).
  late final _splash = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100), value: 1);

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _waves.stop();
      _splash.value = 1;
    } else if (!_waves.isAnimating) {
      _waves.repeat();
    }
  }

  @override
  void didUpdateWidget(WaterGlass old) {
    super.didUpdateWidget(old);
    if (widget.progress > old.progress && !_reduceMotion) {
      _splash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _waves.dispose();
    _splash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: Duration(milliseconds: _reduceMotion ? 0 : 900),
      curve: Curves.easeOutCubic,
      builder: (context, level, _) => SizedBox(
        width: widget.height * _GlassPainter.width / _GlassPainter.height,
        height: widget.height,
        child: CustomPaint(
          painter: _GlassPainter(
            level: level,
            waves: _waves,
            splash: _splash,
            happy: widget.happy,
            decorated: widget.decorated,
          ),
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.level,
    required this.waves,
    required this.splash,
    required this.happy,
    required this.decorated,
  }) : super(repaint: Listenable.merge([waves, splash]));

  // Drawn on a 200 x 280 grid; the glass itself starts [_top] down so drops
  // have room to fly above it.
  static const width = 200.0;
  static const height = 280.0;
  static const _top = 40.0;
  static const _bottom = 230.0;

  final double level;
  final Animation<double> waves;
  final Animation<double> splash;
  final bool happy;
  final bool decorated;

  /// Tapered tumbler with rounded bottom corners, shrunk by [d] all round.
  static Path _body(double d) => Path()
    ..moveTo(12 + d, 20)
    ..lineTo(32 + d, 206 - d * 0.3)
    ..quadraticBezierTo(34.5 + d * 0.8, _bottom - d, 58 + d * 0.3, _bottom - d)
    ..lineTo(142 - d * 0.3, _bottom - d)
    ..quadraticBezierTo(165.5 - d * 0.8, _bottom - d, 168 - d, 206 - d * 0.3)
    ..lineTo(188 - d, 20)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / width, size.height / height);

    // Soft floor shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 272), width: 150, height: 14),
      Paint()
        ..color = AppColors.blueDeep.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    if (decorated) _sideSplashes(canvas);

    canvas.save();
    canvas.translate(0, _top);
    final outer = _body(0);
    final inner = _body(8);

    canvas.drawShadow(
        outer, AppColors.blueDeep.withValues(alpha: 0.6), 10, true);
    canvas.drawPath(outer, Paint()..color = const Color(0xFFEAF5FF));

    canvas.save();
    canvas.clipPath(inner);
    _water(canvas);
    canvas.restore();

    // Glass edge: white with a thin blue outline so it reads on white too.
    canvas.drawPath(
        outer,
        Paint()
          ..color = const Color(0xFFB9DDFB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9);
    canvas.drawPath(
        outer,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);

    // Rim seen from slightly above.
    final rim =
        Rect.fromCenter(center: const Offset(100, 20), width: 176, height: 22);
    canvas.drawOval(rim, Paint()..color = Colors.white.withValues(alpha: 0.55));
    canvas.drawOval(
        rim,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);

    // Shine.
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(34, 52), const Offset(46, 168), shine);
    canvas.drawLine(const Offset(48.5, 186), const Offset(49.5, 194), shine);

    _face(canvas);
    canvas.restore();

    _flyingDrops(canvas);
  }

  void _water(Canvas canvas) {
    if (level <= 0) return;
    const full = 34.0; // water surface at 100%: just under the rim
    final calm = 5.0;
    final amp = calm *
        (1 + 1.6 * math.sin(math.pi * splash.value) * (1 - splash.value));
    final base = _bottom + calm - (_bottom + calm - full) * level;
    final t = waves.value;

    Path wave(double phase, double speed) {
      double y(double x) =>
          base +
          math.sin(x / width * 2 * math.pi + 2 * math.pi * speed * t + phase) *
              amp;
      final p = Path()..moveTo(0, y(0));
      for (var x = 4.0; x <= width; x += 4) {
        p.lineTo(x, y(x));
      }
      return p
        ..lineTo(width, _bottom)
        ..lineTo(0, _bottom)
        ..close();
    }

    canvas.drawPath(wave(math.pi / 2, 2), Paint()..color = AppColors.sky);
    final front = wave(0, 3);
    canvas.drawPath(
      front,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF42A5F5), AppColors.blueDeep],
        ).createShader(Rect.fromLTRB(0, base - amp, width, _bottom)),
    );

    // A few bubbles, only where there is water.
    canvas.save();
    canvas.clipPath(front);
    final bubble = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (final (x, y, r) in const [
      (150.0, 196.0, 6.0),
      (138.0, 172.0, 3.5),
      (62.0, 204.0, 4.0),
      (150.0, 120.0, 3.0)
    ]) {
      canvas.drawCircle(Offset(x, y), r, bubble);
    }
    canvas.restore();
  }

  void _face(Canvas canvas) {
    final ink = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Left eye: always a happy closed arc (the wink).
    canvas.drawPath(
        Path()
          ..moveTo(62, 128)
          ..quadraticBezierTo(74, 114, 86, 128),
        ink);

    if (happy) {
      canvas.drawPath(
          Path()
            ..moveTo(114, 128)
            ..quadraticBezierTo(126, 114, 138, 128),
          ink);
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(126, 123), width: 17, height: 21),
          Paint()..color = AppColors.ink);
      canvas.drawCircle(
          const Offset(129.5, 118), 3.6, Paint()..color = Colors.white);
    }

    // Smile.
    canvas.drawPath(
        Path()
          ..moveTo(82, 146)
          ..quadraticBezierTo(101, 168, 120, 146),
        ink);

    // Coral cheeks.
    final cheek = Paint()..color = AppColors.coral.withValues(alpha: 0.5);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(58, 146), width: 18, height: 10),
        cheek);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(142, 146), width: 18, height: 10),
        cheek);
  }

  /// Three drops thrown up out of the glass after a drink is added.
  void _flyingDrops(Canvas canvas) {
    final t = splash.value;
    if (t >= 1) return;
    final fade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
    final paint = Paint()..color = AppColors.blue.withValues(alpha: fade);
    for (final (dx, peak, r) in const [
      (-62.0, 44.0, 7.0),
      (4.0, 58.0, 9.0),
      (66.0, 40.0, 6.0)
    ]) {
      final x = 100 + dx * t;
      final y = (_top + 26) - peak * 4 * t * (1 - t) - 12 * t;
      _drop(canvas, Offset(x, y), r, paint);
    }
  }

  /// Still drops jumping off the rim, for the splash screen.
  void _sideSplashes(Canvas canvas) {
    final white = Paint()..color = Colors.white;
    final light = Paint()..color = Colors.white.withValues(alpha: 0.7);
    _drop(canvas, const Offset(22, 40), 8, white);
    _drop(canvas, const Offset(6, 64), 5, light);
    _drop(canvas, const Offset(178, 34), 9, white);
    _drop(canvas, const Offset(196, 58), 5, light);
    _drop(canvas, const Offset(100, 12), 6, light);
  }

  /// A teardrop with its round end centred on [c].
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
  bool shouldRepaint(_GlassPainter old) =>
      old.level != level || old.happy != happy || old.decorated != decorated;
}
