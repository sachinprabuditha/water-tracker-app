import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h2go/data/cloud_sync.dart';
import 'package:h2go/data/water_store.dart';
import 'package:h2go/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cloud backup that is never configured, like a build without Firebase.
class _OfflineCloud implements CloudSync {
  @override
  bool available = false;

  @override
  bool get signedIn => false;

  @override
  Future<void> init() async {}

  @override
  Future<void> signIn() async {}

  @override
  void pushDay(String key, int ml) {}

  @override
  void pushSettings({required int goalMl, required int cupMl}) {}

  @override
  Future<Map<String, int>> pullDays({required int legacyGlassMl}) async => {};

  @override
  Future<void> deleteAllAndSignOut() async {}
}

/// Records what would be scheduled instead of touching the platform plugin.
class _FakeNotifications implements NotificationService {
  List<TimeOfDay> scheduled = [];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDaily(List<TimeOfDay> times) async => scheduled = times;

  @override
  Future<void> cancelAll() async => scheduled = [];
}

void main() {
  late _FakeNotifications notifications;

  Future<WaterStore> loadStore([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    notifications = _FakeNotifications();
    final store =
        WaterStore(cloud: _OfflineCloud(), notifications: notifications);
    await store.load();
    return store;
  }

  test('drinks add the selected cup and can be removed', () async {
    final store = await loadStore();
    expect(store.todayMl, 0);

    await store.setCupMl(350);
    final first = await store.addDrink();
    await store.addDrink(200);
    expect(store.todayMl, 550);
    expect(store.drinksOn(DateTime.now()).map((d) => d.ml), [200, 350]);

    await store.removeDrink(first);
    expect(store.todayMl, 200);
    await store.restoreDrink(first);
    expect(store.todayMl, 550);
  });

  test('today\'s total and drinks are saved and restored', () async {
    final store = await loadStore();
    await store.addDrink(240);
    await store.addDrink(500);

    final prefs = await SharedPreferences.getInstance();
    final restored = await loadStore({
      'logMl': prefs.getString('logMl')!,
      'drinks': prefs.getString('drinks')!,
    });
    expect(restored.todayMl, 740);
    expect(restored.drinksOn(DateTime.now()), hasLength(2));
    expect(restored.untrackedMlOn(DateTime.now()), 0);
  });

  test('old glasses-based data is migrated to ml', () async {
    final today = WaterStore.keyFor(DateTime.now());
    final store = await loadStore({
      'log': jsonEncode({today: 3}),
      'goal': 8,
      'glassMl': 250,
    });
    expect(store.todayMl, 750);
    expect(store.goalMl, 2000);
    expect(store.cupMl, 240); // nearest preset to 250
    // The migrated total has no individual drinks behind it.
    expect(store.untrackedMlOn(DateTime.now()), 750);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('log'), isFalse);
    expect(prefs.getInt('goalMl'), 2000);
  });

  test('goal is clamped to the slider range', () async {
    final store = await loadStore();
    await store.setGoalMl(0, push: false);
    expect(store.goalMl, WaterStore.minGoalMl);
    await store.setGoalMl(99999, push: false);
    expect(store.goalMl, WaterStore.maxGoalMl);
  });

  test('reminders are de-duplicated, sorted and scheduled', () async {
    final store = await loadStore({
      'times': <String>['12:00']
    });

    await store.addReminder(const TimeOfDay(hour: 8, minute: 30));
    await store.addReminder(const TimeOfDay(hour: 12, minute: 0));

    expect(store.reminderTimes, const [
      TimeOfDay(hour: 8, minute: 30),
      TimeOfDay(hour: 12, minute: 0),
    ]);
    expect(notifications.scheduled, store.reminderTimes);
  });

  test('turning reminders off cancels them', () async {
    final store = await loadStore();
    expect(notifications.scheduled, isNotEmpty);

    await store.setRemindersOn(false);
    expect(notifications.scheduled, isEmpty);
  });
}
