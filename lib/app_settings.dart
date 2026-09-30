
import 'package:hive_flutter/hive_flutter.dart';


// ============================================================
// APP SETTINGS
// ============================================================

class AppSettings {
  static const String boxName = 'settings';

  static const String defaultReminderDaysKey =
      'defaultReminderDays';

  static const String defaultReminderMinutesKey =
      'defaultReminderMinutes';

  static const String currencyKey = 'currency';

  static const String darkModeKey = 'darkMode';

  static Box get box => Hive.box(boxName);

  static int get defaultReminderDays {
    final value = box.get(
      defaultReminderDaysKey,
      defaultValue: 7,
    );

    final parsed = value is int
        ? value
        : int.tryParse(
              value.toString(),
            ) ??
            7;

    const allowed = [1, 3, 7, 14];

    return allowed.contains(parsed) ? parsed : 7;
  }

  static int get defaultReminderMinutes {
    final value = box.get(
      defaultReminderMinutesKey,
      defaultValue: 9 * 60,
    );

    final parsed = value is int
        ? value
        : int.tryParse(
              value.toString(),
            ) ??
            9 * 60;

    if (parsed < 0 || parsed >= 24 * 60) {
      return 9 * 60;
    }

    return parsed;
  }

  static String get currency {
    final value = box.get(
      currencyKey,
      defaultValue: 'GBP',
    );

    final currency = value?.toString().toUpperCase();

    if (currency == 'USD' ||
        currency == 'EUR' ||
        currency == 'GBP') {
      return currency!;
    }

    return 'GBP';
  }

  static bool get darkMode {
    final value = box.get(
      darkModeKey,
      defaultValue: false,
    );

    return value is bool ? value : false;
  }
}
