import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/water_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  static const _pages = [TodayScreen(), HistoryScreen(), SettingsScreen()];
  static const _tabs = [
    (Icons.water_drop_outlined, Icons.water_drop_rounded, 'Today'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'History'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WaterStore>().ensureNotificationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Roll "today" over if the app stayed in the background past midnight.
    if (state == AppLifecycleState.resumed) {
      context.read<WaterStore>().refresh();
    }
  }

  void _select(int i) {
    if (i == _index) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    // Every tab starts with a blue header, so the status bar icons are white.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            for (var i = 0; i < _pages.length; i++)
              _FadeThroughPage(active: i == _index, child: _pages[i]),
          ],
        ),
        bottomNavigationBar: _FloatingNavBar(
          index: _index,
          tabs: _tabs,
          onSelect: _select,
        ),
      ),
    );
  }
}

/// Keeps every tab alive and cross-fades between them with a small lift.
/// Hidden tabs ignore touches, are hidden from screen readers, and have their
/// animations paused.
class _FadeThroughPage extends StatelessWidget {
  const _FadeThroughPage({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 320);
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.025),
            duration: duration,
            curve: Curves.easeOutCubic,
            // Inside the fade, so muting the page never freezes the fade.
            child: TickerMode(enabled: active, child: child),
          ),
        ),
      ),
    );
  }
}

/// Rounded white bar floating above the bottom edge. The active tab grows
/// into a blue pill showing its name.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar(
      {required this.index, required this.tabs, required this.onSelect});

  final int index;
  final List<(IconData, IconData, String)> tabs;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                  color: p.shadow, blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _NavItem(
                  icon: tabs[i].$1,
                  activeIcon: tabs[i].$2,
                  label: tabs[i].$3,
                  active: i == index,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Bouncy(
      onTap: onTap,
      label: label,
      selected: active,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: active ? 18 : 14),
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon,
                size: 26, color: active ? Colors.white : p.muted),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(label,
                          style: const TextStyle(
                              fontFamily: AppTheme.display,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
