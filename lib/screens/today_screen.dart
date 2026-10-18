import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/cups.dart';
import '../data/water_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cup_icon.dart';
import '../widgets/tip_card.dart';
import '../widgets/ui.dart';
import '../widgets/water_glass.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  Future<void> _add(BuildContext context, WaterStore store) async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final cup = store.cup;
    final drink = await store.addDrink();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('+${drink.ml} ml  ·  ${cup.name}'),
        action: SnackBarAction(
            label: 'Undo', onPressed: () => store.removeDrink(drink)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WaterStore>();
    final p = Palette.of(context);
    final ml = store.todayMl;
    final progress = ml / store.goalMl;
    final done = ml >= store.goalMl;
    final glassHeight =
        (MediaQuery.sizeOf(context).height * 0.3).clamp(170.0, 270.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.blueNight,
            AppColors.blueDeep,
            AppColors.blue,
            p.backgroundTop,
            p.backgroundBottom,
          ],
          stops: const [0, 0.2, 0.4, 0.68, 1],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              const _MyWaterBadge(),
              const SizedBox(height: 10),
              _Percent(value: (progress * 100).round()),
              Text('$ml of ${store.goalMl} ml',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: done
                    ? const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: _GoalReachedBadge(),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 10),
              Semantics(
                label: 'Water glass, ${(progress * 100).round()} percent full',
                child: WaterGlass(
                    progress: progress, height: glassHeight, happy: done),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final cup in Cup.all)
                    _PresetButton(
                      cup: cup,
                      selected: store.cupMl == cup.ml,
                      onTap: () => store.setCupMl(cup.ml),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _AddButton(ml: store.cupMl, onTap: () => _add(context, store)),
              const SizedBox(height: 20),
              // Below the button so "Add Glass" never moves when the tip
              // loads or hides. Keyed by date to fetch a new tip each day.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child:
                    TipCard(key: ValueKey(WaterStore.keyFor(DateTime.now()))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "My Water" pill with a drop, on the blue header.
class _MyWaterBadge extends StatelessWidget {
  const _MyWaterBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 18, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(40),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.water_drop_rounded,
                size: 18, color: AppColors.blue),
          ),
          const SizedBox(width: 8),
          const Text('My Water',
              style: TextStyle(
                  fontFamily: AppTheme.display,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

/// Big percentage that counts up (or down) to its new value.
class _Percent extends StatelessWidget {
  const _Percent({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: Duration(milliseconds: still ? 0 : 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${v.round()}%',
        style: TextStyle(
          fontFamily: AppTheme.display,
          fontSize: 64,
          height: 1.1,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          shadows: [
            Shadow(
                color: AppColors.ink.withValues(alpha: 0.25),
                offset: const Offset(0, 4),
                blurRadius: 10),
          ],
        ),
      ),
    );
  }
}

class _GoalReachedBadge extends StatelessWidget {
  const _GoalReachedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 14, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, size: 18, color: AppColors.coral),
          SizedBox(width: 6),
          Text('Goal reached!',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton(
      {required this.cup, required this.selected, required this.onTap});

  final Cup cup;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Bouncy(
      onTap: onTap,
      selected: selected,
      label: '${cup.name}, ${cup.ml} ml',
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: p.card,
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? AppColors.blue : Colors.transparent,
                  width: 3),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? AppColors.blue.withValues(alpha: 0.45)
                      : p.shadow,
                  blurRadius: selected ? 16 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(child: CupIcon(cup.shape, size: 34)),
          ),
          const SizedBox(height: 6),
          Text('${cup.ml} ml',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: p.text)),
        ],
      ),
    );
  }
}

/// The round "+" button with its "Add Glass" label.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.ml, required this.onTap});

  final int ml;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Bouncy(
      onTap: onTap,
      label: 'Add glass, $ml ml',
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: const Icon(Icons.add_rounded, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text('Add Glass',
              style: TextStyle(
                  fontFamily: AppTheme.display,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: p.text)),
        ],
      ),
    );
  }
}
