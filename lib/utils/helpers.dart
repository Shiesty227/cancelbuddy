

import 'package:cancelbuddy/currency_utils.dart';

// ============================================================
// DATE FORMATTING
// ============================================================

String formatDate(
  DateTime date,
) {
  final day =
      date.day
          .toString()
          .padLeft(
            2,
            '0',
          );

  final month =
      date.month
          .toString()
          .padLeft(
            2,
            '0',
          );

  final year =
      date.year.toString();

  return '$year-$month-$day';
}

String formatLongDate(
  DateTime date,
) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${date.day} '
      '${months[date.month - 1]} '
      '${date.year}';
}

// ============================================================
// PRICE / CYCLE HELPERS
// ============================================================

String cleanPrice(
  String price,
) {
  return price
      .trim()
      .replaceFirst(
        RegExp(
          r'^(GBP|USD|EUR)\s*',
          caseSensitive:
              false,
        ),
        '',
      )
      .replaceFirst(
        RegExp(
          r'^[£€\$]\s*',
        ),
        '',
      )
      .trim();
}

double? parseNumericPrice(
  String price,
) {
  final cleaned =
      cleanPrice(
    price,
  ).replaceAll(
    ',',
    '',
  );

  return double.tryParse(
    cleaned,
  );
}

double convertCyclePrice(
  double price,
  String fromCycle,
  String toCycle,
) {
  final from =
      fromCycle
          .trim()
          .toLowerCase();

  final to =
      toCycle
          .trim()
          .toLowerCase();

  if (from ==
      to) {
    return price;
  }

  double monthly;

  switch (from) {
    case 'weekly':
      monthly =
          price * 4.345;
      break;

    case 'yearly':
    case 'annual':
      monthly =
          price / 12;
      break;

    case 'monthly':
    default:
      monthly =
          price;
      break;
  }

  switch (to) {
    case 'weekly':
      return monthly / 4.345;

    case 'yearly':
    case 'annual':
      return monthly * 12;

    case 'monthly':
    default:
      return monthly;
  }
}

// ============================================================
// CURRENCY HELPERS
// ============================================================

String currencySymbolOf(
  String code,
) {
  return CurrencyUtils.symbolOf(
    code,
  );
}

// ============================================================
// CATEGORY HELPERS
// ============================================================

String normalizeSubscriptionCategory(
  String category,
) {
  final value =
      category.trim();

  if (value.toLowerCase() ==
      'cloud storage') {
    return 'Cloud';
  }

  if (value.isEmpty) {
    return 'Other';
  }

  return value;
}
