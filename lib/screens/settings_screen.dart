import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/cups.dart';
import '../data/water_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cup_icon.dart';
import '../widgets/feedback_sheet.dart';
import '../widgets/ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Cup tapped in the grid but not saved with SELECT yet.
  int? _pendingCupMl;

  Future<void> _addTime(WaterStore store) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) await store.addReminder(picked);
  }

  Future<void> _selectCup(WaterStore store, Cup cup) async {
    await store.setCupMl(cup.ml);
    setState(() => _pendingCupMl = null);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text('${cup.name} (${cup.ml} ml) selected')));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WaterStore>();
    final p = Palette.of(context);
    final shownCup = Cup.forMl(_pendingCupMl ?? store.cupMl);
    final changed = shownCup.ml != store.cupMl;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: p.background),
      child: ListView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
        children: [
          BlueHeader(
            title: 'Settings',
            bandHeight: 130,
            child: _GoalCard(store: store),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RemindersCard(store: store, onAdd: () => _addTime(store)),
                const SizedBox(height: 28),
                const SectionTitle('Customization of Cup'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  // Otherwise it pads itself by the nav bar's inset.
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: [
                    for (final cup in Cup.all)
                      _CupTile(
                        cup: cup,
                        selected: cup.ml == shownCup.ml,
                        onTap: () => setState(() => _pendingCupMl = cup.ml),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: GradientButton(
                    label: changed ? 'SELECT' : 'SELECTED',
                    icon: changed ? null : Icons.check_rounded,
                    onPressed:
                        changed ? () => _selectCup(store, shownCup) : null,
                  ),
                ),
                const SizedBox(height: 28),
                const SectionTitle('More'),
                _CloudCard(store: store),
                if (context.read<ApiClient>().configured) ...[
                  const SizedBox(height: 12),
                  SoftCard(
                    padding: EdgeInsets.zero,
                    child: _RowTile(
                      icon: Icons.rate_review_rounded,
                      title: 'Send feedback',
                      subtitle: 'Ideas or problems? Tell us.',
                      trailing:
                          Icon(Icons.chevron_right_rounded, color: p.muted),
                      onTap: () => showFeedbackSheet(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.store});

  final WaterStore store;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final small =
        TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.muted);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Daily goal',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              ValueBadge('${store.goalMl} ml'),
            ],
          ),
          const SizedBox(height: 6),
          Slider(
            value: store.goalMl.toDouble(),
            min: WaterStore.minGoalMl.toDouble(),
            max: WaterStore.maxGoalMl.toDouble(),
            divisions: (WaterStore.maxGoalMl - WaterStore.minGoalMl) ~/ 100,
            semanticFormatterCallback: (v) => '${v.round()} ml',
            onChanged: (v) => store.setGoalMl(v.round(), push: false),
            onChangeEnd: (_) => store.pushSettings(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${WaterStore.minGoalMl} ml', style: small),
                Text('${WaterStore.maxGoalMl} ml', style: small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindersCard extends StatelessWidget {
  const _RemindersCard({required this.store, required this.onAdd});

  final WaterStore store;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final full = store.reminderTimes.length >= 12;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Column(
        children: [
          _RowTile(
            icon: Icons.alarm_rounded,
            title: 'Reminder times',
            subtitle: 'Daily notifications to drink water',
            trailing: Switch(
                value: store.remindersOn, onChanged: store.setRemindersOn),
            onTap: () => store.setRemindersOn(!store.remindersOn),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !store.remindersOn
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                    child: Column(
                      children: [
                        for (var i = 0; i < store.reminderTimes.length; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 20, color: AppColors.blue),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                      store.reminderTimes[i].format(context),
                                      style: TextStyle(
                                          fontFamily: AppTheme.display,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: p.text)),
                                ),
                                _RoundIconButton(
                                  icon: Icons.remove_rounded,
                                  tooltip:
                                      'Remove ${store.reminderTimes[i].format(context)}',
                                  onPressed: () => store.removeReminder(i),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            _RoundIconButton(
                              icon: Icons.add_rounded,
                              tooltip: 'Add reminder time',
                              filled: true,
                              onPressed: full ? null : onAdd,
                            ),
                            const SizedBox(width: 10),
                            Text(full ? 'Up to 12 reminders' : 'Add time',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: p.muted)),
                          ],
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: filled ? AppColors.blue : Palette.of(context).card,
        foregroundColor: filled ? Colors.white : AppColors.blue,
        side: filled ? null : const BorderSide(color: AppColors.blue, width: 2),
      ),
      icon: Icon(icon),
    );
  }
}

class _CupTile extends StatelessWidget {
  const _CupTile(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue.withValues(alpha: 0.1) : p.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: selected ? AppColors.blue : Colors.transparent, width: 3),
          boxShadow: p.cardShadow,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupIcon(cup.shape, size: 64),
                  const SizedBox(height: 8),
                  Text(cup.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: p.text)),
                  Text('${cup.ml} ml',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.muted)),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle_rounded,
                    size: 22, color: AppColors.blue),
              ),
          ],
        ),
      ),
    );
  }
}

class _CloudCard extends StatelessWidget {
  const _CloudCard({required this.store});

  final WaterStore store;

  @override
  Widget build(BuildContext context) {
    if (!store.cloudAvailable) {
      return const SoftCard(
        padding: EdgeInsets.zero,
        child: _RowTile(
          icon: Icons.cloud_off_rounded,
          title: 'Cloud backup',
          subtitle: 'Unavailable - Firebase is not set up.',
          muted: true,
        ),
      );
    }
    return SoftCard(
      padding: EdgeInsets.zero,
      child: _RowTile(
        icon: Icons.cloud_sync_rounded,
        title: 'Cloud backup',
        subtitle: 'Saves your water log anonymously to Firebase. '
            'Turning this off deletes the cloud copy.',
        muted: !store.cloudOn,
        trailing: Switch(value: store.cloudOn, onChanged: store.setCloudOn),
        onTap: () => store.setCloudOn(!store.cloudOn),
      ),
    );
  }
}

/// Icon bubble, title and subtitle, with an optional trailing control.
class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: muted ? null : AppColors.primaryGradient,
                color: muted ? p.track : null,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 24, color: muted ? p.muted : Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 13, color: p.muted)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
