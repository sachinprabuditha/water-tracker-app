import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../theme/app_theme.dart';

/// Daily repeating local notifications (no server, no FCM needed).
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _bodies = [
    'A quick sip keeps you on track today.',
    'Stay hydrated - tap to log your glass.',
    'Your body will thank you. Drink up!',
    'Almost there - keep sipping!',
  ];

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Could not resolve local timezone, falling back to UTC: $e');
    }

    // Monochrome status-bar icon (res/drawable/ic_notification.xml).
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    await _plugin.initialize(
        settings: const InitializationSettings(android: android));
  }

  /// Shows the Android 13+ notification permission dialog if needed.
  Future<bool> requestPermission() async {
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await impl?.requestNotificationsPermission() ?? false;
  }

  Future<void> scheduleDaily(List<TimeOfDay> times) async {
    await _plugin.cancelAll();
    for (var i = 0; i < times.length; i++) {
      await _plugin.zonedSchedule(
        id: 100 + i,
        title: 'H2Go: time for a glass of water \u{1F4A7}',
        body: _bodies[i % _bodies.length],
        scheduledDate: _nextInstance(times[i]),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_reminders',
            'Water reminders',
            channelDescription: 'Daily reminders to drink water',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            color: AppColors.blue,
          ),
        ),
        // Inexact = no special "exact alarm" permission, which keeps Play review simple.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  tz.TZDateTime _nextInstance(TimeOfDay t) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, now.day + 1, t.hour, t.minute);
    }
    return scheduled;
  }
}
