import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

enum NotificationVerbosity { off, minimal, all }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationVerbosity _verbosity = NotificationVerbosity.all;
  NotificationVerbosity get verbosity => _verbosity;

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS, configure DarwinInitializationSettings if needed, skipping for now
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Request permissions for newer Android versions (Android 13+)
    _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    await _loadPreferences();
    await _scheduleNotifications();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final verbosityIndex = prefs.getInt('notification_verbosity') ?? NotificationVerbosity.all.index;
    _verbosity = NotificationVerbosity.values[verbosityIndex];
  }

  Future<void> setVerbosity(NotificationVerbosity verbosity) async {
    _verbosity = verbosity;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_verbosity', verbosity.index);
    await _scheduleNotifications();
  }

  Future<void> setCustomReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_reminder_hour', hour);
    await prefs.setInt('custom_reminder_minute', minute);
    await _scheduleNotifications();
  }

  Future<void> _scheduleNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();

    if (_verbosity == NotificationVerbosity.off) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('custom_reminder_hour');
    final minute = prefs.getInt('custom_reminder_minute');

    if (hour != null && minute != null) {
      await _scheduleDailyReminder(hour, minute);
    }

    if (_verbosity == NotificationVerbosity.all) {
      await _scheduleRandomReminders();
    }
  }

  Future<void> _scheduleDailyReminder(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Reminders to do your lessons daily.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0, // ID for daily reminder
      title: 'Time to Practice!',
      body: 'Jump in and complete a lesson today.',
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleRandomReminders() async {
    // Schedule a random reminder in the next 1-3 days
    final random = Random();
    final daysToWait = random.nextInt(3) + 1;
    final hour = random.nextInt(8) + 10; // Between 10 AM and 6 PM
    final minute = random.nextInt(60);

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(days: daysToWait, hours: hour - now.hour, minutes: minute - now.minute));

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'random_reminder_channel',
      'Random Reminders',
      channelDescription: 'Random reminders to keep you engaged.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    final messages = [
      'Don\'t break your streak! Keep learning.',
      'A new sign awaits you. Jump in!',
      'Ready for a quick practice session?',
    ];

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 1, // ID for random reminder
      title: 'Keep it up!',
      body: messages[random.nextInt(messages.length)],
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
