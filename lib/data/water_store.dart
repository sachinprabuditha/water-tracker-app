import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import 'cloud_sync.dart';
import 'cups.dart';

/// One logged drink, kept for the History timeline and for undo.
@immutable
class Drink {
  const Drink(this.ml, this.at);

  final int ml;
  final DateTime at;

  Map<String, Object> toJson() => {'ml': ml, 'at': at.toIso8601String()};

  static Drink fromJson(Map<String, dynamic> j) =>
      Drink((j['ml'] as num).toInt(), DateTime.parse(j['at'] as String));
}

/// App state. Local storage (SharedPreferences) is the source of truth;
/// Firestore is a best-effort backup layered on top.
///
/// Each day's total ml is stored separately from the drinks list, because
/// totals restored from the cloud or migrated from the old glasses-based log
/// have no individual drinks behind them.
class WaterStore extends ChangeNotifier {
  WaterStore({required this.cloud, required this.notifications});

  final CloudSync cloud;
  final NotificationService notifications;

  /// How long individual drinks are kept. Day totals are kept forever.
  static const keepDrinksFor = Duration(days: 35);
  static const minGoalMl = 500;
  static const maxGoalMl = 5000;

  late SharedPreferences _prefs;
  Map<String, int> _log = {}; // yyyy-MM-dd -> ml
  List<Drink> _drinks = []; // oldest first

  /// Glass size of the old glasses-based version, for migrating its data.
  int _legacyGlassMl = 250;

  int goalMl = 2000;
  int cupMl = Cup.fallback.ml;
  bool remindersOn = true;
  bool cloudOn = true;
  List<TimeOfDay> reminderTimes = const [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  ];

  bool get cloudAvailable => cloud.available;
  Cup get cup => Cup.forMl(cupMl);

  // ---------------------------------------------------------------- queries

  static String keyFor(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  int get todayMl => mlFor(DateTime.now());
  int mlFor(DateTime d) => _log[keyFor(d)] ?? 0;

  /// That day's drinks, newest first.
  List<Drink> drinksOn(DateTime d) {
    final key = keyFor(d);
    return _drinks.where((e) => keyFor(e.at) == key).toList().reversed.toList();
  }

  /// Part of that day's total with no drink behind it (restored or migrated).
  int untrackedMlOn(DateTime d) {
    final logged = drinksOn(d).fold(0, (sum, e) => sum + e.ml);
    return (mlFor(d) - logged).clamp(0, 1 << 30);
  }

  /// Called when the app resumes so "today" rolls over after midnight.
  void refresh() => notifyListeners();

  // ---------------------------------------------------------------- loading

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _legacyGlassMl = _prefs.getInt('glassMl') ?? _legacyGlassMl;

    final legacyGoal = _prefs.getInt('goal');
    goalMl = _prefs.getInt('goalMl') ??
        (legacyGoal != null ? legacyGoal * _legacyGlassMl : goalMl);
    goalMl = goalMl.clamp(minGoalMl, maxGoalMl);
    cupMl = Cup.nearest(_prefs.getInt('cupMl') ?? _legacyGlassMl).ml;
    remindersOn = _prefs.getBool('remindersOn') ?? remindersOn;
    cloudOn = _prefs.getBool('cloudOn') ?? cloudOn;

    final times = _prefs.getStringList('times');
    if (times != null) reminderTimes = times.map(_parse).toList();

    final rawMl = _prefs.getString('logMl');
    final rawGlasses = _prefs.getString('log');
    if (rawMl != null) {
      _log = _decodeCounts(rawMl);
    } else if (rawGlasses != null) {
      _log = _decodeCounts(rawGlasses)
          .map((k, glasses) => MapEntry(k, glasses * _legacyGlassMl));
    }
    if (rawGlasses != null || legacyGoal != null) await _migrated();

    final rawDrinks = _prefs.getString('drinks');
    if (rawDrinks != null) {
      final cutoff = DateTime.now().subtract(keepDrinksFor);
      _drinks = (jsonDecode(rawDrinks) as List)
          .map((e) => Drink.fromJson(e as Map<String, dynamic>))
          .where((e) => e.at.isAfter(cutoff))
          .toList();
    }

    await _applyReminders();
    notifyListeners();
    unawaited(_startCloud());
  }

  /// Rewrites the old glasses-based keys in ml, then drops them. 'glassMl'
  /// stays: cloud days saved by the old version still need converting.
  Future<void> _migrated() async {
    await _saveLog();
    await _prefs.setInt('goalMl', goalMl);
    await _prefs.setInt('cupMl', cupMl);
    await _prefs.remove('log');
    await _prefs.remove('goal');
  }

  /// Ask for notification permission (Android 13+). Safe to call repeatedly.
  Future<void> ensureNotificationPermission() async {
    if (remindersOn) await notifications.requestPermission();
  }

  // ---------------------------------------------------------------- actions

  /// Logs a drink of [ml] (the selected cup by default) and returns it.
  Future<Drink> addDrink([int? ml]) async {
    final drink = Drink(ml ?? cupMl, DateTime.now());
    await restoreDrink(drink);
    return drink;
  }

  /// Puts back a drink, e.g. one that was just deleted.
  Future<void> restoreDrink(Drink drink) async {
    _drinks = [..._drinks, drink]..sort((a, b) => a.at.compareTo(b.at));
    await _changeDay(drink.at, drink.ml);
  }

  Future<void> removeDrink(Drink drink) async {
    final i = _drinks.lastIndexOf(drink);
    if (i < 0) return;
    _drinks = [..._drinks]..removeAt(i);
    await _changeDay(drink.at, -drink.ml);
  }

  Future<void> _changeDay(DateTime day, int deltaMl) async {
    final key = keyFor(day);
    final value = ((_log[key] ?? 0) + deltaMl).clamp(0, 1 << 30);
    _log[key] = value;
    notifyListeners();
    await _saveLog();
    await _prefs.setString(
        'drinks', jsonEncode(_drinks.map((e) => e.toJson()).toList()));
    if (cloudOn) cloud.pushDay(key, value);
  }

  Future<void> setGoalMl(int v, {bool push = true}) async {
    goalMl = v.clamp(minGoalMl, maxGoalMl);
    await _prefs.setInt('goalMl', goalMl);
    notifyListeners();
    if (push) pushSettings();
  }

  Future<void> setCupMl(int v) async {
    cupMl = Cup.nearest(v).ml;
    await _prefs.setInt('cupMl', cupMl);
    notifyListeners();
    pushSettings();
  }

  void pushSettings() {
    if (cloudOn) cloud.pushSettings(goalMl: goalMl, cupMl: cupMl);
  }

  Future<void> setRemindersOn(bool v) async {
    remindersOn = v;
    await _prefs.setBool('remindersOn', v);
    if (v) await notifications.requestPermission();
    await _applyReminders();
    notifyListeners();
  }

  Future<void> addReminder(TimeOfDay t) async {
    if (reminderTimes.any((e) => e.hour == t.hour && e.minute == t.minute)) {
      return;
    }
    if (reminderTimes.length >= 12) return;
    reminderTimes = [...reminderTimes, t]..sort(_byTime);
    await _saveTimes();
  }

  Future<void> removeReminder(int index) async {
    reminderTimes = [...reminderTimes]..removeAt(index);
    await _saveTimes();
  }

  Future<void> setCloudOn(bool v) async {
    cloudOn = v;
    await _prefs.setBool('cloudOn', v);
    notifyListeners();
    if (v) {
      unawaited(_startCloud());
    } else {
      await cloud.deleteAllAndSignOut();
    }
  }

  // ---------------------------------------------------------------- internals

  Future<void> _saveTimes() async {
    await _prefs.setStringList('times', reminderTimes.map(_fmt).toList());
    await _applyReminders();
    notifyListeners();
  }

  Future<void> _saveLog() => _prefs.setString('logMl', jsonEncode(_log));

  Future<void> _applyReminders() async {
    try {
      if (remindersOn && reminderTimes.isNotEmpty) {
        await notifications.scheduleDaily(reminderTimes);
      } else {
        await notifications.cancelAll();
      }
    } catch (e) {
      debugPrint('Scheduling reminders failed: $e');
    }
  }

  /// Sign in, merge remote days into local (max wins), push anything local is
  /// ahead on. Max-merge is simple and safe for a total that mostly goes up.
  Future<void> _startCloud() async {
    if (!cloud.available || !cloudOn) return;
    await cloud.signIn();
    if (!cloud.signedIn) return;

    final remote = await cloud.pullDays(legacyGlassMl: _legacyGlassMl);
    var changed = false;
    remote.forEach((k, v) {
      if (v > (_log[k] ?? 0)) {
        _log[k] = v;
        changed = true;
      }
    });
    if (changed) {
      await _saveLog();
      notifyListeners();
    }
    for (final e in _log.entries) {
      if (e.value > (remote[e.key] ?? 0)) cloud.pushDay(e.key, e.value);
    }
    pushSettings();
  }

  static Map<String, int> _decodeCounts(String raw) =>
      (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));

  static int _byTime(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute);

  static TimeOfDay _parse(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
