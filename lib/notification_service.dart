import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'subscription.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId =
      'cancelbuddy_renewals';

  static const String _channelName =
      'Renewal reminders';

  static const String _channelDescription =
      'Reminders for upcoming subscription renewals.';

  bool _initialized = false;

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // Initialise timezone database.
    tz.initializeTimeZones();

    // Get the device timezone.
    try {
      final timezoneInfo =
          await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(
        tz.getLocation(
          timezoneInfo.identifier,
        ),
      );

      debugPrint(
        'CancelBuddy timezone: '
        '${timezoneInfo.identifier}',
      );
    } catch (e) {
      debugPrint(
        'Could not determine local timezone: $e',
      );
    }

    // Android initialization.
    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization.
    const darwinSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings =
        InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse:
          _onNotificationTapped,
    );

    // Create Android notification channel.
    const androidChannel =
        AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      androidChannel,
    );

    _initialized = true;

    debugPrint(
      'CancelBuddy notifications initialized.',
    );
  }

  // ==========================================================
  // REQUEST PERMISSIONS
  // ==========================================================

  Future<bool> requestPermissions() async {
    await initialize();

    bool granted = true;

    // Android 13+.
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final androidGranted =
          await androidPlugin.requestNotificationsPermission();

      granted =
          androidGranted ?? true;

      debugPrint(
        'Android notification permission: '
        '$granted',
      );
    }

    // iOS.
    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final iosGranted =
          await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (iosGranted != null) {
        granted = iosGranted;
      }

      debugPrint(
        'iOS notification permission: '
        '$granted',
      );
    }

    return granted;
  }

  // ==========================================================
  // CHECK WHETHER NOTIFICATIONS ARE ENABLED
  // ==========================================================

  Future<bool> areNotificationsEnabled() async {
    await initialize();

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final enabled =
          await androidPlugin.areNotificationsEnabled();

      return enabled ?? true;
    }

    return true;
  }

  // ==========================================================
  // TEST NOTIFICATION
  // ==========================================================

  Future<void> showTestNotification() async {
    await initialize();

    final permissionGranted =
        await requestPermissions();

    if (!permissionGranted) {
      debugPrint(
        'Test notification not shown: '
        'permission denied.',
      );
      return;
    }

    const androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription:
          _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details =
        NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: 999999,
      title: 'CancelBuddy test',
      body:
          'Notifications are working correctly!',
      notificationDetails: details,
      payload: 'cancelbuddy-test',
    );

    debugPrint(
      'Test notification sent.',
    );
  }

  // ==========================================================
  // SCHEDULE ONE SUBSCRIPTION
  // ==========================================================

  Future<void> scheduleSubscriptionReminder(
    Subscription subscription,
  ) async {
    await initialize();

    // Cancel existing reminder first.
    await cancelSubscriptionReminder(
      subscription.id,
    );

    // Notifications disabled.
    if (!subscription.notificationsEnabled) {
      debugPrint(
        'Notifications disabled for '
        '${subscription.name}.',
      );
      return;
    }

    // Request permission.
    final permissionGranted =
        await requestPermissions();

    if (!permissionGranted) {
      debugPrint(
        'Notification permission denied for '
        '${subscription.name}.',
      );
      return;
    }

    // Calculate reminder date.
    final scheduledDate =
        _calculateReminderDate(
      subscription,
    );

    debugPrint(
      'Current local time: '
      '${tz.TZDateTime.now(tz.local)}',
    );

    debugPrint(
      'Calculated reminder date for '
      '${subscription.name}: '
      '$scheduledDate',
    );

    if (scheduledDate == null) {
      debugPrint(
        'Reminder is in the past for '
        '${subscription.name}.',
      );
      return;
    }

    final notificationId =
        _notificationId(
      subscription.id,
    );

    final currencySymbol =
        _currencySymbol(
      subscription.currency,
    );

    final price =
        subscription.numericPrice
            .toStringAsFixed(2);

    final title =
        '${subscription.name} renews soon';

    final body =
        '${currencySymbol}$price '
        '${subscription.cycle.toLowerCase()} '
        'subscription renews in '
        '${subscription.reminderDays} '
        '${subscription.reminderDays == 1 ? 'day' : 'days'}.';

    const androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription:
          _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details =
        NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      payload: subscription.id,
    );

    debugPrint(
      'Scheduled notification for '
      '${subscription.name} at '
      '$scheduledDate',
    );
  }

  // ==========================================================
  // CALCULATE REMINDER DATE
  // ==========================================================

  tz.TZDateTime? _calculateReminderDate(
    Subscription subscription,
  ) {
    final renewal =
        subscription.renewalDate;

    final reminderDate =
        DateTime(
      renewal.year,
      renewal.month,
      renewal.day,
    ).subtract(
      Duration(
        days: subscription.reminderDays,
      ),
    );

    final reminderDateTime =
        DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      subscription.reminderMinutes ~/ 60,
      subscription.reminderMinutes % 60,
    );

    final localDate =
        tz.TZDateTime(
      tz.local,
      reminderDateTime.year,
      reminderDateTime.month,
      reminderDateTime.day,
      reminderDateTime.hour,
      reminderDateTime.minute,
    );

    final now =
        tz.TZDateTime.now(
      tz.local,
    );

    if (!localDate.isAfter(now)) {
      return null;
    }

    return localDate;
  }

  // ==========================================================
  // CANCEL
  // ==========================================================

  Future<void> cancelSubscriptionReminder(
    String subscriptionId,
  ) async {
    await initialize();

    final id =
        _notificationId(
      subscriptionId,
    );

    await _plugin.cancel(
      id: id,
    );

    debugPrint(
      'Cancelled notification: $id',
    );
  }

  // ==========================================================
  // SYNC ONE SUBSCRIPTION
  // ==========================================================

  Future<void> syncSubscription(
    Subscription subscription,
  ) async {
    await initialize();

    await cancelSubscriptionReminder(
      subscription.id,
    );

    if (!subscription.notificationsEnabled) {
      debugPrint(
        'Notifications disabled for '
        '${subscription.name}.',
      );
      return;
    }

    await scheduleSubscriptionReminder(
      subscription,
    );
  }

  // ==========================================================
  // SYNC ALL SUBSCRIPTIONS
  // ==========================================================

  Future<void> syncAll(
    Iterable<Subscription> subscriptions,
  ) async {
    await initialize();

    final list =
        subscriptions.toList();

    debugPrint(
      'Syncing notifications for '
      '${list.length} subscriptions.',
    );

    for (final subscription in list) {
      try {
        await syncSubscription(
          subscription,
        );
      } catch (e) {
        debugPrint(
          'Failed to sync notification for '
          '${subscription.name}: $e',
        );
      }
    }
  }

  // ==========================================================
  // PENDING NOTIFICATIONS
  // ==========================================================

  Future<List<PendingNotificationRequest>>
      pendingNotifications() async {
    await initialize();

    final pending =
        await _plugin
            .pendingNotificationRequests();

    debugPrint(
      'Pending notifications: '
      '${pending.length}',
    );

    for (final notification
        in pending) {
      debugPrint(
        'Pending: '
        '${notification.id} '
        '${notification.title}',
      );
    }

    return pending;
  }

  // ==========================================================
  // NOTIFICATION ID
  // ==========================================================

  int _notificationId(
    String subscriptionId,
  ) {
    var hash = 0;

    for (final codeUnit
        in subscriptionId.codeUnits) {
      hash =
          ((hash * 31) + codeUnit) &
              0x7fffffff;
    }

    if (hash == 0) {
      return 1;
    }

    return hash;
  }

  // ==========================================================
  // CURRENCY SYMBOL
  // ==========================================================

  String _currencySymbol(
    String currency,
  ) {
    switch (currency.toUpperCase()) {
      case 'GBP':
        return '£';

      case 'EUR':
        return '€';

      case 'USD':
        return '\$';

      default:
        return currency;
    }
  }

  // ==========================================================
  // NOTIFICATION TAP
  // ==========================================================

  void _onNotificationTapped(
    NotificationResponse response,
  ) {
    debugPrint(
      'Notification tapped: '
      '${response.payload}',
    );
  }
}