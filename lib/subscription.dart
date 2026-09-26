import 'dart:math';

class Subscription {
  final String id;
  final String name;
  final String price;
  final String cycle;
  final DateTime renewalDate;
  final String currency;
  final String category;
  final String notes;
  final String cancellationUrl;
  final bool notificationsEnabled;
  final int reminderDays;
  final int reminderMinutes;

  Subscription({
    String? id,
    required this.name,
    required this.price,
    required this.cycle,
    required this.renewalDate,
    this.currency = 'GBP',
    this.category = 'Other',
    this.notes = '',
    this.cancellationUrl = '',
    this.notificationsEnabled = true,
    this.reminderDays = 7,
    this.reminderMinutes = 9 * 60,
  }) : id = id ?? _generateId();

  static String _generateId() {
    final random = Random();
    final timestamp =
        DateTime.now().microsecondsSinceEpoch;

    return '$timestamp-${random.nextInt(999999)}';
  }

  double get numericPrice {
    final cleaned = price
        .replaceAll(',', '')
        .replaceAll(
          RegExp(r'[^0-9.]'),
          '',
        );

    return double.tryParse(cleaned) ?? 0;
  }

  double get monthlyPrice {
    switch (cycle.trim().toLowerCase()) {
      case 'weekly':
        return numericPrice * 4.345;

      case 'yearly':
      case 'annual':
        return numericPrice / 12;

      case 'monthly':
      default:
        return numericPrice;
    }
  }

  double get annualPrice {
    switch (cycle.trim().toLowerCase()) {
      case 'weekly':
        return numericPrice * 52.143;

      case 'yearly':
      case 'annual':
        return numericPrice;

      case 'monthly':
      default:
        return numericPrice * 12;
    }
  }

  DateTime getNextRenewalDate([
    DateTime? now,
  ]) {
    final currentTime =
        now ?? DateTime.now();

    final normalizedCycle =
        cycle.trim().toLowerCase();

    if (renewalDate.isAfter(
      currentTime,
    )) {
      return renewalDate;
    }

    switch (normalizedCycle) {
      case 'weekly':
        DateTime next = renewalDate;

        while (!next.isAfter(
          currentTime,
        )) {
          next = next.add(
            const Duration(
              days: 7,
            ),
          );
        }

        return next;

      case 'yearly':
      case 'annual':
        int periods = 1;

        DateTime next =
            _addMonthsFromAnchor(
          renewalDate,
          12 * periods,
        );

        while (!next.isAfter(
          currentTime,
        )) {
          periods++;

          next =
              _addMonthsFromAnchor(
            renewalDate,
            12 * periods,
          );
        }

        return next;

      case 'monthly':
      default:
        int periods = 1;

        DateTime next =
            _addMonthsFromAnchor(
          renewalDate,
          periods,
        );

        while (!next.isAfter(
          currentTime,
        )) {
          periods++;

          next =
              _addMonthsFromAnchor(
            renewalDate,
            periods,
          );
        }

        return next;
    }
  }

  bool get needsRenewalUpdate {
    return !renewalDate.isAfter(
      DateTime.now(),
    );
  }

  Subscription advanceToNextRenewal([
    DateTime? now,
  ]) {
    final nextDate =
        getNextRenewalDate(now);

    if (nextDate == renewalDate) {
      return this;
    }

    return copyWith(
      renewalDate: nextDate,
    );
  }

  static DateTime _addMonthsFromAnchor(
    DateTime anchor,
    int months,
  ) {
    final totalMonths =
        anchor.year * 12 +
        (anchor.month - 1) +
        months;

    final year =
        totalMonths ~/ 12;

    final month =
        totalMonths % 12 + 1;

    final lastDayOfMonth =
        DateTime(
      year,
      month + 1,
      0,
    ).day;

    final day =
        anchor.day > lastDayOfMonth
            ? lastDayOfMonth
            : anchor.day;

    return DateTime(
      year,
      month,
      day,
      anchor.hour,
      anchor.minute,
      anchor.second,
      anchor.millisecond,
      anchor.microsecond,
    );
  }

  Subscription copyWith({
    String? id,
    String? name,
    String? price,
    String? cycle,
    DateTime? renewalDate,
    String? currency,
    String? category,
    String? notes,
    String? cancellationUrl,
    bool? notificationsEnabled,
    int? reminderDays,
    int? reminderMinutes,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      cycle: cycle ?? this.cycle,
      renewalDate:
          renewalDate ?? this.renewalDate,
      currency:
          currency ?? this.currency,
      category:
          category ?? this.category,
      notes:
          notes ?? this.notes,
      cancellationUrl:
          cancellationUrl ?? this.cancellationUrl,
      notificationsEnabled:
          notificationsEnabled ??
          this.notificationsEnabled,
      reminderDays:
          reminderDays ?? this.reminderDays,
      reminderMinutes:
          reminderMinutes ??
          this.reminderMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'cycle': cycle,
      'renewalDate':
          renewalDate.toIso8601String(),
      'currency': currency,
      'category': category,
      'notes': notes,
      'cancellationUrl':
          cancellationUrl,
      'notificationsEnabled':
          notificationsEnabled,
      'reminderDays':
          reminderDays,
      'reminderMinutes':
          reminderMinutes,
    };
  }

  factory Subscription.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawCurrency =
        map['currency']?.toString();

    final rawReminderDays =
        map['reminderDays'];

    final parsedReminderDays =
        rawReminderDays is int
            ? rawReminderDays
            : int.tryParse(
                rawReminderDays?.toString() ??
                    '',
              );

    final rawReminderMinutes =
        map['reminderMinutes'];

    final parsedReminderMinutes =
        rawReminderMinutes is int
            ? rawReminderMinutes
            : int.tryParse(
                rawReminderMinutes?.toString() ??
                    '',
              );

    return Subscription(
      id:
          map['id']?.toString(),
      name:
          map['name']?.toString() ??
              'Unknown',
      price:
          map['price']?.toString() ??
              '',
      cycle:
          map['cycle']?.toString() ??
              'Monthly',
      renewalDate:
          DateTime.tryParse(
                map['renewalDate']
                        ?.toString() ??
                    '',
              ) ??
              DateTime.now(),
      currency:
          rawCurrency?.isNotEmpty == true
              ? rawCurrency!
              : _inferCurrency(
                  map['price']?.toString() ??
                      '',
                ),
      category:
          map['category']
                      ?.toString()
                      .isNotEmpty ==
                  true
              ? map['category'].toString()
              : 'Other',
      notes:
          map['notes']?.toString() ??
              '',
      cancellationUrl:
          map['cancellationUrl']
                  ?.toString() ??
              '',
      notificationsEnabled:
          map['notificationsEnabled']
                  is bool
              ? map['notificationsEnabled']
                  as bool
              : true,
      reminderDays:
          _validReminderDays(
        parsedReminderDays ?? 7,
      ),
      reminderMinutes:
          _validReminderMinutes(
        parsedReminderMinutes ??
            9 * 60,
      ),
    );
  }

  static String _inferCurrency(
    String price,
  ) {
    final value =
        price.toUpperCase();

    if (value.contains('GBP') ||
        price.contains('£')) {
      return 'GBP';
    }

    if (value.contains('EUR') ||
        price.contains('€')) {
      return 'EUR';
    }

    if (value.contains('USD') ||
        price.contains('\$')) {
      return 'USD';
    }

    return 'GBP';
  }

  static int _validReminderDays(
    int value,
  ) {
    const allowed = [
      1,
      3,
      7,
      14,
    ];

    if (allowed.contains(value)) {
      return value;
    }

    return 7;
  }

  static int _validReminderMinutes(
    int value,
  ) {
    if (value < 0 ||
        value >= 24 * 60) {
      return 9 * 60;
    }

    return value;
  }
}