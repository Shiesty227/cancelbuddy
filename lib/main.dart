import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'choose_subscription.dart';
import 'currency_utils.dart';
import 'notification_service.dart';
import 'service_icons.dart';
import 'subscription.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox('subscriptions');
  await Hive.openBox('settings');

  await NotificationService.instance.initialize();

  runApp(const CancelBuddyApp());
}

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

// ============================================================
// APP
// ============================================================

class CancelBuddyApp extends StatefulWidget {
  const CancelBuddyApp({super.key});

  @override
  State<CancelBuddyApp> createState() =>
      _CancelBuddyAppState();
}

class _CancelBuddyAppState
    extends State<CancelBuddyApp> {
  bool isDark = AppSettings.darkMode;

  void toggle() {
    setState(() {
      isDark = !isDark;
    });

    AppSettings.box.put(
      AppSettings.darkModeKey,
      isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CancelBuddy',
      themeMode:
          isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed:
            const Color(0xFF5E6AD2),
        scaffoldBackgroundColor:
            const Color(0xFFF7F8FC),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide:
                const BorderSide(
              color: Color(0xFF5E6AD2),
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed:
            const Color(0xFF7C83E8),
        scaffoldBackgroundColor:
            const Color(0xFF101116),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor:
              const Color(0xFF191A21),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide:
                const BorderSide(
              color: Color(0xFF7C83E8),
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
      home: HomeScreen(
        isDarkMode: isDark,
        onThemeToggle: toggle,
      ),
    );
  }
}

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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChooseSubscriptionScreen(
          onSubscriptionSelected:
              (subscription) async {
            final isManual =
                subscription.name ==
                    '__manual__';

            final result =
                await Navigator.push<
                    Subscription?>(
              context,
              MaterialPageRoute(
                builder: (_) {
                  if (isManual) {
                    return const AddSubscriptionScreen();
                  }

                  return AddSubscriptionScreen(
                    prefillName:
                        subscription.name,
                    prefillPrice:
                        subscription.price,
                    prefillCycle:
                        subscription.cycle,
                    prefillCategory:
                        subscription.category,
                  );
                },
              ),
            );

            if (result == null) {
              return;
            }

            await box.add(
              result.toMap(),
            );

            if (!mounted) return;

            Navigator.pop(context);

            setState(() {});

            await _refreshAppData();
          },
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

            _LiveOverviewCard(
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
                      _AnimatedTotalCard(
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
                      _AnimatedTotalCard(
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
            // SPENDING INSIGHT
            // ==================================================

            _SpendingInsightCard(
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
              _EmptySubscriptionsCard(
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

                  return _AnimatedSubscriptionCard(
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
                      await deleteSub(
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

// ============================================================
// LIVE OVERVIEW
// ============================================================

class _LiveOverviewCard
    extends StatelessWidget {
  final String message;
  final Subscription? nextRenewal;
  final String? renewalText;
  final String? dateText;
  final double? price;
  final String? cycle;
  final String currencySymbol;
  final ServiceStyle? service;

  const _LiveOverviewCard({
    required this.message,
    required this.nextRenewal,
    required this.renewalText,
    required this.dateText,
    required this.price,
    required this.cycle,
    required this.currencySymbol,
    required this.service,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final renewal = nextRenewal;

    final accent =
        service?.color ??
            colorScheme.primary;

    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 300,
      ),
      curve:
          Curves.easeOutCubic,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            accent.withValues(
              alpha: 0.14,
            ),
            colorScheme
                .surfaceContainerHighest
                .withValues(
              alpha: 0.72,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
        border:
            Border.all(
          color:
              accent.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PulseDot(
                color:
                    accent,
              ),
              const SizedBox(
                width:
                    8,
              ),
              Text(
                'Live overview',
                style:
                    TextStyle(
                  fontSize:
                      12,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                  letterSpacing:
                      0.2,
                ),
              ),
            ],
          ),
          const SizedBox(
            height:
                9,
          ),
          AnimatedSwitcher(
            duration:
                const Duration(
              milliseconds:
                  280,
            ),
            transitionBuilder:
                (
              child,
              animation,
            ) {
              return FadeTransition(
                opacity:
                    animation,
                child:
                    SlideTransition(
                  position:
                      Tween<Offset>(
                    begin:
                        const Offset(
                      0,
                      0.12,
                    ),
                    end:
                        Offset.zero,
                  ).animate(
                    animation,
                  ),
                  child:
                      child,
                ),
              );
            },
            child:
                Text(
              message,
              key:
                  ValueKey(
                message,
              ),
              style:
                  const TextStyle(
                fontSize:
                    18,
                fontWeight:
                    FontWeight.w800,
                height:
                    1.15,
              ),
            ),
          ),
          if (renewal != null) ...[
            const SizedBox(
              height:
                  15,
            ),
            Row(
              children: [
                Container(
                  width:
                      42,
                  height:
                      42,
                  decoration:
                      BoxDecoration(
                    color:
                        service?.backgroundColor ??
                            accent.withValues(
                              alpha:
                                  0.10,
                            ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child:
                      Icon(
                    service?.icon ??
                        Icons
                            .event_rounded,
                    color:
                        accent,
                    size:
                        21,
                  ),
                ),
                const SizedBox(
                  width:
                      10,
                ),
                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        renewal.name,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize:
                              14,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height:
                            2,
                      ),
                      Text(
                        '${renewalText ?? ''}'
                        ' · '
                        '${dateText ?? ''}',
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
                ),
                if (price != null)
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .end,
                    children: [
                      Text(
                        '$currencySymbol'
                        '${price!.toStringAsFixed(2)}',
                        style:
                            TextStyle(
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              accent,
                        ),
                      ),
                      const SizedBox(
                        height:
                            2,
                      ),
                      Text(
                        cycle ?? '',
                        style:
                            TextStyle(
                          fontSize:
                              11,
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// PULSE DOT
// ============================================================

class _PulseDot
    extends StatefulWidget {
  final Color color;

  const _PulseDot({
    required this.color,
  });

  @override
  State<_PulseDot> createState() =>
      _PulseDotState();
}

class _PulseDotState
    extends State<_PulseDot>
    with
        SingleTickerProviderStateMixin {
  late final AnimationController
      _controller;

  late final Animation<double>
      _animation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
      vsync:
          this,
      duration:
          const Duration(
        milliseconds:
            1200,
      ),
    )..repeat(
        reverse:
            true,
      );

    _animation =
        Tween<double>(
      begin:
          0.55,
      end:
          1.0,
    ).animate(
      CurvedAnimation(
        parent:
            _controller,
        curve:
            Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return FadeTransition(
      opacity:
          _animation,
      child:
          Container(
        width:
            9,
        height:
            9,
        decoration:
            BoxDecoration(
          color:
              widget.color,
          shape:
              BoxShape.circle,
        ),
      ),
    );
  }
}

// ============================================================
// ANIMATED TOTAL CARD
// ============================================================

class _AnimatedTotalCard
    extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final String currencySymbol;
  final bool isRight;

  const _AnimatedTotalCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.currencySymbol,
    this.isRight = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin:
          EdgeInsets.fromLTRB(
        isRight ? 5 : 0,
        4,
        isRight ? 0 : 5,
        4,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha:
              0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              color.withValues(
            alpha:
                0.15,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:
                    34,
                height:
                    34,
                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha:
                        0.14,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  size:
                      18,
                  color:
                      color,
                ),
              ),
              const SizedBox(
                width:
                    9,
              ),
              Text(
                title,
                style:
                    TextStyle(
                  color:
                      color,
                  fontWeight:
                      FontWeight.w700,
                  fontSize:
                      13,
                ),
              ),
            ],
          ),
          const SizedBox(
            height:
                10,
          ),
          TweenAnimationBuilder<double>(
            tween:
                Tween<double>(
              begin:
                  0,
              end:
                  amount,
            ),
            duration:
                const Duration(
              milliseconds:
                  650,
            ),
            curve:
                Curves.easeOutCubic,
            builder:
                (
              context,
              value,
              child,
            ) {
              return Text(
                '$currencySymbol'
                '${value.toStringAsFixed(2)}',
                style:
                    const TextStyle(
                  fontSize:
                      21,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      -0.3,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SPENDING INSIGHT
// ============================================================

class _SpendingInsightCard
    extends StatefulWidget {
  final List<Subscription>
      subscriptions;

  final Map<String, double>
      convertedMonthlyPrices;

  final String currencySymbol;

  const _SpendingInsightCard({
    required this.subscriptions,
    required this.convertedMonthlyPrices,
    required this.currencySymbol,
  });

  @override
  State<_SpendingInsightCard> createState() =>
      _SpendingInsightCardState();
}

class _SpendingInsightCardState
    extends State<_SpendingInsightCard> {
  bool _expanded = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    if (widget.subscriptions.isEmpty) {
      return _InsightContainer(
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const _InsightHeader(
              title:
                  'Spending insight',
            ),
            const SizedBox(
              height:
                  12,
            ),
            Row(
              children: [
                _InsightIcon(
                  icon:
                      Icons.insights_rounded,
                  color:
                      colorScheme.primary,
                ),
                const SizedBox(
                  width:
                      12,
                ),
                Expanded(
                  child:
                      Text(
                    'Add a subscription to see where your money goes.',
                    style:
                        TextStyle(
                      fontSize:
                          14,
                      height:
                          1.35,
                      color:
                          colorScheme
                              .onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final categoryTotals =
        <String, double>{};

    for (final subscription
        in widget.subscriptions) {
      final category =
          subscription.category
                  .trim()
                  .isEmpty
              ? 'Other'
              : subscription.category;

      final amount =
          widget.convertedMonthlyPrices[
                  subscription.id] ??
              0;

      categoryTotals[category] =
          (categoryTotals[category] ??
                  0) +
              amount;
    }

    final sortedCategories =
        categoryTotals.entries.toList()
          ..sort(
            (a, b) =>
                b.value.compareTo(
              a.value,
            ),
          );

    final visibleCategories =
        _expanded
            ? sortedCategories
            : sortedCategories.take(3).toList();

    final total =
        monthlyTotalFromMap(
      widget.convertedMonthlyPrices,
    );

    final hasMore =
        sortedCategories.length > 3;

    return _InsightContainer(
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const _InsightHeader(
            title:
                'Spending insight',
          ),
          const SizedBox(
            height:
                6,
          ),
          const Text(
            'Where your money goes',
            style:
                TextStyle(
              fontSize:
                  18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height:
                6,
          ),
          Text(
            total > 0
                ? '${widget.currencySymbol}'
                    '${total.toStringAsFixed(2)} per month'
                : 'Your monthly spending',
            style:
                TextStyle(
              fontSize:
                  12,
              color:
                  colorScheme
                      .onSurfaceVariant,
            ),
          ),
          const SizedBox(
            height:
                14,
          ),

          // ==================================================
          // CATEGORY LIST
          // ==================================================

          AnimatedSize(
            duration:
                const Duration(
              milliseconds:
                  280,
            ),
            curve:
                Curves.easeInOut,
            alignment:
                Alignment.topCenter,
            child:
                Column(
              children: [
                ...List.generate(
                  visibleCategories.length,
                  (index) {
                    final entry =
                        visibleCategories[index];

                    return Padding(
                      padding:
                          EdgeInsets.only(
                        bottom:
                            index ==
                                    visibleCategories
                                            .length -
                                        1
                                ? 0
                                : 11,
                      ),
                      child:
                          _InsightCategoryRow(
                        category:
                            entry.key,
                        amount:
                            entry.value,
                        total:
                            total,
                        currencySymbol:
                            widget.currencySymbol,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ==================================================
          // EXPAND / COLLAPSE
          // ==================================================

          if (hasMore) ...[
            const SizedBox(
              height:
                  13,
            ),
            Material(
              color:
                  Colors.transparent,
              child:
                  InkWell(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                onTap:
                    () {
                  setState(
                    () {
                      _expanded =
                          !_expanded;
                    },
                  );
                },
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical:
                        6,
                    horizontal:
                        4,
                  ),
                  child:
                      Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Text(
                        _expanded
                            ? 'Show less'
                            : '+${sortedCategories.length - 3} more '
                                '${sortedCategories.length - 3 == 1 ? 'category' : 'categories'}',
                        style:
                            TextStyle(
                          fontSize:
                              12,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              colorScheme
                                  .primary,
                        ),
                      ),
                      const SizedBox(
                        width:
                            4,
                      ),
                      AnimatedRotation(
                        duration:
                            const Duration(
                          milliseconds:
                              220,
                        ),
                        turns:
                            _expanded
                                ? 0.5
                                : 0,
                        child:
                            Icon(
                          Icons
                              .keyboard_arrow_down_rounded,
                          size:
                              19,
                          color:
                              colorScheme
                                  .primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

double monthlyTotalFromMap(
  Map<String, double> values,
) {
  double total = 0;

  for (final value in values.values) {
    total += value;
  }

  return total;
}

// ============================================================
// INSIGHT CONTAINER
// ============================================================

class _InsightContainer
    extends StatelessWidget {
  final Widget child;

  const _InsightContainer({
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final color =
        colorScheme.primary;

    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds:
            300,
      ),
      padding:
          const EdgeInsets.all(17),
      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            color.withValues(
              alpha:
                  0.11,
            ),
            colorScheme
                .surfaceContainerHighest
                .withValues(
              alpha:
                  0.60,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              color.withValues(
            alpha:
                0.10,
          ),
        ),
      ),
      child:
          child,
    );
  }
}

// ============================================================
// INSIGHT HEADER
// ============================================================

class _InsightHeader
    extends StatelessWidget {
  final String title;

  const _InsightHeader({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width:
              31,
          height:
              31,
          decoration:
              BoxDecoration(
            color:
                colorScheme
                    .primary
                    .withValues(
              alpha:
                  0.10,
            ),
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),
          child:
              Icon(
            Icons.insights_rounded,
            size:
                17,
            color:
                colorScheme
                    .primary,
          ),
        ),
        const SizedBox(
          width:
              9,
        ),
        Text(
          title,
          style:
              TextStyle(
            fontSize:
                12,
            fontWeight:
                FontWeight.w800,
            color:
                colorScheme
                    .onSurfaceVariant,
            letterSpacing:
                0.2,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// INSIGHT ICON
// ============================================================

class _InsightIcon
    extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _InsightIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          42,
      height:
          42,
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha:
              0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          13,
        ),
      ),
      child:
          Icon(
        icon,
        size:
            21,
        color:
            color,
      ),
    );
  }
}

// ============================================================
// INSIGHT CATEGORY ROW
// ============================================================

class _InsightCategoryRow
    extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  final String currencySymbol;

  const _InsightCategoryRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.currencySymbol,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final percentage =
        total <= 0
            ? 0.0
            : (amount / total).clamp(
                0.0,
                1.0,
              );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child:
                  Text(
                category,
                maxLines:
                    1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize:
                      13,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),

            // Animated category amount
            TweenAnimationBuilder<double>(
              tween:
                  Tween<double>(
                begin:
                    0,
                end:
                    amount,
              ),
              duration:
                  const Duration(
                milliseconds:
                    650,
              ),
              curve:
                  Curves.easeOutCubic,
              builder:
                  (
                context,
                value,
                child,
              ) {
                return Text(
                  '$currencySymbol'
                  '${value.toStringAsFixed(2)}',
                  style:
                      TextStyle(
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        colorScheme
                            .onSurface,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(
          height:
              6,
        ),

        // Animated category progress bar
        ClipRRect(
          borderRadius:
              BorderRadius.circular(
            99,
          ),
          child:
              TweenAnimationBuilder<double>(
            tween:
                Tween<double>(
              begin:
                  0,
              end:
                  percentage,
            ),
            duration:
                const Duration(
              milliseconds:
                  650,
            ),
            curve:
                Curves.easeOutCubic,
            builder:
                (
              context,
              value,
              child,
            ) {
              return LinearProgressIndicator(
                value:
                    value,
                minHeight:
                    6,
                backgroundColor:
                    colorScheme
                        .onSurface
                        .withValues(
                  alpha:
                      0.07,
                ),
                color:
                    colorScheme.primary,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ANIMATED SUBSCRIPTION CARD
// ============================================================

class _AnimatedSubscriptionCard
    extends StatelessWidget {
  final Subscription subscription;
  final ServiceStyle service;
  final ColorScheme colorScheme;
  final double? displayedPrice;
  final String currencySymbol;
  final String renewalText;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;
  final Duration animationDelay;

  const _AnimatedSubscriptionCard({
    super.key,
    required this.subscription,
    required this.service,
    required this.colorScheme,
    required this.displayedPrice,
    required this.currencySymbol,
    required this.renewalText,
    required this.onTap,
    required this.onDelete,
    required this.animationDelay,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return TweenAnimationBuilder<double>(
      tween:
          Tween<double>(
        begin:
            0.94,
        end:
            1.0,
      ),
      duration:
          Duration(
        milliseconds:
            350 +
                animationDelay
                    .inMilliseconds,
      ),
      curve:
          Curves.easeOutCubic,
      builder:
          (
        context,
        value,
        child,
      ) {
        return Opacity(
          opacity:
              value,
          child:
              Transform.scale(
            scale:
                value,
            alignment:
                Alignment.topCenter,
            child:
                child,
          ),
        );
      },
      child:
          Card(
        elevation:
            0,
        margin:
            const EdgeInsets.only(
          bottom:
              9,
        ),
        color:
            colorScheme
                .surfaceContainerHighest
                .withValues(
          alpha:
              0.48,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          side:
              BorderSide(
            color:
                service.color
                    .withValues(
              alpha:
                  0.14,
            ),
          ),
        ),
        child:
            Material(
          color:
              Colors.transparent,
          child:
              InkWell(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            onTap:
                onTap,
            child:
                Padding(
              padding:
                  const EdgeInsets.all(
                13,
              ),
              child:
                  Row(
                children: [
                  Container(
                    width:
                        56,
                    height:
                        56,
                    decoration:
                        BoxDecoration(
                      color:
                          service
                              .backgroundColor,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child:
                        Icon(
                      service.icon,
                      size:
                          29,
                      color:
                          service.color,
                    ),
                  ),
                  const SizedBox(
                    width:
                        14,
                  ),
                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          subscription.name,
                          maxLines:
                              1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize:
                                17,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height:
                              4,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons
                                  .event_rounded,
                              size:
                                  14,
                              color:
                                  service
                                      .color,
                            ),
                            const SizedBox(
                              width:
                                  4,
                            ),
                            Flexible(
                              child:
                                  Text(
                                renewalText,
                                maxLines:
                                    1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    TextStyle(
                                  color:
                                      service
                                          .color,
                                  fontSize:
                                      12,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subscription
                            .category
                            .isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top:
                                  4,
                            ),
                            child:
                                Text(
                                  subscription
                                      .category,
                                  style:
                                      TextStyle(
                                    color:
                                        colorScheme
                                            .onSurfaceVariant,
                                    fontSize:
                                        11,
                                  ),
                                ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      AnimatedSwitcher(
                        duration:
                            const Duration(
                          milliseconds:
                              220,
                        ),
                        child:
                            Text(
                          displayedPrice ==
                                  null
                              ? '—'
                              : '$currencySymbol'
                                  '${displayedPrice!.toStringAsFixed(2)}',
                          key:
                              ValueKey(
                            displayedPrice,
                          ),
                          style:
                              TextStyle(
                            color:
                                service.color,
                            fontSize:
                                17,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height:
                            3,
                      ),
                      Text(
                        subscription.cycle,
                        style:
                            TextStyle(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                          fontSize:
                              11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width:
                        2,
                  ),
                  IconButton(
                    tooltip:
                        'Delete',
                    icon:
                        const Icon(
                      Icons
                          .delete_outline_rounded,
                      color:
                          Colors.red,
                    ),
                    onPressed:
                        () async {
                      await onDelete();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptySubscriptionsCard
    extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptySubscriptionsCard({
    required this.onAdd,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        22,
      ),
      decoration:
          BoxDecoration(
        color: colorScheme
            .surfaceContainerHighest
            .withValues(
          alpha:
              0.52,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              colorScheme.outline
                  .withValues(
            alpha:
                0.07,
          ),
        ),
      ),
      child:
          Column(
        children: [
          Container(
            width:
                72,
            height:
                72,
            decoration:
                BoxDecoration(
              color:
                  colorScheme.primary
                      .withValues(
                alpha:
                    0.10,
              ),
              shape:
                  BoxShape.circle,
            ),
            child:
                Icon(
              Icons
                  .subscriptions_rounded,
              size:
                  34,
              color:
                  colorScheme.primary,
            ),
          ),
          const SizedBox(
            height:
                14,
          ),
          const Text(
            'Nothing here yet',
            style:
                TextStyle(
              fontSize:
                  19,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height:
                5,
          ),
          Text(
            'Add your first subscription and CancelBuddy will keep an eye on your renewals.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize:
                  13,
              height:
                  1.35,
              color:
                  colorScheme
                      .onSurfaceVariant,
            ),
          ),
          const SizedBox(
            height:
                16,
          ),
          FilledButton.icon(
            onPressed:
                onAdd,
            icon:
                const Icon(
              Icons.add_rounded,
            ),
            label:
                const Text(
              'Add subscription',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS SCREEN
// ============================================================

class SettingsScreen
    extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  late String currency;
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();

    currency =
        AppSettings.currency;

    isDarkMode =
        widget.isDarkMode;
  }

  Future<void> _changeCurrency(
    String? value,
  ) async {
    if (value == null) {
      return;
    }

    setState(() {
      currency =
          value;
    });

    await AppSettings.box.put(
      AppSettings.currencyKey,
      value,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar:
          AppBar(
        title:
            const Text(
          'Settings',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body:
          SafeArea(
        child:
            ListView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            32,
          ),
          children: [
            const Text(
              'Preferences',
              style:
                  TextStyle(
                fontSize:
                    30,
                fontWeight:
                    FontWeight.w900,
                letterSpacing:
                    -0.7,
              ),
            ),
            const SizedBox(
              height:
                  6,
            ),
            Text(
              'Control how CancelBuddy looks and displays your spending.',
              style:
                  TextStyle(
                fontSize:
                    15,
                color:
                    colorScheme
                        .onSurfaceVariant,
              ),
            ),
            const SizedBox(
              height:
                  28,
            ),
            _sectionTitle(
              context,
              'Currency',
              Icons.currency_exchange_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _SettingsCard(
              child:
                  ListTile(
                contentPadding:
                    EdgeInsets.zero,
                leading:
                    Container(
                  width:
                      44,
                  height:
                      44,
                  decoration:
                      BoxDecoration(
                    color:
                        colorScheme
                            .primary
                            .withValues(
                      alpha:
                          0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child:
                      Icon(
                    Icons
                        .currency_exchange_rounded,
                    color:
                        colorScheme
                            .primary,
                  ),
                ),
                title:
                    const Text(
                  'Dashboard currency',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                subtitle:
                    const Text(
                  'Used for your spending totals.',
                ),
                trailing:
                    DropdownButton<String>(
                  value:
                      currency,
                  underline:
                      const SizedBox(),
                  items:
                      const [
                    DropdownMenuItem(
                      value:
                          'GBP',
                      child:
                          Text(
                        'GBP (£)',
                      ),
                    ),
                    DropdownMenuItem(
                      value:
                          'USD',
                      child:
                          Text(
                        'USD (\$)',
                      ),
                    ),
                    DropdownMenuItem(
                      value:
                          'EUR',
                      child:
                          Text(
                        'EUR (€)',
                      ),
                    ),
                  ],
                  onChanged:
                      _changeCurrency,
                ),
              ),
            ),
            const SizedBox(
              height:
                  28,
            ),
            _sectionTitle(
              context,
              'Appearance',
              Icons.palette_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _SettingsCard(
              child:
                  SwitchListTile.adaptive(
                contentPadding:
                    EdgeInsets.zero,
                secondary:
                    Container(
                  width:
                      44,
                  height:
                      44,
                  decoration:
                      BoxDecoration(
                    color:
                        colorScheme
                            .primary
                            .withValues(
                      alpha:
                          0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child:
                      Icon(
                    isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color:
                        colorScheme
                            .primary,
                  ),
                ),
                title:
                    const Text(
                  'Dark mode',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                subtitle:
                    Text(
                  isDarkMode
                      ? 'Dark appearance is enabled.'
                      : 'Light appearance is enabled.',
                ),
                value:
                    isDarkMode,
                onChanged:
                    (_) {
                  widget
                      .onThemeToggle();

                  setState(() {
                    isDarkMode =
                        !isDarkMode;
                  });
                },
              ),
            ),
            const SizedBox(
              height:
                  28,
            ),
            _sectionTitle(
              context,
              'About',
              Icons.info_outline_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _SettingsCard(
              child:
                  ListTile(
                contentPadding:
                    EdgeInsets.zero,
                leading:
                    Container(
                  width:
                      44,
                  height:
                      44,
                  decoration:
                      BoxDecoration(
                    color:
                        colorScheme
                            .primary
                            .withValues(
                      alpha:
                          0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child:
                      Icon(
                    Icons
                        .account_balance_wallet_rounded,
                    color:
                        colorScheme
                            .primary,
                  ),
                ),
                title:
                    const Text(
                  'CancelBuddy',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                subtitle:
                    const Text(
                  'Subscription tracking made simple.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADD SUBSCRIPTION SCREEN
// ============================================================

class AddSubscriptionScreen
    extends StatefulWidget {
  final String? prefillName;
  final String? prefillPrice;
  final String? prefillCycle;
  final String? prefillCategory;

  const AddSubscriptionScreen({
    super.key,
    this.prefillName,
    this.prefillPrice,
    this.prefillCycle,
    this.prefillCategory,
  });

  @override
  State<AddSubscriptionScreen>
      createState() =>
          _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState
    extends State<AddSubscriptionScreen> {
  late final TextEditingController
      nameController;

  late final TextEditingController
      priceController;

  late final TextEditingController
      notesController;

  late final TextEditingController
      cancellationUrlController;

  String cycle =
      'Monthly';

  String currency =
      AppSettings.currency;

  String priceCurrency =
      AppSettings.currency;

  String category =
      'Other';

  DateTime? date;

  bool notificationsEnabled =
      true;

  bool isCurrencyConverting =
      false;

  int reminderDays =
      AppSettings.defaultReminderDays;

  TimeOfDay reminderTime =
      TimeOfDay(
    hour:
        AppSettings.defaultReminderMinutes ~/
            60,
    minute:
        AppSettings.defaultReminderMinutes %
            60,
  );

  static const categories = [
    'Entertainment',
    'Music',
    'AI',
    'Software',
    'Cloud',
    'Gaming',
    'Fitness',
    'News & Reading',
    'Bills',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    cycle =
        widget.prefillCycle ??
            'Monthly';

    // FIX:
    // Predefined cloud subscriptions use
    // "Cloud Storage", while the dropdown
    // uses "Cloud".
    category =
        normalizeSubscriptionCategory(
      widget.prefillCategory ??
          'Other',
    );

    currency =
        AppSettings.currency;

    final hasPrefilledPrice =
        widget.prefillPrice != null &&
            widget.prefillPrice!
                .trim()
                .isNotEmpty;

    priceCurrency =
        hasPrefilledPrice
            ? 'GBP'
            : currency;

    nameController =
        TextEditingController(
      text:
          widget.prefillName ??
              '',
    );

    priceController =
        TextEditingController(
      text:
          cleanPrice(
        widget.prefillPrice ??
            '',
      ),
    );

    notesController =
        TextEditingController();

    cancellationUrlController =
        TextEditingController();

    final minutes =
        AppSettings.defaultReminderMinutes;

    reminderTime =
        TimeOfDay(
      hour:
          minutes ~/ 60,
      minute:
          minutes % 60,
    );

    if (hasPrefilledPrice &&
        priceCurrency !=
            currency) {
      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          _convertInitialPrice();
        },
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    notesController.dispose();
    cancellationUrlController
        .dispose();

    super.dispose();
  }

  // ==========================================================
  // DATE / TIME
  // ==========================================================

  Future<void> _pickDate() async {
    final selected =
        await showDatePicker(
      context:
          context,
      initialDate:
          date ??
              DateTime.now(),
      firstDate:
          DateTime(2000),
      lastDate:
          DateTime(2100),
      builder:
          (
        context,
        child,
      ) {
        return Theme(
          data:
              Theme.of(context).copyWith(
            datePickerTheme:
                DatePickerThemeData(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
            ),
          ),
          child:
              child!,
        );
      },
    );

    if (selected != null &&
        mounted) {
      setState(() {
        date =
            selected;
      });
    }
  }

  Future<void>
      _pickReminderTime() async {
    final selected =
        await showTimePicker(
      context:
          context,
      initialTime:
          reminderTime,
    );

    if (selected != null &&
        mounted) {
      setState(() {
        reminderTime =
            selected;
      });
    }
  }

  // ==========================================================
  // CURRENCY
  // ==========================================================

  Future<void>
      _convertInitialPrice() async {
    final amount =
        parseNumericPrice(
      priceController.text,
    );

    if (amount == null ||
        priceCurrency ==
            currency) {
      return;
    }

    final sourceCurrency =
        priceCurrency;

    final targetCurrency =
        currency;

    setState(() {
      isCurrencyConverting =
          true;
    });

    try {
      final converted =
          await CurrencyUtils
              .convertAmount(
        amount,
        sourceCurrency,
        targetCurrency,
      );

      if (!mounted) return;

      setState(() {
        priceController.text =
            converted
                .toStringAsFixed(
          2,
        );

        priceController
                .selection =
            TextSelection.collapsed(
          offset:
              priceController
                  .text
                  .length,
        );

        priceCurrency =
            targetCurrency;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        currency =
            sourceCurrency;

        priceCurrency =
            sourceCurrency;
      });

      _showError(
        'Could not convert the price. Please check your internet connection.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isCurrencyConverting =
              false;
        });
      }
    }
  }

  Future<void>
      _changeCurrency(
    String value,
  ) async {
    if (value ==
            currency ||
        isCurrencyConverting) {
      return;
    }

    final amount =
        parseNumericPrice(
      priceController.text,
    );

    if (amount == null) {
      setState(() {
        currency =
            value;

        priceCurrency =
            value;
      });

      return;
    }

    final sourceCurrency =
        priceCurrency;

    final targetCurrency =
        value;

    setState(() {
      isCurrencyConverting =
          true;
    });

    try {
      final converted =
          await CurrencyUtils
              .convertAmount(
        amount,
        sourceCurrency,
        targetCurrency,
      );

      if (!mounted) return;

      setState(() {
        priceController.text =
            converted
                .toStringAsFixed(
          2,
        );

        priceController
                .selection =
            TextSelection.collapsed(
          offset:
              priceController
                  .text
                  .length,
        );

        currency =
            targetCurrency;

        priceCurrency =
            targetCurrency;
      });
    } catch (_) {
      if (!mounted) return;

      _showError(
        'Could not convert the price. Please check your internet connection.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isCurrencyConverting =
              false;
        });
      }
    }
  }

  // ==========================================================
  // BILLING CYCLE
  // ==========================================================

  void _changeBillingCycle(
    String value,
  ) {
    if (value ==
        cycle) {
      return;
    }

    final currentPrice =
        parseNumericPrice(
      priceController.text,
    );

    setState(() {
      if (currentPrice !=
          null) {
        final converted =
            convertCyclePrice(
          currentPrice,
          cycle,
          value,
        );

        priceController.text =
            converted
                .toStringAsFixed(
          2,
        );

        priceController
                .selection =
            TextSelection.collapsed(
          offset:
              priceController
                  .text
                  .length,
        );
      }

      cycle =
          value;
    });
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  void _save() {
    final name =
        nameController.text.trim();

    final price =
        cleanPrice(
      priceController.text,
    );

    if (name.isEmpty) {
      _showError(
        'Please enter a subscription name.',
      );
      return;
    }

    if (price.isEmpty) {
      _showError(
        'Please enter a price.',
      );
      return;
    }

    final cleanedPrice =
        price
            .replaceAll(
              ',',
              '',
            )
            .replaceAll(
              RegExp(
                r'[^0-9.]',
              ),
              '',
            );

    if (double.tryParse(
          cleanedPrice,
        ) ==
        null) {
      _showError(
        'Please enter a valid price.',
      );
      return;
    }

    if (date == null) {
      _showError(
        'Please choose a renewal date.',
      );
      return;
    }

    final reminderMinutes =
        reminderTime.hour * 60 +
            reminderTime.minute;

    Navigator.pop(
      context,
      Subscription(
        name:
            name,
        price:
            cleanedPrice,
        cycle:
            cycle,
        renewalDate:
            date!,
        currency:
            currency,
        category:
            category,
        notes:
            notesController.text.trim(),
        cancellationUrl:
            cancellationUrlController
                .text
                .trim(),
        notificationsEnabled:
            notificationsEnabled,
        reminderDays:
            reminderDays,
        reminderMinutes:
            reminderMinutes,
      ),
    );
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(
          16,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
        content:
            Text(message),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final service =
        serviceStyle(
      nameController.text,
    );

    return Scaffold(
      appBar:
          AppBar(
        title:
            const Text(
          'Add Subscription',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body:
          SafeArea(
        child:
            ListView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            32,
          ),
          children: [
            const Text(
              'Add something new',
              style:
                  TextStyle(
                fontSize:
                    30,
                fontWeight:
                    FontWeight.w900,
                letterSpacing:
                    -0.7,
              ),
            ),
            const SizedBox(
              height:
                  6,
            ),
            Text(
              'Keep your recurring payments in one place.',
              style:
                  TextStyle(
                fontSize:
                    15,
                color:
                    colorScheme
                        .onSurfaceVariant,
              ),
            ),
            const SizedBox(
              height:
                  24,
            ),
            _ServicePreview(
              name:
                  widget.prefillName ??
                      nameController
                          .text,
              service:
                  service,
              subtitle:
                  widget.prefillName ==
                          null
                      ? 'Add your details below'
                      : 'Review the details before saving',
            ),
            const SizedBox(
              height:
                  28,
            ),
            _sectionTitle(
              context,
              'Subscription details',
              Icons.receipt_long_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            TextField(
              controller:
                  nameController,
              textCapitalization:
                  TextCapitalization.words,
              onChanged:
                  (_) {
                setState(
                  () {},
                );
              },
              decoration:
                  const InputDecoration(
                labelText:
                    'Subscription name',
                hintText:
                    'Netflix',
                prefixIcon:
                    Icon(
                  Icons
                      .label_outline_rounded,
                ),
              ),
            ),
            const SizedBox(
              height:
                  14,
            ),
            TextField(
              controller:
                  priceController,
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal:
                    true,
              ),
              inputFormatters: [
                TextInputFormatter
                    .withFunction(
                  (
                    oldValue,
                    newValue,
                  ) {
                    if (newValue.text
                        .isEmpty) {
                      return newValue;
                    }

                    final valid =
                        RegExp(
                      r'^\d*\.?\d{0,2}$',
                    ).hasMatch(
                      newValue.text,
                    );

                    return valid
                        ? newValue
                        : oldValue;
                  },
                ),
              ],
              decoration:
                  InputDecoration(
                labelText:
                    'Price',
                hintText:
                    '15.49',
                suffixIcon:
                    isCurrencyConverting
                        ? const Padding(
                            padding:
                                EdgeInsets.all(
                              14,
                            ),
                            child:
                                SizedBox(
                              width:
                                  18,
                              height:
                                  18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            ),
                          )
                        : null,
              ),
            ),
            const SizedBox(
              height:
                  14,
            ),
            _DropdownField<
                String>(
              label:
                  'Currency',
              value:
                  currency,
              icon:
                  Icons
                      .currency_exchange_rounded,
              items:
                  const [
                'GBP',
                'USD',
                'EUR',
              ],
              itemLabel:
                  (
                value,
              ) {
                return '$value '
                    '(${CurrencyUtils.symbolOf(value)})';
              },
              onChanged:
                  isCurrencyConverting
                      ? null
                      : (
                          value,
                        ) {
                          if (value ==
                              null) {
                            return;
                          }

                          _changeCurrency(
                            value,
                          );
                        },
            ),
            const SizedBox(
              height:
                  24,
            ),
            _sectionTitle(
              context,
              'Category',
              Icons.category_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _DropdownField<
                String>(
              label:
                  'Category',
              value:
                  category,
              icon:
                  Icons.category_outlined,
              items:
                  categories,
              onChanged:
                  (
                value,
              ) {
                if (value ==
                    null) {
                  return;
                }

                setState(
                  () {
                    category =
                        value;
                  },
                );
              },
            ),
            const SizedBox(
              height:
                  24,
            ),
            _sectionTitle(
              context,
              'Billing cycle',
              Icons.autorenew_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _BillingCycleSelector(
              value:
                  cycle,
              onChanged:
                  _changeBillingCycle,
            ),
            const SizedBox(
              height:
                  24,
            ),
            _sectionTitle(
              context,
              'Renewal date',
              Icons.event_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _DateCard(
              date:
                  date,
              onTap:
                  _pickDate,
            ),
            const SizedBox(
              height:
                  24,
            ),
            _sectionTitle(
              context,
              'Renewal reminders',
              Icons.notifications_active_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _SettingsCard(
              child:
                  Column(
                children: [
                  SwitchListTile
                      .adaptive(
                    contentPadding:
                        EdgeInsets.zero,
                    title:
                        const Text(
                      'Renewal reminders',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                    subtitle:
                        const Text(
                      'Save a reminder for this subscription.',
                    ),
                    value:
                        notificationsEnabled,
                    onChanged:
                        (
                      value,
                    ) {
                      setState(
                        () {
                          notificationsEnabled =
                              value;
                        },
                      );
                    },
                  ),
                  if (notificationsEnabled) ...[
                    const Divider(),
                    ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading:
                          const Icon(
                        Icons
                            .event_available_rounded,
                      ),
                      title:
                          const Text(
                        'Remind me',
                      ),
                      trailing:
                          DropdownButton<int>(
                        value:
                            reminderDays,
                        underline:
                            const SizedBox(),
                        items:
                            const [
                          DropdownMenuItem(
                            value:
                                1,
                            child:
                                Text(
                              '1 day before',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                3,
                            child:
                                Text(
                              '3 days before',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                7,
                            child:
                                Text(
                              '7 days before',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                14,
                            child:
                                Text(
                              '14 days before',
                            ),
                          ),
                        ],
                        onChanged:
                            (
                          value,
                        ) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(
                            () {
                              reminderDays =
                                  value;
                            },
                          );
                        },
                      ),
                    ),
                    ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading:
                          const Icon(
                        Icons.schedule_rounded,
                      ),
                      title:
                          const Text(
                        'Reminder time',
                      ),
                      subtitle:
                          const Text(
                        'The notification will use this time.',
                      ),
                      trailing:
                          TextButton(
                        onPressed:
                            _pickReminderTime,
                        child:
                            Text(
                          reminderTime.format(
                            context,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(
              height:
                  24,
            ),
            _sectionTitle(
              context,
              'Optional details',
              Icons.notes_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            TextField(
              controller:
                  notesController,
              maxLines:
                  3,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration:
                  const InputDecoration(
                labelText:
                    'Notes',
                hintText:
                    'Anything you want to remember...',
                prefixIcon:
                    Padding(
                  padding:
                      EdgeInsets.only(
                    bottom:
                        45,
                  ),
                  child:
                      Icon(
                    Icons
                        .notes_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height:
                  14,
            ),
            TextField(
              controller:
                  cancellationUrlController,
              keyboardType:
                  TextInputType.url,
              decoration:
                  const InputDecoration(
                labelText:
                    'Cancellation / management link',
                hintText:
                    'https://...',
                prefixIcon:
                    Icon(
                  Icons
                      .link_rounded,
                ),
              ),
            ),
            const SizedBox(
              height:
                  30,
            ),
            SizedBox(
              height:
                  58,
              child:
                  FilledButton(
                onPressed:
                    isCurrencyConverting
                        ? null
                        : _save,
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      colorScheme
                          .primary,
                  foregroundColor:
                      colorScheme
                          .onPrimary,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                ),
                child:
                    const Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size:
                          22,
                    ),
                    SizedBox(
                      width:
                          9,
                    ),
                    Text(
                      'Save Subscription',
                      style:
                          TextStyle(
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height:
                  12,
            ),
            Text(
              'You can edit or delete this subscription later.',
              textAlign:
                  TextAlign.center,
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
      ),
    );
  }
}

// ============================================================
// EDIT SUBSCRIPTION SCREEN
// ============================================================

class EditSubscriptionScreen
    extends StatefulWidget {
  final Subscription sub;

  const EditSubscriptionScreen({
    super.key,
    required this.sub,
  });

  @override
  State<EditSubscriptionScreen>
      createState() =>
          _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState
    extends State<EditSubscriptionScreen> {
  late final TextEditingController
      nameController;

  late final TextEditingController
      priceController;

  late final TextEditingController
      notesController;

  late final TextEditingController
      cancellationUrlController;

  late String cycle;
  late String currency;

  late String priceCurrency;

  late String category;

  late DateTime date;

  late bool notificationsEnabled;

  late int reminderDays;

  late TimeOfDay reminderTime;

  bool isCurrencyConverting =
      false;

  bool isInitialCurrencyConversion =
      false;

  static const categories = [
    'Entertainment',
    'Music',
    'AI',
    'Software',
    'Cloud',
    'Gaming',
    'Fitness',
    'News & Reading',
    'Bills',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(
      text:
          widget.sub.name,
    );

    priceController =
        TextEditingController(
      text:
          cleanPrice(
        widget.sub.price,
      ),
    );

    notesController =
        TextEditingController(
      text:
          widget.sub.notes,
    );

    cancellationUrlController =
        TextEditingController(
      text:
          widget.sub
              .cancellationUrl,
    );

    cycle =
        widget.sub.cycle;

    currency =
        AppSettings.currency;

    priceCurrency =
        widget.sub.currency;

    // FIX:
    // Older/predefined data can contain
    // "Cloud Storage". Normalize it to
    // the dropdown's "Cloud" value.
    category =
        normalizeSubscriptionCategory(
      widget.sub.category,
    );

    date =
        widget.sub.renewalDate;

    notificationsEnabled =
        widget.sub
            .notificationsEnabled;

    reminderDays =
        widget.sub.reminderDays;

    reminderTime =
        TimeOfDay(
      hour:
          widget.sub
                  .reminderMinutes ~/
              60,
      minute:
          widget.sub
                  .reminderMinutes %
              60,
    );

    if (widget.sub.currency
            .toUpperCase() !=
        AppSettings.currency
            .toUpperCase()) {
      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          _convertInitialEditPrice();
        },
      );
    } else {
      priceCurrency =
          AppSettings.currency;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    notesController.dispose();
    cancellationUrlController
        .dispose();

    super.dispose();
  }

  // ==========================================================
  // INITIAL CURRENCY CONVERSION
  // ==========================================================

  Future<void>
      _convertInitialEditPrice() async {
    final amount =
        parseNumericPrice(
      priceController.text,
    );

    if (amount == null) {
      return;
    }

    final sourceCurrency =
        widget.sub.currency
            .toUpperCase();

    final targetCurrency =
        AppSettings.currency
            .toUpperCase();

    if (sourceCurrency ==
        targetCurrency) {
      if (mounted) {
        setState(
          () {
            currency =
                targetCurrency;

            priceCurrency =
                targetCurrency;
          },
        );
      }

      return;
    }

    if (mounted) {
      setState(
        () {
          isInitialCurrencyConversion =
              true;

          isCurrencyConverting =
              true;

          currency =
              targetCurrency;
        },
      );
    }

    try {
      final converted =
          await CurrencyUtils
              .convertAmount(
        amount,
        sourceCurrency,
        targetCurrency,
      );

      if (!mounted) return;

      setState(
        () {
          priceController.text =
              converted
                  .toStringAsFixed(
            2,
          );

          priceController
                  .selection =
              TextSelection.collapsed(
            offset:
                priceController
                    .text
                    .length,
          );

          currency =
              targetCurrency;

          priceCurrency =
              targetCurrency;
        },
      );
    } catch (_) {
      if (!mounted) return;

      setState(
        () {
          currency =
              sourceCurrency;

          priceCurrency =
              sourceCurrency;
        },
      );

      _showError(
        'Could not convert the price. Please check your internet connection.',
      );
    } finally {
      if (mounted) {
        setState(
          () {
            isInitialCurrencyConversion =
                false;

            isCurrencyConverting =
                false;
          },
        );
      }
    }
  }

  // ==========================================================
  // CURRENCY CHANGE
  // ==========================================================

  Future<void>
      _changeCurrency(
    String? value,
  ) async {
    if (value == null ||
        value == currency ||
        isCurrencyConverting) {
      return;
    }

    final amount =
        parseNumericPrice(
      priceController.text,
    );

    if (amount == null) {
      setState(
        () {
          currency =
              value;

          priceCurrency =
              value;
        },
      );

      return;
    }

    final oldCurrency =
        priceCurrency;

    final newCurrency =
        value;

    setState(
      () {
        isCurrencyConverting =
            true;
      },
    );

    try {
      final converted =
          await CurrencyUtils
              .convertAmount(
        amount,
        oldCurrency,
        newCurrency,
      );

      if (!mounted) return;

      setState(
        () {
          priceController.text =
              converted
                  .toStringAsFixed(
            2,
          );

          priceController
                  .selection =
              TextSelection.collapsed(
            offset:
                priceController
                    .text
                    .length,
          );

          currency =
              newCurrency;

          priceCurrency =
              newCurrency;
        },
      );
    } catch (_) {
      if (!mounted) return;

      _showError(
        'Could not convert the price. Please check your internet connection.',
      );
    } finally {
      if (mounted) {
        setState(
          () {
            isCurrencyConverting =
                false;
          },
        );
      }
    }
  }

  // ==========================================================
  // BILLING CYCLE
  // ==========================================================

  void _changeBillingCycle(
    String value,
  ) {
    if (value ==
        cycle) {
      return;
    }

    final currentPrice =
        parseNumericPrice(
      priceController.text,
    );

    if (currentPrice ==
        null) {
      setState(
        () {
          cycle =
              value;
        },
      );

      return;
    }

    final converted =
        convertCyclePrice(
      currentPrice,
      cycle,
      value,
    );

    setState(
      () {
        priceController.text =
            converted
                .toStringAsFixed(
          2,
        );

        priceController
                .selection =
            TextSelection.collapsed(
          offset:
              priceController
                  .text
                  .length,
        );

        cycle =
            value;
      },
    );
  }

  // ==========================================================
  // DATE
  // ==========================================================

  Future<void> _pickDate() async {
    final selected =
        await showDatePicker(
      context:
          context,
      initialDate:
          date,
      firstDate:
          DateTime(2000),
      lastDate:
          DateTime(2100),
      builder:
          (
        context,
        child,
      ) {
        return Theme(
          data:
              Theme.of(context).copyWith(
            datePickerTheme:
                DatePickerThemeData(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
            ),
          ),
          child:
              child!,
        );
      },
    );

    if (selected != null &&
        mounted) {
      setState(
        () {
          date =
              selected;
        },
      );
    }
  }

  // ==========================================================
  // REMINDER TIME
  // ==========================================================

  Future<void>
      _pickReminderTime() async {
    final selected =
        await showTimePicker(
      context:
          context,
      initialTime:
          reminderTime,
    );

    if (selected != null &&
        mounted) {
      setState(
        () {
          reminderTime =
              selected;
        },
      );
    }
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  void _save() {
    final name =
        nameController.text
            .trim();

    final price =
        cleanPrice(
      priceController.text,
    );

    if (name.isEmpty) {
      _showError(
        'Please enter a subscription name.',
      );
      return;
    }

    if (price.isEmpty) {
      _showError(
        'Please enter a price.',
      );
      return;
    }

    final cleanedPrice =
        price
            .replaceAll(
              ',',
              '',
            )
            .replaceAll(
              RegExp(
                r'[^0-9.]',
              ),
              '',
            );

    final numericPrice =
        double.tryParse(
      cleanedPrice,
    );

    if (numericPrice ==
        null) {
      _showError(
        'Please enter a valid price.',
      );
      return;
    }

    final reminderMinutes =
        reminderTime.hour * 60 +
            reminderTime.minute;

    final updatedSubscription =
        Subscription(
      id:
          widget.sub.id,
      name:
          name,
      price:
          numericPrice
              .toStringAsFixed(
        2,
      ),
      cycle:
          cycle,
      renewalDate:
          date,
      currency:
          currency,
      category:
          category,
      notes:
          notesController
              .text
              .trim(),
      cancellationUrl:
          cancellationUrlController
              .text
              .trim(),
      notificationsEnabled:
          notificationsEnabled,
      reminderDays:
          reminderDays,
      reminderMinutes:
          reminderMinutes,
    );

    Navigator.pop(
      context,
      updatedSubscription,
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(
          16,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
        content:
            Text(message),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final service =
        serviceStyle(
      nameController.text,
    );

    return Scaffold(
      appBar:
          AppBar(
        title:
            const Text(
          'Edit Subscription',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body:
          SafeArea(
        child:
            ListView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            32,
          ),
          children: [
            const Text(
              'Update your payment',
              style:
                  TextStyle(
                fontSize:
                    30,
                fontWeight:
                    FontWeight.w900,
                letterSpacing:
                    -0.7,
              ),
            ),
            const SizedBox(
              height:
                  6,
            ),
            Text(
              'Change the details below and save your updates.',
              style:
                  TextStyle(
                fontSize:
                    15,
                color:
                    colorScheme
                        .onSurfaceVariant,
              ),
            ),
            const SizedBox(
              height:
                  24,
            ),
            _ServicePreview(
              name:
                  nameController
                      .text,
              service:
                  service,
              subtitle:
                  'Subscription details',
            ),
            const SizedBox(
              height:
                  28,
            ),
            _sectionTitle(
              context,
              'Subscription details',
              Icons.receipt_long_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            TextField(
              controller:
                  nameController,
              textCapitalization:
                  TextCapitalization.words,
              onChanged:
                  (_) {
                setState(
                  () {},
                );
              },
              decoration:
                  const InputDecoration(
                labelText:
                    'Subscription name',
                prefixIcon:
                    Icon(
                  Icons
                      .label_outline_rounded,
                ),
              ),
            ),
            const SizedBox(
              height:
                  14,
            ),
            TextField(
              controller:
                  priceController,
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal:
                    true,
              ),
              inputFormatters: [
                TextInputFormatter
                    .withFunction(
                  (
                    oldValue,
                    newValue,
                  ) {
                    if (newValue
                        .text
                        .isEmpty) {
                      return newValue;
                    }

                    final valid =
                        RegExp(
                      r'^\d*\.?\d{0,2}$',
                    ).hasMatch(
                      newValue.text,
                    );

                    return valid
                        ? newValue
                        : oldValue;
                  },
                ),
              ],
              decoration:
                  InputDecoration(
                labelText:
                    'Price',
                hintText:
                    '15.49',
                prefixText:
                    '${CurrencyUtils.symbolOf(currency)} ',
                suffixIcon:
                    isCurrencyConverting
                        ? const Padding(
                            padding:
                                EdgeInsets.all(
                              14,
                            ),
                            child:
                                SizedBox(
                              width:
                                  18,
                              height:
                                  18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            ),
                          )
                        : null,
              ),
            ),
            const SizedBox(
              height:
                  14,
            ),
            _DropdownField<
                String>(
              label:
                  'Currency',
              value:
                  currency,
              icon:
                  Icons
                      .currency_exchange_rounded,
              items:
                  const [
                'GBP',
                'USD',
                'EUR',
              ],
              itemLabel:
                  (
                value,
              ) {
                return '$value '
                    '(${CurrencyUtils.symbolOf(value)})';
              },
              onChanged:
                  isCurrencyConverting
                      ? null
                      : _changeCurrency,
            ),
            const SizedBox(
              height:
                  24,
            ),
            _sectionTitle(
              context,
              'Category',
              Icons.category_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _DropdownField<
                String>(
              label:
                  'Category',
              value:
                  categories
                          .contains(
                        category,
                      )
                      ? category
                      : 'Other',
              icon:
                  Icons
                      .category_outlined,
              items:
                  categories,
              onChanged:
                  (
                value,
              ) {
                if (value ==
                    null) {
                  return;
                }

                setState(
                  () {
                    category =
                        value;
                  },
                );
              },
            ),
            const SizedBox(
              height:
                  24,
            ),
            _sectionTitle(
              context,
              'Billing cycle',
              Icons.autorenew_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _BillingCycleSelector(
              value:
                  cycle,
              onChanged:
                  _changeBillingCycle,
            ),
            const SizedBox(
              height:
                  24,
            ),
            _sectionTitle(
              context,
              'Renewal date',
              Icons.event_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _DateCard(
              date:
                  date,
              onTap:
                  _pickDate,
            ),
            const SizedBox(
              height:
                  24,
            ),
            _sectionTitle(
              context,
              'Renewal reminders',
              Icons
                  .notifications_active_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            _SettingsCard(
              child:
                  Column(
                children: [
                  SwitchListTile
                      .adaptive(
                    contentPadding:
                        EdgeInsets.zero,
                    title:
                        const Text(
                      'Renewal reminders',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                    subtitle:
                        const Text(
                      'Save a reminder for this subscription.',
                    ),
                    value:
                        notificationsEnabled,
                    onChanged:
                        (
                      value,
                    ) {
                      setState(
                        () {
                          notificationsEnabled =
                              value;
                        },
                      );
                    },
                  ),
                  if (notificationsEnabled) ...[
                    const Divider(),
                    ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading:
                          const Icon(
                        Icons
                            .event_available_rounded,
                      ),
                      title:
                          const Text(
                        'Remind me',
                      ),
                      trailing:
                          DropdownButton<int>(
                        value:
                            reminderDays,
                        underline:
                            const SizedBox(),
                        items:
                            const [
                          DropdownMenuItem(
                            value:
                                1,
                            child:
                                Text(
                              '1 day before',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                3,
                            child:
                                Text(
                              '3 days before',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                7,
                            child:
                                Text(
                              '7 days before',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                14,
                            child:
                                Text(
                              '14 days before',
                            ),
                          ),
                        ],
                        onChanged:
                            (
                          value,
                        ) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(
                            () {
                              reminderDays =
                                  value;
                            },
                          );
                        },
                      ),
                    ),
                    ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading:
                          const Icon(
                        Icons
                            .schedule_rounded,
                      ),
                      title:
                          const Text(
                        'Reminder time',
                      ),
                      trailing:
                          TextButton(
                        onPressed:
                            _pickReminderTime,
                        child:
                            Text(
                          reminderTime
                              .format(
                            context,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(
              height:
                  24,
            ),
            _sectionTitle(
              context,
              'Optional details',
              Icons.notes_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            TextField(
              controller:
                  notesController,
              maxLines:
                  3,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration:
                  const InputDecoration(
                labelText:
                    'Notes',
                hintText:
                    'Anything you want to remember...',
                prefixIcon:
                    Padding(
                  padding:
                      EdgeInsets.only(
                    bottom:
                        45,
                  ),
                  child:
                      Icon(
                    Icons
                        .notes_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height:
                  14,
            ),
            TextField(
              controller:
                  cancellationUrlController,
              keyboardType:
                  TextInputType.url,
              decoration:
                  const InputDecoration(
                labelText:
                    'Cancellation / management link',
                hintText:
                    'https://...',
                prefixIcon:
                    Icon(
                  Icons
                      .link_rounded,
                ),
              ),
            ),
            const SizedBox(
              height:
                  30,
            ),
            SizedBox(
              height:
                  58,
              child:
                  FilledButton(
                onPressed:
                    isCurrencyConverting ||
                            isInitialCurrencyConversion
                        ? null
                        : _save,
                style:
                    FilledButton
                        .styleFrom(
                  backgroundColor:
                      colorScheme
                          .primary,
                  foregroundColor:
                      colorScheme
                          .onPrimary,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                ),
                child:
                    const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.save_rounded,
                      size:
                          22,
                    ),
                    SizedBox(
                      width:
                          9,
                    ),
                    Text(
                      'Save Changes',
                      style:
                          TextStyle(
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SERVICE PREVIEW
// ============================================================

class _ServicePreview
    extends StatelessWidget {
  final String name;
  final ServiceStyle service;
  final String subtitle;

  const _ServicePreview({
    required this.name,
    required this.service,
    required this.subtitle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            service.color.withValues(
              alpha:
                  0.16,
            ),
            service.color.withValues(
              alpha:
                  0.05,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
        border:
            Border.all(
          color:
              service.color.withValues(
            alpha:
                0.14,
          ),
        ),
      ),
      child:
          Row(
        children: [
          Container(
            width:
                64,
            height:
                64,
            decoration:
                BoxDecoration(
              color:
                  service.backgroundColor,
              borderRadius:
                  BorderRadius.circular(
                19,
              ),
            ),
            child:
                Icon(
              service.icon,
              size:
                  32,
              color:
                  service.color,
            ),
          ),
          const SizedBox(
            width:
                15,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  name.isEmpty
                      ? 'Your subscription'
                      : name,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height:
                      4,
                ),
                Text(
                  subtitle,
                  style:
                      TextStyle(
                    color:
                        colorScheme
                            .onSurfaceVariant,
                    fontSize:
                        13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BILLING CYCLE SELECTOR
// ============================================================

class _BillingCycleSelector
    extends StatelessWidget {
  final String value;
  final ValueChanged<String>
      onChanged;

  const _BillingCycleSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    const options = [
      'Weekly',
      'Monthly',
      'Yearly',
    ];

    return Container(
      padding:
          const EdgeInsets.all(
        5,
      ),
      decoration:
          BoxDecoration(
        color:
            colorScheme
                .surfaceContainerHighest
                .withValues(
          alpha:
              0.65,
        ),
        borderRadius:
            BorderRadius.circular(
          17,
        ),
      ),
      child:
          Row(
        children:
            options.map(
          (option) {
            final selected =
                value ==
                    option;

            return Expanded(
              child:
                  GestureDetector(
                onTap:
                    () {
                  onChanged(
                    option,
                  );
                },
                child:
                    AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds:
                        180,
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical:
                        13,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        selected
                            ? colorScheme
                                .primary
                            : Colors
                                .transparent,
                    borderRadius:
                        BorderRadius
                            .circular(
                      13,
                    ),
                  ),
                  child:
                      Text(
                    option,
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      fontSize:
                          13,
                      color:
                          selected
                              ? colorScheme
                                  .onPrimary
                              : colorScheme
                                  .onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}

// ============================================================
// DATE CARD
// ============================================================

class _DateCard
    extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DateCard({
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final hasDate =
        date != null;

    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child:
            Ink(
          padding:
              const EdgeInsets.all(
            16,
          ),
          decoration:
              BoxDecoration(
            color:
                colorScheme
                    .surfaceContainerHighest
                    .withValues(
              alpha:
                  0.62,
            ),
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border:
                Border.all(
              color:
                  colorScheme
                      .outline
                      .withValues(
                alpha:
                    0.08,
              ),
            ),
          ),
          child:
              Row(
            children: [
              Container(
                width:
                    50,
                height:
                    50,
                decoration:
                    BoxDecoration(
                  color:
                      colorScheme
                          .primary
                          .withValues(
                    alpha:
                        0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child:
                    Icon(
                  Icons
                      .calendar_month_rounded,
                  color:
                      colorScheme.primary,
                ),
              ),
              const SizedBox(
                width:
                    14,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      hasDate
                          ? formatLongDate(
                              date!,
                            )
                          : 'Choose renewal date',
                      style:
                          const TextStyle(
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height:
                          3,
                    ),
                    Text(
                      hasDate
                          ? 'Your next payment date'
                          : 'When will you be charged?',
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
              ),
              Container(
                padding:
                    const EdgeInsets.all(
                  8,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      colorScheme.surface,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DROPDOWN FIELD
// ============================================================

class _DropdownField<T>
    extends StatelessWidget {
  final String label;
  final T value;
  final IconData icon;
  final List<T> items;
  final String Function(T)?
      itemLabel;

  final ValueChanged<T?>?
      onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return DropdownButtonFormField<T>(
      initialValue:
          value,
      decoration:
          InputDecoration(
        labelText:
            label,
        prefixIcon:
            Icon(icon),
      ),
      items:
          items.map(
        (item) {
          return DropdownMenuItem<T>(
            value:
                item,
            child:
                Text(
              itemLabel !=
                      null
                  ? itemLabel!(
                      item,
                    )
                  : item.toString(),
            ),
          );
        },
      ).toList(),
      onChanged:
          onChanged,
    );
  }
}

// ============================================================
// SETTINGS CARD
// ============================================================

class _SettingsCard
    extends StatelessWidget {
  final Widget child;

  const _SettingsCard({
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            16,
        vertical:
            6,
      ),
      decoration:
          BoxDecoration(
        color:
            colorScheme
                .surfaceContainerHighest
                .withValues(
          alpha:
              0.62,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              colorScheme
                  .outline
                  .withValues(
            alpha:
                0.08,
          ),
        ),
      ),
      child:
          child,
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

Widget _sectionTitle(
  BuildContext context,
  String title,
  IconData icon,
) {
  final colorScheme =
      Theme.of(context).colorScheme;

  return Row(
    children: [
      Container(
        width:
            32,
        height:
            32,
        decoration:
            BoxDecoration(
          color:
              colorScheme
                  .primary
                  .withValues(
            alpha:
                0.10,
          ),
          borderRadius:
              BorderRadius.circular(
            9,
          ),
        ),
        child:
            Icon(
          icon,
          size:
              17,
          color:
              colorScheme.primary,
        ),
      ),
      const SizedBox(
        width:
            9,
      ),
      Text(
        title,
        style:
            const TextStyle(
          fontSize:
              15,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    ],
  );
}

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