import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// "Tip of the day" from `GET /v1/tips/today`.
///
/// Shows a shimmering skeleton while loading and hides itself completely when
/// the API is not configured, offline, or returns nothing usable. Give it a
/// key that changes daily so a new tip is fetched after midnight.
class TipCard extends StatefulWidget {
  const TipCard({super.key});

  @override
  State<TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<TipCard> {
  late final ApiClient _api = context.read<ApiClient>();
  late final Future<String?> _tip = _api.todayTip();

  @override
  Widget build(BuildContext context) {
    if (!_api.configured) return const SizedBox.shrink();
    return FutureBuilder<String?>(
      future: _tip,
      builder: (context, snap) {
        final Widget child;
        if (snap.connectionState != ConnectionState.done) {
          child = const _TipSkeleton(key: ValueKey('loading'));
        } else if (snap.data == null) {
          child = const SizedBox(key: ValueKey('none'), width: double.infinity);
        } else {
          child = _GlassTip(key: const ValueKey('tip'), text: snap.data!);
        }
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: child,
          ),
        );
      },
    );
  }
}

/// Rounded card the tip and its skeleton share.
class _Glass extends StatelessWidget {
  const _Glass({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SoftCard(padding: const EdgeInsets.all(16), child: child);
}

class _GlassTip extends StatelessWidget {
  const _GlassTip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Glass(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_rounded,
                size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tip of the day',
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.brightness == Brightness.light
                            ? AppColors.blueDeep
                            : AppColors.sky)),
                const SizedBox(height: 4),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder shaped like the tip, with a moving shimmer.
class _TipSkeleton extends StatefulWidget {
  const _TipSkeleton({super.key});

  @override
  State<_TipSkeleton> createState() => _TipSkeletonState();
}

class _TipSkeletonState extends State<_TipSkeleton>
    with SingleTickerProviderStateMixin {
  late final _shimmer = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shimmer.stop();
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Pale track -> sky blue; muted in dark mode so the shimmer doesn't glare.
    final base = Palette.of(context).track;
    final glow = AppColors.sky.withValues(alpha: dark ? 0.3 : 0.9);

    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(6)),
          ),
        );

    return Semantics(
      label: 'Loading tip of the day',
      child: _Glass(
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (context, child) => ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) {
              final x = -1.5 + 3 * _shimmer.value;
              return LinearGradient(
                begin: Alignment(x - 1, 0),
                end: Alignment(x + 1, 0),
                colors: [base, glow, base],
              ).createShader(rect);
            },
            child: child,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    bar(0.35, 10),
                    const SizedBox(height: 10),
                    bar(1, 12),
                    const SizedBox(height: 6),
                    bar(0.7, 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
