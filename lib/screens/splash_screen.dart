import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/water_glass.dart';

/// Blue launch screen: bubbly "H2Go" logo, the winking glass, and waves with
/// rising bubbles. Fades into [next] after a moment. The Android launch
/// background uses the same blue so there is no flash before it appears.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.next});

  final WidgetBuilder next;

  static const duration = Duration(milliseconds: 2200);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  late final _sea =
      AnimationController(vsync: this, duration: const Duration(seconds: 5));
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.duration, _goNext);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      _sea.stop();
    } else {
      if (_intro.value == 0) _intro.forward();
      if (!_sea.isAnimating) _sea.repeat();
    }
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, _, __) => widget.next(context),
      transitionsBuilder: (context, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
              scale: Tween(begin: 1.04, end: 1.0).animate(curved),
              child: child),
        );
      },
    ));
  }

  @override
  void dispose() {
    _timer.cancel();
    _intro.dispose();
    _sea.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final pop = CurvedAnimation(parent: _intro, curve: Curves.elasticOut);
    final fade = CurvedAnimation(
        parent: _intro, curve: const Interval(0, 0.4, curve: Curves.easeOut));
    final rise = CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF42A5F5), AppColors.blue, AppColors.blueDeep],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: size.height * 0.36 + bottom,
                child: CustomPaint(painter: _SeaPainter(_sea)),
              ),
              Align(
                alignment: const Alignment(0, -0.32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: fade,
                      child: ScaleTransition(
                          scale: pop, child: const _BubblyLogo()),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: rise,
                      child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0, 0.25), end: Offset.zero)
                            .animate(rise),
                        child: WaterGlass(
                            progress: 0.62,
                            height: (size.height * 0.22).clamp(140.0, 200.0),
                            decorated: true),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: bottom + size.height * 0.07,
                child: FadeTransition(
                  opacity: rise,
                  child: const Text(
                    'Drink enough water\nevery day!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.display,
                      fontSize: 26,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            color: Color(0x660B2545),
                            offset: Offset(0, 2),
                            blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "H2Go" in rounded white letters with a soft blue outline, like a sticker.
class _BubblyLogo extends StatelessWidget {
  const _BubblyLogo();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        fontFamily: AppTheme.display,
        fontSize: 88,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 1);
    return Semantics(
      header: true,
      label: 'H2Go',
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Text('H2Go',
                style: style.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 12
                    ..strokeJoin = StrokeJoin.round
                    ..color = AppColors.blueNight.withValues(alpha: 0.55),
                )),
            Text('H2Go',
                style: style.copyWith(
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                        color: Color(0x400B2545),
                        offset: Offset(0, 6),
                        blurRadius: 12),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

/// Rolling waves along the bottom with bubbles rising through the water.
class _SeaPainter extends CustomPainter {
  _SeaPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  // (x as a fraction of width, radius, speed, starting phase)
  static const _bubbles = [
    (0.08, 5.0, 1.0, 0.1),
    (0.18, 9.0, 1.0, 0.55),
    (0.27, 4.0, 2.0, 0.3),
    (0.36, 6.5, 1.0, 0.8),
    (0.44, 3.5, 2.0, 0.05),
    (0.52, 8.0, 1.0, 0.35),
    (0.6, 4.5, 2.0, 0.7),
    (0.68, 6.0, 1.0, 0.15),
    (0.76, 3.5, 2.0, 0.5),
    (0.84, 7.5, 1.0, 0.9),
    (0.92, 4.5, 2.0, 0.25),
    (0.48, 5.0, 1.0, 0.62),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final v = t.value;
    const crest = 34.0; // where the front wave's centre line sits

    /// The water under a wave, or just its crest line when [crestOnly].
    Path wave(double base, double amp, double cycles, double phase,
        {bool crestOnly = false}) {
      double y(double x) =>
          base + math.sin(x / w * cycles * 2 * math.pi + phase) * amp;
      final p = Path()..moveTo(0, y(0));
      for (var x = 4.0; x < w; x += 4) {
        p.lineTo(x, y(x));
      }
      p.lineTo(w, y(w));
      if (crestOnly) return p;
      return p
        ..lineTo(w, size.height)
        ..lineTo(0, size.height)
        ..close();
    }

    canvas.drawPath(wave(crest - 16, 10, 1.5, 2 * math.pi * v + 1),
        Paint()..color = Colors.white.withValues(alpha: 0.28));
    canvas.drawPath(wave(crest - 4, 9, 1, -2 * math.pi * v),
        Paint()..color = AppColors.sky.withValues(alpha: 0.75));
    final front = wave(crest + 6, 8, 2, 2 * math.pi * 2 * v);
    canvas.drawPath(
      front,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF64B5F6), AppColors.blueDeep, AppColors.blueNight],
          stops: [0, 0.45, 1],
        ).createShader(Offset.zero & size),
    );

    // White foam line on the front crest.
    canvas.drawPath(
      wave(crest + 6, 8, 2, 2 * math.pi * 2 * v, crestOnly: true),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.save();
    canvas.clipPath(front);
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.16);
    final travel = size.height - crest;
    for (final (fx, r, speed, phase) in _bubbles) {
      final k = (v * speed + phase) % 1;
      final y = size.height + r - k * (travel + 2 * r);
      final x = fx * w + math.sin((k + phase) * 2 * math.pi) * 6;
      canvas.drawCircle(Offset(x, y), r, fill);
      canvas.drawCircle(Offset(x, y), r, ring);
      canvas.drawCircle(Offset(x - r * 0.35, y - r * 0.35), r * 0.22,
          Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SeaPainter old) => false;
}
