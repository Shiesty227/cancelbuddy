import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cancelbuddy/app_settings.dart';
import 'package:cancelbuddy/celebration.dart';
import 'package:cancelbuddy/currency_utils.dart';
import 'package:cancelbuddy/notification_service.dart';
import 'package:cancelbuddy/savings.dart';
import 'package:cancelbuddy/service_icons.dart';
import 'package:cancelbuddy/subscription.dart';
import 'package:cancelbuddy/utils/helpers.dart';
import 'package:cancelbuddy/widgets/home_cards.dart';
import 'package:cancelbuddy/widgets/spending_insights.dart';
import 'package:cancelbuddy/screens/add_subscription_screen.dart';
import 'package:cancelbuddy/screens/edit_subscription_screen.dart';
import 'package:cancelbuddy/screens/settings_screen.dart';

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen>
    with WidgetsBindingObserver {
  late Box box;

  String selectedCurrencyCode =
      AppSettings.currency;

  double monthlyTotal = 0;
  double yearlyTotal = 0;

  // Savings from cancelled subscriptions,
  // in the dashboard currency.
  double savingsPerMonth = 0;
  double savedSoFar = 0;

  bool isConverting = false;
  String? conversionError;

  final Map<String, double>
      _convertedSubscriptionPrices = {};

  final Map<String, double>
      _convertedMonthlyPrices = {};

  final Map<String, double>
      _exchangeRateCache = {};

  Timer? _renewalCheckTimer;

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    box = Hive.box('subscriptions');

    selectedCurrencyCode =
        AppSettings.currency;

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) async {
        await _refreshAppData();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    _renewalCheckTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
        AppLifecycleState.resumed) {
      _refreshAppData();
    }
  }

  // ==========================================================
  // REFRESH / RENEWALS
  // ==========================================================

  Future<void> _refreshAppData() async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;

    try {
      await _advancePastRenewals();

      if (!mounted) {
        return;
      }

      selectedCurrencyCode =
          AppSettings.currency;

      await _recalculateTotals();

      if (!mounted) {
        return;
      }

      await _recalculateSavings();

      if (!mounted) {
        return;
      }

      await _syncNotifications();
    } finally {
      _isRefreshing = false;

      if (mounted) {
        _scheduleRenewalCheck();
      }
    }
  }

  bool _isBeforeToday(
    DateTime date,
  ) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final comparisonDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return comparisonDate.isBefore(today);
  }

  Future<void> _advancePastRenewals() async {
    final now = DateTime.now();

    final entries =
        box.toMap().entries.toList();

    for (final entry in entries) {
      try {
        final map =
            Map<String, dynamic>.from(
          entry.value,
        );

        final subscription =
            Subscription.fromMap(map);

        if (!_isBeforeToday(
          subscription.renewalDate,
        )) {
          continue;
        }

        final nextDate =
            subscription.getNextRenewalDate(
          now,
        );

        if (!nextDate.isAfter(
          subscription.renewalDate,
        )) {
          continue;
        }

        final updatedSubscription =
            subscription.copyWith(
          renewalDate: nextDate,
        );

        await box.put(
          entry.key,
          updatedSubscription.toMap(),
        );
      } catch (e) {
        debugPrint(
          'Could not advance renewal: $e',
        );
      }
    }
  }

  void _scheduleRenewalCheck() {
    _renewalCheckTimer?.cancel();

    if (!mounted) {
      return;
    }

    final now = DateTime.now();

    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
      0,
      0,
      1,
    );

    final duration =
        nextMidnight.difference(now);

    _renewalCheckTimer = Timer(
      duration,
      () async {
        if (!mounted) {
          return;
        }

        await _refreshAppData();
      },
    );
  }

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  Future<void> _syncNotifications() async {
    try {
      await NotificationService.instance.syncAll(
        subs,
      );
    } catch (e) {
      debugPrint(
        'Notification sync failed: $e',
      );
    }
  }

  // ==========================================================
  // SUBSCRIPTIONS
  // ==========================================================

  List<Subscription> get subs {
    final list = <Subscription>[];

    for (final value in box.values) {
      try {
        final map =
            Map<String, dynamic>.from(
          value,
        );

        list.add(
          Subscription.fromMap(map),
        );
      } catch (_) {}
    }

    list.sort(
      (a, b) =>
          a.renewalDate.compareTo(
        b.renewalDate,
      ),
    );

    return list;
  }

  List<Subscription>
      _upcomingSubscriptions(
    List<Subscription> subscriptions,
  ) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final upcoming =
        subscriptions.where(
      (subscription) {
        final renewal = DateTime(
          subscription.renewalDate.year,
          subscription.renewalDate.month,
          subscription.renewalDate.day,
        );

        return !renewal.isBefore(today);
      },
    ).toList();

    upcoming.sort(
      (a, b) =>
          a.renewalDate.compareTo(
        b.renewalDate,
      ),
    );

    return upcoming;
  }

  Subscription? _nextRenewal(
    List<Subscription> subscriptions,
  ) {
    final upcoming =
        _upcomingSubscriptions(
      subscriptions,
    );

    if (upcoming.isEmpty) {
      return null;
    }

    return upcoming.first;
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> deleteSub(
    Subscription subscription,
  ) async {
    await NotificationService.instance
        .cancelSubscriptionReminder(
      subscription.id,
    );

    dynamic key = subscription.id;

    if (box.containsKey(key)) {
      await box.delete(key);
    } else {
      for (final existingKey in box.keys) {
        try {
          final map =
              Map<String, dynamic>.from(
            box.get(existingKey),
          );

          final existing =
              Subscription.fromMap(map);

          if (existing.name ==
                  subscription.name &&
              existing.price ==
                  subscription.price &&
              existing.cycle ==
                  subscription.cycle &&
              existing.renewalDate ==
                  subscription.renewalDate) {
            key = existingKey;
            break;
          }
        } catch (_) {}
      }

      if (key != null &&
          box.containsKey(key)) {
        await box.delete(key);
      }
    }

    if (!mounted) return;

    setState(() {});

    await _refreshAppData();
  }

  // Asks whether the user cancelled the
  // subscription or just wants it gone.
  Future<void> _confirmRemove(
    Subscription subscription,
  ) async {
    HapticFeedback.mediumImpact();

    final choice =
        await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme =
            Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              16,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Remove ${subscription.name}?',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'If you cancelled it, CancelBuddy will count what you save.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                      'cancelled',
                    );
                  },
                  icon: const Icon(
                    Icons.celebration_rounded,
                  ),
                  label: const Text(
                    'I cancelled it',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                      'delete',
                    );
                  },
                  style: OutlinedButton
                      .styleFrom(
                    foregroundColor:
                        colorScheme.error,
                  ),
                  icon: const Icon(
                    Icons
                        .delete_outline_rounded,
                  ),
                  label: const Text(
                    'Just delete it',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                  child: const Text(
                    'Keep it',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) {
      return;
    }

    if (choice == 'delete') {
      await deleteSub(subscription);
      return;
    }

    // Read before deleting: the refresh
    // afterwards clears converted prices.
    final monthly =
        _convertedMonthlyPrices[
                subscription.id] ??
            subscription.monthlyPrice;

    await SavingsStore.add(
      CancelledSubscription.fromSubscription(
        subscription,
      ),
    );

    await deleteSub(subscription);

    if (!mounted) return;

    HapticFeedback.heavyImpact();

    showConfetti(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          content: Text(
            'Nice! You\'re now saving '
            '${currencySymbolOf(selectedCurrencyCode)}'
            '${monthly.toStringAsFixed(2)} a month.',
          ),
        ),
      );
  }

  // ==========================================================
  // SAVINGS
  // ==========================================================

  Future<void> _recalculateSavings() async {
    double perMonth = 0;
    double soFar = 0;

    for (final item in SavingsStore.all) {
      try {
        final rate = await _convertAmount(
          1,
          item.currency,
          selectedCurrencyCode,
        );

        perMonth +=
            item.monthlyPrice * rate;

        soFar +=
            item.savedSoFar * rate;
      } catch (e) {
        debugPrint(
          'Could not convert savings '
          'for ${item.name}: $e',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      savingsPerMonth = perMonth;
      savedSoFar = soFar;
    });
  }

  Future<void> _openSavings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => CancelledListSheet(
        onRemove: (item) async {
          await SavingsStore.remove(
            item.id,
          );

          await _recalculateSavings();
        },
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  Future<void> updateSub(
    Subscription oldSubscription,
    Subscription newSubscription,
  ) async {
    dynamic key = oldSubscription.id;

    if (!box.containsKey(key)) {
      for (final existingKey in box.keys) {
        try {
          final map =
              Map<String, dynamic>.from(
            box.get(existingKey),
          );

          final existing =
              Subscription.fromMap(map);

          if (existing.name ==
                  oldSubscription.name &&
              existing.price ==
                  oldSubscription.price &&
              existing.cycle ==
                  oldSubscription.cycle &&
              existing.renewalDate ==
                  oldSubscription.renewalDate) {
            key = existingKey;
            break;
          }
        } catch (_) {}
      }
    }

    if (key != null &&
        box.containsKey(key)) {
      await box.put(
        key,
        newSubscription.toMap(),
      );
    } else {
      await box.add(
        newSubscription.toMap(),
      );
    }

    if (!mounted) return;

    setState(() {});

    await _refreshAppData();
  }

  // ==========================================================
  // CURRENCY
  // ==========================================================

  Future<double> _convertAmount(
    double amount,
    String from,
    String to,
  ) async {
    final source = from.toUpperCase();
    final target = to.toUpperCase();

    if (amount == 0 ||
        source == target) {
      return amount;
    }

    final cacheKey =
        '$source->$target';

    final cachedRate =
        _exchangeRateCache[cacheKey];

    if (cachedRate != null) {
      return amount * cachedRate;
    }

    final rate =
        await CurrencyUtils.exchangeRate(
      source,
      target,
    );

    _exchangeRateCache[cacheKey] =
        rate;

    return amount * rate;
  }

  Future<void> _recalculateTotals() async {
    final subscriptions = subs;

    if (subscriptions.isEmpty) {
      if (!mounted) return;

      setState(() {
        monthlyTotal = 0;
        yearlyTotal = 0;
        isConverting = false;
        conversionError = null;

        _convertedSubscriptionPrices.clear();
        _convertedMonthlyPrices.clear();
      });

      return;
    }

    if (mounted) {
      setState(() {
        isConverting = true;
        conversionError = null;
      });
    }

    double newMonthlyTotal = 0;
    double newYearlyTotal = 0;

    final convertedCyclePrices =
        <String, double>{};

    final convertedMonthlyPrices =
        <String, double>{};

    bool hadConversionFailure =
        false;

    for (final subscription in subscriptions) {
      try {
        final monthlyAmount =
            await _convertAmount(
          subscription.monthlyPrice,
          subscription.currency,
          selectedCurrencyCode,
        );

        final yearlyAmount =
            await _convertAmount(
          subscription.annualPrice,
          subscription.currency,
          selectedCurrencyCode,
        );

        final currentCycleAmount =
            await _convertAmount(
          subscription.numericPrice,
          subscription.currency,
          selectedCurrencyCode,
        );

        newMonthlyTotal +=
            monthlyAmount;

        newYearlyTotal +=
            yearlyAmount;

        convertedCyclePrices[
                subscription.id] =
            currentCycleAmount;

        convertedMonthlyPrices[
                subscription.id] =
            monthlyAmount;
      } catch (e) {
        hadConversionFailure = true;

        debugPrint(
          'Currency conversion failed '
          'for ${subscription.name}: $e',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      monthlyTotal = newMonthlyTotal;
      yearlyTotal = newYearlyTotal;

      _convertedSubscriptionPrices
        ..clear()
        ..addAll(convertedCyclePrices);

      _convertedMonthlyPrices
        ..clear()
        ..addAll(convertedMonthlyPrices);

      isConverting = false;

      conversionError =
          hadConversionFailure
              ? 'Some exchange rates could not be updated.'
              : null;
    });
  }

  // ==========================================================
  // ADD
  // ==========================================================

  Future<void> _addSubscription(
    BuildContext context,
  ) async {
    final result =
        await Navigator.push<
            Subscription?>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddSubscriptionScreen(),
      ),
    );

    if (result != null) {
      await box.add(
        result.toMap(),
      );
    }

    if (!mounted) return;

    setState(() {
      selectedCurrencyCode =
          AppSettings.currency;
    });

    await _refreshAppData();
  }

  // ==========================================================
  // SETTINGS
  // ==========================================================

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          isDarkMode:
              widget.isDarkMode,
          onThemeToggle:
              widget.onThemeToggle,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      selectedCurrencyCode =
          AppSettings.currency;
    });

    await _refreshAppData();
  }

  // ==========================================================
  // RENEWAL HELPERS
  // ==========================================================

  int daysUntil(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final renewalDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return renewalDay
        .difference(today)
        .inDays;
  }

  String renewalText(DateTime date) {
    final difference =
        daysUntil(date);

    if (difference == 0) {
      return 'Renews today';
    }

    if (difference == 1) {
      return 'Renews tomorrow';
    }

    if (difference < 0) {
      return 'Already renewed';
    }

    return 'Renews in $difference days';
  }

  String shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]}';
  }

  String greeting() {
    final hour =
        DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    if (hour < 22) {
      return 'Good evening';
    }

    return 'Good night';
  }

  String liveMessage(
    List<Subscription> subscriptions,
  ) {
    final next =
        _nextRenewal(
      subscriptions,
    );

    if (next == null) {
      if (subscriptions.isEmpty) {
        return 'Add your first subscription and let CancelBuddy keep an eye on it.';
      }

      return 'No upcoming renewals right now.';
    }

    final difference =
        daysUntil(
      next.renewalDate,
    );

    if (difference == 0) {
      return '${next.name} renews today.';
    }

    if (difference == 1) {
      return '${next.name} renews tomorrow.';
    }

    return '${next.name} renews in '
        '$difference days.';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final subscriptions = subs;

    final nextRenewal =
        _nextRenewal(
      subscriptions,
    );

    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CancelBuddy',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_rounded,
            ),
            onPressed:
                _openSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.selectionClick();

          await _refreshAppData();
        },
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            110,
          ),
          children: [
            Text(
              greeting(),
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w700,
                color:
                    colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Your subscriptions',
              style: TextStyle(
                fontSize: 27,
                fontWeight:
                    FontWeight.w900,
                letterSpacing: -0.7,
                color:
                    colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subscriptions.isEmpty
                  ? 'Keep track of what you pay for.'
                  : '${subscriptions.length} active '
                      'subscription'
                      '${subscriptions.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 14,
                color:
                    colorScheme
                        .onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            // ==================================================
            // LIVE OVERVIEW
            // ==================================================

            LiveOverviewCard(
              message:
                  liveMessage(
                subscriptions,
              ),
              nextRenewal:
                  nextRenewal,
              renewalText:
                  nextRenewal == null
                      ? null
                      : renewalText(
                          nextRenewal
                              .renewalDate,
                        ),
              dateText:
                  nextRenewal == null
                      ? null
                      : shortDate(
                          nextRenewal
                              .renewalDate,
                        ),
              price:
                  nextRenewal == null
                      ? null
                      : _convertedSubscriptionPrices[
                          nextRenewal.id],
              cycle:
                  nextRenewal?.cycle,
              currencySymbol:
                  currencySymbolOf(
                selectedCurrencyCode,
              ),
              service:
                  nextRenewal == null
                      ? null
                      : serviceStyle(
                          nextRenewal.name,
                          nextRenewal.category,
                        ).forBrightness(
                          Theme.of(context)
                              .brightness,
                        ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // TOTALS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child:
                      AnimatedTotalCard(
                    title:
                        'Monthly',
                    amount:
                        monthlyTotal,
                    color:
                        const Color(
                      0xFF5E6AD2,
                    ),
                    icon:
                        Icons
                            .calendar_month_rounded,
                    currencySymbol:
                        currencySymbolOf(
                      selectedCurrencyCode,
                    ),
                  ),
                ),
                Expanded(
                  child:
                      AnimatedTotalCard(
                    title:
                        'Yearly',
                    amount:
                        yearlyTotal,
                    color:
                        const Color(
                      0xFF00A896,
                    ),
                    icon:
                        Icons
                            .event_repeat_rounded,
                    currencySymbol:
                        currencySymbolOf(
                      selectedCurrencyCode,
                    ),
                    isRight:
                        true,
                  ),
                ),
              ],
            ),

            AnimatedSwitcher(
              duration:
                  const Duration(
                milliseconds: 220,
              ),
              child:
                  isConverting
                      ? Padding(
                          key:
                              const ValueKey(
                            'converting',
                          ),
                          padding:
                              const EdgeInsets
                                  .only(
                            top:
                                4,
                            bottom:
                                8,
                          ),
                          child:
                              Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              SizedBox(
                                width:
                                    14,
                                height:
                                    14,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      colorScheme
                                          .primary,
                                ),
                              ),
                              const SizedBox(
                                width:
                                    8,
                              ),
                              Text(
                                'Updating exchange rates...',
                                style:
                                    TextStyle(
                                  fontSize:
                                      12,
                                  color:
                                      colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(
                          key:
                              ValueKey(
                            'not-converting',
                          ),
                        ),
            ),

            AnimatedSwitcher(
              duration:
                  const Duration(
                milliseconds: 220,
              ),
              child:
                  conversionError !=
                          null
                      ? Padding(
                          key:
                              const ValueKey(
                            'conversion-error',
                          ),
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            4,
                            0,
                            4,
                            10,
                          ),
                          child:
                              Text(
                            conversionError!,
                            style:
                                TextStyle(
                              color:
                                  colorScheme
                                      .error,
                              fontSize:
                                  12,
                            ),
                            textAlign:
                                TextAlign.center,
                          ),
                        )
                      : const SizedBox(
                          key:
                              ValueKey(
                            'no-conversion-error',
                          ),
                        ),
            ),

            // ==================================================
            // SAVINGS
            // ==================================================

            if (SavingsStore.box.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: SavingsCard(
                  perMonth:
                      savingsPerMonth,
                  soFar: savedSoFar,
                  count: SavingsStore
                      .box.length,
                  currencySymbol:
                      currencySymbolOf(
                    selectedCurrencyCode,
                  ),
                  onTap: _openSavings,
                ),
              ),

            // ==================================================
            // SPENDING INSIGHT
            // ==================================================

            SpendingInsightCard(
              subscriptions:
                  subscriptions,
              convertedMonthlyPrices:
                  _convertedMonthlyPrices,
              currencySymbol:
                  currencySymbolOf(
                selectedCurrencyCode,
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // SUBSCRIPTIONS
            // ==================================================

            Row(
              children: [
                const Expanded(
                  child:
                      Text(
                    'Your subscriptions',
                    style:
                        TextStyle(
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                if (subscriptions
                    .isNotEmpty)
                  Text(
                    '${subscriptions.length}',
                    style:
                        TextStyle(
                      fontSize:
                          13,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          colorScheme
                              .onSurfaceVariant,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            if (subscriptions.isEmpty)
              EmptySubscriptionsCard(
                onAdd: () {
                  _addSubscription(
                    context,
                  );
                },
              )
            else
              ...List.generate(
                subscriptions.length,
                (index) {
                  final subscription =
                      subscriptions[index];

                  final service =
                      serviceStyle(
                    subscription.name,
                    subscription.category,
                  ).forBrightness(
                    Theme.of(context)
                        .brightness,
                  );

                  final convertedPrice =
                      _convertedSubscriptionPrices[
                          subscription.id];

                  final sameCurrency =
                      subscription.currency
                              .toUpperCase() ==
                          selectedCurrencyCode
                              .toUpperCase();

                  final displayedPrice =
                      convertedPrice ??
                          (sameCurrency
                              ? subscription
                                  .numericPrice
                              : null);

                  return AnimatedSubscriptionCard(
                    key:
                        ValueKey(
                      subscription.id,
                    ),
                    subscription:
                        subscription,
                    service:
                        service,
                    colorScheme:
                        colorScheme,
                    displayedPrice:
                        displayedPrice,
                    currencySymbol:
                        currencySymbolOf(
                      selectedCurrencyCode,
                    ),
                    renewalText:
                        renewalText(
                      subscription
                          .renewalDate,
                    ),
                    onTap:
                        () async {
                      final updated =
                          await Navigator.push<
                              Subscription?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditSubscriptionScreen(
                            sub:
                                subscription,
                          ),
                        ),
                      );

                      if (updated !=
                          null) {
                        await updateSub(
                          subscription,
                          updated,
                        );
                      }
                    },
                    onDelete:
                        () async {
                      await _confirmRemove(
                        subscription,
                      );
                    },
                    animationDelay:
                        Duration(
                      milliseconds:
                          index * 55,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            colorScheme.primary,
        foregroundColor:
            colorScheme.onPrimary,
        elevation: 4,
        onPressed: () {
          _addSubscription(
            context,
          );
        },
        icon:
            const Icon(
          Icons.add_rounded,
        ),
        label:
            const Text(
          'Add',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
