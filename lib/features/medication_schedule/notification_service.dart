import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/config/constants.dart';

/// Thin wrapper around `flutter_local_notifications`. Centralises the
/// channel id and permission flow so callers don't have to think about
/// the platform-specific plugin API.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _timers = <int, Timer>{};
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    try {
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      // Non-fatal: notifications are a best-effort enhancement, and
      // the app must still run on platforms without them (e.g. web).
      if (kDebugMode) debugPrint('NotificationService init failed: $e');
    }
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    if (granted != null) return granted;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_ready) return;
    final delay = when.difference(DateTime.now());
    if (delay.isNegative) return;
    _timers[id]?.cancel();
    _timers[id] = Timer(delay, () {
      _timers.remove(id);
      unawaited(
        _plugin.show(
          id,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              AppConstants.notificationChannelId,
              AppConstants.notificationChannelName,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        ),
      );
    });
  }

  Future<void> cancel(int id) async {
    _timers.remove(id)?.cancel();
    if (!_ready) return;
    await _plugin.cancel(id);
  }
}
