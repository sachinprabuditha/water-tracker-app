import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand colours. Fixed in both themes; per-theme surfaces live in [Palette].
abstract final class AppColors {
  static const blue = Color(0xFF2196F3); // primary: water, bars, buttons
  static const blueDeep = Color(0xFF1976D2); // gradient end, text-safe blue
  static const blueNight = Color(0xFF1565C0); // darkest step of headers
  static const sky = Color(0xFF90CAF9); // accent: back wave, tracks
  static const mist = Color(0xFFE3F2FD); // light background, chips
  static const coral = Color(0xFFFF7043); // small highlights only
  static const ink = Color(0xFF0B2545); // text and the glass's face

  /// Buttons, badges and the active nav item.
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, blueDeep],
  );

  /// Blue headers. Dark enough at the top that white body text passes 4.5:1.
  static const headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blueNight, blueDeep, blue],
  );
}

/// Surfaces that change between light and dark mode.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.card,
    required this.shadow,
    required this.text,
    required this.muted,
    required this.track,
  });

  final Color backgroundTop;
  final Color backgroundBottom;
  final Color card;
  final Color shadow;
  final Color text;
  final Color muted;
  final Color track;

  static const light = Palette(
    backgroundTop: AppColors.mist,
    backgroundBottom: Colors.white,
    card: Colors.white,
    shadow: Color(0x2E1976D2),
    text: AppColors.ink,
    muted: Color(0xFF52708F),
    track: Color(0xFFDCEBFA),
  );

  static const dark = Palette(
    backgroundTop: Color(0xFF0F2A4D),
    backgroundBottom: Color(0xFF081627),
    card: Color(0xFF14325A),
    shadow: Color(0x66000000),
    text: Color(0xFFEAF4FF),
    muted: Color(0xFF9DB6D3),
    track: Color(0xFF24456F),
  );

  /// The theme's palette, or the default one for its brightness when the
  /// widget is shown outside [AppTheme] (e.g. in a test's bare MaterialApp).
  static Palette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<Palette>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  /// Soft light-blue to white page background.
  LinearGradient get background => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [backgroundTop, backgroundBottom],
      );

  /// The layered drop shadow every card uses.
  List<BoxShadow> get cardShadow => [
        BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 10)),
      ];

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      backgroundTop: l(backgroundTop, other.backgroundTop),
      backgroundBottom: l(backgroundBottom, other.backgroundBottom),
      card: l(card, other.card),
      shadow: l(shadow, other.shadow),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      track: l(track, other.track),
    );
  }
}

abstract final class AppTheme {
  static const display = 'Fredoka';
  static const _body = 'Nunito';

  static ThemeData light() => _build(Brightness.light, Palette.light);
  static ThemeData dark() => _build(Brightness.dark, Palette.dark);

  static ThemeData _build(Brightness brightness, Palette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.blue,
      onPrimary: Colors.white,
      secondary: AppColors.sky,
      onSecondary: AppColors.ink,
      tertiary: AppColors.coral,
      onTertiary: AppColors.ink,
      surface: p.card,
      onSurface: p.text,
      onSurfaceVariant: p.muted,
      surfaceContainerHighest: p.track,
      outline: p.track,
      outlineVariant: p.track,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: _body,
    );

    // Fredoka for headings and big numbers, Nunito for everything else.
    TextStyle? round(TextStyle? s, FontWeight w) =>
        s?.copyWith(fontFamily: display, fontWeight: w);
    final t = base.textTheme;
    final text = t
        .copyWith(
          displayLarge: round(t.displayLarge, FontWeight.w700),
          displayMedium: round(t.displayMedium, FontWeight.w700),
          displaySmall: round(t.displaySmall, FontWeight.w600),
          headlineLarge: round(t.headlineLarge, FontWeight.w600),
          headlineMedium: round(t.headlineMedium, FontWeight.w600),
          headlineSmall: round(t.headlineSmall, FontWeight.w600),
          titleLarge: round(t.titleLarge, FontWeight.w600),
          titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          bodyLarge: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          bodyMedium: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          bodySmall: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          labelSmall: t.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        )
        .apply(bodyColor: p.text, displayColor: p.text);

    return base.copyWith(
      scaffoldBackgroundColor: p.backgroundBottom,
      textTheme: text,
      extensions: [p],
      iconTheme: IconThemeData(color: p.text),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blueDeep,
          foregroundColor: Colors.white,
          disabledBackgroundColor: p.track,
          disabledForegroundColor: p.muted,
          textStyle: const TextStyle(
              fontFamily: display, fontWeight: FontWeight.w600, fontSize: 18),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brightness == Brightness.light
              ? AppColors.blueDeep
              : AppColors.sky,
          textStyle:
              const TextStyle(fontFamily: _body, fontWeight: FontWeight.w800),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : p.muted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.blue : p.track),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 10,
        activeTrackColor: AppColors.blue,
        inactiveTrackColor: p.track,
        thumbColor: Colors.white,
        overlayColor: AppColors.blue.withValues(alpha: 0.14),
        thumbShape: const _RingThumb(),
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.never,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: p.card,
        selectedColor: AppColors.blue.withValues(alpha: 0.16),
        side: BorderSide(color: p.track, width: 1.5),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
            fontFamily: _body, fontWeight: FontWeight.w700, color: p.text),
        checkmarkColor: AppColors.blue,
      ),
      dividerTheme: DividerThemeData(color: p.track),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.track,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? AppColors.mist.withValues(alpha: 0.6)
            : p.backgroundBottom,
        hintStyle: TextStyle(fontFamily: _body, color: p.muted),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.blue,
        selectionHandleColor: AppColors.blue,
        selectionColor: AppColors.blue.withValues(alpha: 0.3),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        actionTextColor: AppColors.coral,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentTextStyle: const TextStyle(
            fontFamily: _body,
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  /// Shows the bundled fonts' licences on the system licences page.
  static void registerFontLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final family in ['Fredoka', 'Nunito']) {
        final text =
            await rootBundle.loadString('assets/fonts/$family-OFL.txt');
        yield LicenseEntryWithLineBreaks([family], text);
      }
    });
  }
}

/// White slider thumb with a thick blue ring, like a bubble.
class _RingThumb extends SliderComponentShape {
  const _RingThumb();

  static const _radius = 14.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(
        center.translate(0, 2),
        _radius,
        Paint()
          ..color = AppColors.blueDeep.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(center, _radius, Paint()..color = Colors.white);
    canvas.drawCircle(
        center,
        _radius - 3,
        Paint()
          ..color = AppColors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
  }
}
