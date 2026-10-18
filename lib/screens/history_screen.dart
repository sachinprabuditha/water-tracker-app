import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/water_store.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_glass_illustration.dart';
import '../widgets/sporty_girl_illustration.dart';
import '../widgets/ui.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _maxWeeksBack = 52;

  /// 0 = the 7 days ending today, 1 = the 7 before that, ...
  int _weeksBack = 0;

  /// Index (0-6) of the day whose drinks are listed. Defaults to the last.
  int _selected = 6;

  void _changeWeek(int delta) => setState(() {
        _weeksBack = (_weeksBack + delta).clamp(0, _maxWeeksBack);
        _selected = 6;
      });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WaterStore>();
    final now = DateTime.now();
    final days = List.generate(
        7,
        (i) =>
            DateTime(now.year, now.month, now.day - 7 * _weeksBack - (6 - i)));
    final values = days.map(store.mlFor).toList();
    final average = (values.reduce((a, b) => a + b) / 7).round();
    final goalDays = values.where((v) => v >= store.goalMl).length;
    final range = '${DateFormat('MMM d').format(days.first)} - '
        '${DateFormat('MMM d').format(days.last)}';

    return DecoratedBox(
      decoration: BoxDecoration(gradient: Palette.of(context).background),
      child: ListView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
        children: [
          BlueHeader(
            title: 'History',
            subtitle: _weeksBack == 0 ? 'Last 7 days' : range,
            leading: HeaderButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Previous week',
              onPressed:
                  _weeksBack < _maxWeeksBack ? () => _changeWeek(1) : null,
            ),
            trailing: HeaderButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Next week',
              onPressed: _weeksBack > 0 ? () => _changeWeek(-1) : null,
            ),
            child: _ChartCard(
              days: days,
              values: values,
              goalMl: store.goalMl,
              average: average,
              selected: _selected,
              onSelect: (i) => setState(() => _selected = i),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GoalCard(goalMl: store.goalMl, goalDays: goalDays),
                const SizedBox(height: 24),
                _Timeline(day: days[_selected]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.days,
    required this.values,
    required this.goalMl,
    required this.average,
    required this.selected,
    required this.onSelect,
  });

  static const _barHeight = 150.0;

  final List<DateTime> days;
  final List<int> values;
  final int goalMl;
  final int average;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final scale = math.max(goalMl, values.reduce(math.max)) * 1.15;
    final goalY = _barHeight * goalMl / scale;
    final today = WaterStore.keyFor(DateTime.now());

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      child: Column(
        children: [
          SizedBox(
            height: _barHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _Bar(
                          day: days[i],
                          ml: values[i],
                          height: _barHeight * values[i] / scale,
                          selected: i == selected,
                          onTap: () => onSelect(i),
                        ),
                      ),
                  ],
                ),
                // Dashed coral goal line, centred on the goal height.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: goalY - 8,
                  child: const IgnorePointer(child: _GoalLine()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _DayLabel(
                    day: days[i],
                    selected: i == selected,
                    isToday: WaterStore.keyFor(days[i]) == today,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: p.track),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text('Daily Average',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              ValueBadge('$average ml'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalLine extends StatelessWidget {
  const _GoalLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              size: const Size.fromHeight(2),
              painter: _DashPainter(),
            ),
          ),
          const SizedBox(width: 4),
          const Text('Goal',
              style: TextStyle(
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.coral)),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.coral
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < size.width; x += 9) {
      canvas.drawLine(
          Offset(x, 1), Offset(math.min(x + 4, size.width), 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.ml,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final int ml;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${DateFormat('EEEE, d MMMM').format(day)}, $ml ml',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          // Pale full-height track with the day's water rising inside it.
          child: Container(
            width: 24,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: p.track.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              width: 24,
              height: ml == 0 ? 0 : math.max(12, height),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: selected
                      ? const [AppColors.blue, AppColors.blueNight]
                      : const [Color(0xFF64B5F6), AppColors.blue],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-letter weekday under a bar; the selected day gets a blue pill.
class _DayLabel extends StatelessWidget {
  const _DayLabel({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final label = DateFormat('E').format(day);
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.blueDeep : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label.length > 2 ? label.substring(0, 2) : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isToday || selected ? FontWeight.w800 : FontWeight.w700,
                color: selected
                    ? Colors.white
                    : isToday
                        ? p.text
                        : p.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "2400 ml Daily Goal" with the sporty girl illustration.
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goalMl, required this.goalDays});

  final int goalMl;
  final int goalDays;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final blue = Theme.of(context).brightness == Brightness.light
        ? AppColors.blueDeep
        : AppColors.sky;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(8, 12, 18, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SportyGirlIllustration(height: 160),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('$goalMl ml',
                        style: TextStyle(
                            fontFamily: AppTheme.display,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: blue)),
                  ),
                  Text('Daily Goal',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: p.muted)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 18, color: AppColors.coral),
                        const SizedBox(width: 4),
                        Text('Met $goalDays of 7 days',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: p.text)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The selected day's drinks, newest first. Swipe one left to delete it.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WaterStore>();
    final p = Palette.of(context);
    final drinks = store.drinksOn(day);
    final untracked = store.untrackedMlOn(day);
    final isToday = WaterStore.keyFor(day) == WaterStore.keyFor(DateTime.now());
    final time = DateFormat.jm();

    void delete(Drink d) {
      store.removeDrink(d);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Deleted ${d.ml} ml'),
          action: SnackBarAction(
              label: 'Undo', onPressed: () => store.restoreDrink(d)),
        ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          isToday ? 'Today' : DateFormat('EEEE, d MMM').format(day),
          trailing: Text('${store.mlFor(day)} ml',
              style: TextStyle(
                  fontFamily: AppTheme.display,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: p.muted)),
        ),
        if (drinks.isEmpty && untracked == 0)
          SoftCard(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const EmptyGlassIllustration(width: 150),
                const SizedBox(height: 14),
                Text('No drinks logged',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  isToday
                      ? 'Tap "Add Glass" on the home tab and it shows up here.'
                      : 'Nothing was logged on this day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted),
                ),
              ],
            ),
          )
        else ...[
          for (final d in drinks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: ObjectKey(d),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => delete(d),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 22),
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                child: _TimelineTile(
                    ml: d.ml,
                    trailing: time.format(d.at),
                    icon: Icons.water_drop_rounded),
              ),
            ),
          if (untracked > 0)
            _TimelineTile(
                ml: untracked,
                trailing: 'Earlier',
                icon: Icons.history_rounded),
          if (drinks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Swipe a drink left to delete it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: p.muted)),
            ),
        ],
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile(
      {required this.ml, required this.trailing, required this.icon});

  final int ml;
  final String trailing;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 18, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: AppColors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('$ml ml',
                style: TextStyle(
                    fontFamily: AppTheme.display,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: p.text)),
          ),
          Text(trailing,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: p.muted)),
        ],
      ),
    );
  }
}
