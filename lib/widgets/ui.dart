import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shrinks a little while pressed and springs back, for a playful feel.
class Bouncy extends StatefulWidget {
  const Bouncy({
    super.key,
    required this.child,
    required this.onTap,
    this.label,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  final bool? selected;

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      selected: widget.selected,
      label: widget.label,
      excludeSemantics: widget.label != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: Duration(milliseconds: _down ? 90 : 260),
          curve: _down ? Curves.easeOut : Curves.elasticOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// White rounded card with the soft layered drop shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final radius = BorderRadius.circular(24);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: p.cardShadow),
      child: Material(
        color: p.card,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// Rounded blue gradient pill with white text, e.g. "2400 ml".
class ValueBadge extends StatelessWidget {
  const ValueBadge(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
          ],
          // Bold 18 px counts as large text, so white on this blue passes.
          Text(text,
              style: const TextStyle(
                  fontFamily: AppTheme.display,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

/// Wide pill button filled with the primary gradient.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final enabled = onPressed != null;
    return Bouncy(
      onTap: onPressed,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : p.track,
          borderRadius: BorderRadius.circular(40),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8)),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: enabled ? Colors.white : p.muted),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: TextStyle(
                    fontFamily: AppTheme.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: enabled ? Colors.white : p.muted)),
          ],
        ),
      ),
    );
  }
}

/// Blue gradient band at the top of a screen, with rounded bottom corners
/// and a title row. [child] (usually a card) starts under the title and
/// overlaps the bottom of the band. Draws under the status bar.
class BlueHeader extends StatelessWidget {
  const BlueHeader({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    this.bandHeight = 150,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;

  /// Height of the band below the status bar.
  final double bandHeight;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top + bandHeight,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 8, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(width: 48, child: leading),
                  Expanded(
                    child: Column(
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title,
                              style: const TextStyle(
                                  fontFamily: AppTheme.display,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.92))),
                      ],
                    ),
                  ),
                  SizedBox(width: 48, child: trailing),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

/// Round translucent white icon button for use on the blue header.
class HeaderButton extends StatelessWidget {
  const HeaderButton(
      {super.key, required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.35),
      ),
      icon: Icon(icon),
    );
  }
}

/// Small bold section title.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 20)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
