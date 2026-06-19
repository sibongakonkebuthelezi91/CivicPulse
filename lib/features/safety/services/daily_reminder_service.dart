import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DailyReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  static Future<void> scheduleDailyReminder() async {
    await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_safety_reminder',
        'Daily Safety Reminder',
        channelDescription:
            'Morning reminder to activate safety features before leaving home.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      linux: LinuxNotificationDetails(),
    );

    await _plugin.show(
      id: 0,
      title: '🛡️ Good morning! Stay safe today',
      body:
          'Remember to activate your Safe Tracker and share your journey with a Guardian Angel before leaving home.',
      notificationDetails: details,
    );
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
