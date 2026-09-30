import 'package:hive_flutter/hive_flutter.dart';

import 'subscription.dart';

// A subscription the user has cancelled. Its monthly
// cost is kept so the app can show how much the
// user is saving by not paying for it any more.
class CancelledSubscription {
  final String id;
  final String name;
  final String category;
  final double monthlyPrice;
  final String currency;
  final DateTime cancelledAt;

  const CancelledSubscription({
    required this.id,
    required this.name,
    required this.category,
    required this.monthlyPrice,
    required this.currency,
    required this.cancelledAt,
  });

  factory CancelledSubscription.fromSubscription(
    Subscription subscription,
  ) {
    return CancelledSubscription(
      id: subscription.id,
      name: subscription.name,
      category: subscription.category,
      monthlyPrice:
          subscription.monthlyPrice,
      currency: subscription.currency,
      cancelledAt: DateTime.now(),
    );
  }

  // Months since cancelling, as a fraction,
  // e.g. 1.5 after about six weeks.
  double monthsSinceCancelled([
    DateTime? now,
  ]) {
    final days = (now ?? DateTime.now())
        .difference(cancelledAt)
        .inHours /
        24;

    if (days <= 0) {
      return 0;
    }

    return days / 30.4375;
  }

  double get savedSoFar =>
      monthlyPrice * monthsSinceCancelled();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'monthlyPrice': monthlyPrice,
      'currency': currency,
      'cancelledAt':
          cancelledAt.toIso8601String(),
    };
  }

  factory CancelledSubscription.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawPrice = map['monthlyPrice'];

    return CancelledSubscription(
      id: map['id']?.toString() ?? '',
      name:
          map['name']?.toString() ?? 'Unknown',
      category:
          map['category']?.toString() ?? 'Other',
      monthlyPrice: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(
                rawPrice?.toString() ?? '',
              ) ??
              0,
      currency:
          map['currency']?.toString() ?? 'GBP',
      cancelledAt: DateTime.tryParse(
            map['cancelledAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }
}

class SavingsStore {
  static const String boxName = 'cancelled';

  static Box get box => Hive.box(boxName);

  static List<CancelledSubscription> get all {
    final list = <CancelledSubscription>[];

    for (final value in box.values) {
      try {
        list.add(
          CancelledSubscription.fromMap(
            Map<String, dynamic>.from(value),
          ),
        );
      } catch (_) {}
    }

    list.sort(
      (a, b) =>
          b.cancelledAt.compareTo(a.cancelledAt),
    );

    return list;
  }

  static Future<void> add(
    CancelledSubscription item,
  ) async {
    await box.put(item.id, item.toMap());
  }

  static Future<void> remove(
    String id,
  ) async {
    await box.delete(id);
  }
}
