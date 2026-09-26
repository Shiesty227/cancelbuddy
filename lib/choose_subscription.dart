import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'currency_utils.dart';
import 'predefined.dart';
import 'service_icons.dart';

class ChooseSubscriptionScreen
    extends StatefulWidget {
  final Future<void> Function(
    PredefinedSub subscription,
  ) onSubscriptionSelected;

  const ChooseSubscriptionScreen({
    super.key,
    required this.onSubscriptionSelected,
  });

  @override
  State<ChooseSubscriptionScreen>
      createState() =>
          _ChooseSubscriptionScreenState();
}

class _ChooseSubscriptionScreenState
    extends State<ChooseSubscriptionScreen> {
  String selectedCategory = 'All';

  final TextEditingController
      searchController =
      TextEditingController();

  String searchText = '';

  bool isLoadingPrices = true;

  String? priceError;

  String loadedCurrency = 'GBP';

  final Map<String, double>
      convertedPrices = {};

  @override
  void initState() {
    super.initState();

    loadedCurrency = selectedCurrency;

    searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        searchText =
            searchController.text
                .trim()
                .toLowerCase();
      });
    });

    _loadConvertedPrices();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // CURRENCY
  // ==========================================================

  String get selectedCurrency {
    final box =
        Hive.box('settings');

    final value = box.get(
      'currency',
      defaultValue: 'GBP',
    );

    final currency =
        value?.toString().toUpperCase();

    if (currency == 'GBP' ||
        currency == 'USD' ||
        currency == 'EUR') {
      return currency!;
    }

    return 'GBP';
  }

  String currencySymbolOf(
    String code,
  ) {
    return CurrencyUtils.symbolOf(
      code,
    );
  }

  double? _parsePrice(
    String price,
  ) {
    final cleaned = price
        .trim()
        .replaceFirst(
          RegExp(
            r'^(GBP|USD|EUR)\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^[£€\$]\s*',
          ),
          '',
        )
        .replaceAll(',', '');

    return double.tryParse(
      cleaned,
    );
  }

  Future<void> _loadConvertedPrices() async {
    final targetCurrency =
        selectedCurrency;

    if (!mounted) return;

    setState(() {
      isLoadingPrices = true;
      priceError = null;
      loadedCurrency =
          targetCurrency;
      convertedPrices.clear();
    });

    if (targetCurrency == 'GBP') {
      final values =
          <String, double>{};

      for (final subscription
          in predefinedSubs) {
        final parsed =
            _parsePrice(
          subscription.price,
        );

        if (parsed != null) {
          values[
                  subscription.name] =
              parsed;
        }
      }

      if (!mounted) return;

      setState(() {
        convertedPrices
          ..clear()
          ..addAll(values);

        isLoadingPrices = false;
      });

      return;
    }

    try {
      final rate =
          await CurrencyUtils.exchangeRate(
        'GBP',
        targetCurrency,
      );

      final values =
          <String, double>{};

      for (final subscription
          in predefinedSubs) {
        final parsed =
            _parsePrice(
          subscription.price,
        );

        if (parsed != null) {
          values[
                  subscription.name] =
              parsed * rate;
        }
      }

      if (!mounted) return;

      setState(() {
        convertedPrices
          ..clear()
          ..addAll(values);

        isLoadingPrices = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingPrices = false;
        priceError =
            'Could not update prices.';
      });
    }
  }

  String displayPrice(
    PredefinedSub subscription,
  ) {
    final converted =
        convertedPrices[
            subscription.name];

    if (converted == null) {
      return '—';
    }

    return '${currencySymbolOf(selectedCurrency)}'
        '${converted.toStringAsFixed(2)}';
  }

  // ==========================================================
  // CATEGORIES
  // ==========================================================

  List<String> get categories {
    final result =
        <String>{'All'};

    for (final subscription
        in predefinedSubs) {
      result.add(
        subscription.category,
      );
    }

    return result.toList();
  }

  // ==========================================================
  // FILTERING
  // ==========================================================

  List<PredefinedSub>
      get filteredSubscriptions {
    return predefinedSubs.where(
      (subscription) {
        final matchesCategory =
            selectedCategory ==
                    'All' ||
                subscription.category ==
                    selectedCategory;

        final matchesSearch =
            searchText.isEmpty ||
                subscription.name
                    .toLowerCase()
                    .contains(
                      searchText,
                    );

        return matchesCategory &&
            matchesSearch;
      },
    ).toList();
  }

  // ==========================================================
  // SELECT
  // ==========================================================

  Future<void> _select(
    PredefinedSub subscription,
  ) async {
    await widget.onSubscriptionSelected(
      subscription,
    );
  }

  Future<void> _manual() async {
    await widget.onSubscriptionSelected(
      const PredefinedSub(
        name: '__manual__',
        price: '',
        cycle: 'Monthly',
        category: 'Manual',
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

    final subscriptions =
        filteredSubscriptions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Subscription',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: TextField(
              controller:
                  searchController,
              decoration:
                  InputDecoration(
                hintText:
                    'Search subscriptions',
                prefixIcon:
                    const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon:
                    searchText.isEmpty
                        ? null
                        : IconButton(
                            onPressed:
                                searchController
                                    .clear,
                            icon:
                                const Icon(
                              Icons
                                  .clear_rounded,
                            ),
                          ),
                filled: true,
                fillColor: colorScheme
                    .surfaceContainerHighest
                    .withValues(
                  alpha: 0.55,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ),

          SizedBox(
            height: 48,
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  categories.length,
              separatorBuilder:
                  (_, _) =>
                      const SizedBox(
                width: 8,
              ),
              itemBuilder:
                  (_, index) {
                final category =
                    categories[index];

                final selected =
                    category ==
                        selectedCategory;

                return ChoiceChip(
                  label:
                      Text(category),
                  selected:
                      selected,
                  onSelected:
                      (_) {
                    setState(() {
                      selectedCategory =
                          category;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          if (isLoadingPrices)
            const Padding(
              padding:
                  EdgeInsets.only(
                bottom: 8,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Updating prices...',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          if (priceError != null)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                8,
              ),
              child: Text(
                priceError!,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 12,
                ),
                textAlign:
                    TextAlign.center,
              ),
            ),

          Expanded(
            child:
                subscriptions.isEmpty
                    ? Center(
                        child: Text(
                          'No subscriptions found.',
                          style: TextStyle(
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          12,
                          4,
                          12,
                          100,
                        ),
                        itemCount:
                            subscriptions.length,
                        itemBuilder:
                            (_, index) {
                          final subscription =
                              subscriptions[
                                  index];

                          final service =
                              serviceStyle(
                            subscription.name,
                          );

                          return Card(
                            elevation: 0,
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 8,
                            ),
                            color: colorScheme
                                .surfaceContainerHighest
                                .withValues(
                              alpha: 0.48,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                              side:
                                  BorderSide(
                                color: service
                                    .color
                                    .withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            child:
                                InkWell(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                              onTap: () {
                                _select(
                                  subscription,
                                );
                              },
                              child:
                                  Padding(
                                padding:
                                    const EdgeInsets
                                        .all(
                                  13,
                                ),
                                child:
                                    Row(
                                  children: [
                                    Container(
                                      width:
                                          52,
                                      height:
                                          52,
                                      decoration:
                                          BoxDecoration(
                                        color: service
                                            .backgroundColor,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          15,
                                        ),
                                      ),
                                      child:
                                          Icon(
                                        service
                                            .icon,
                                        color:
                                            service
                                                .color,
                                        size: 27,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 14,
                                    ),
                                    Expanded(
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            subscription
                                                .name,
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  16,
                                              fontWeight:
                                                  FontWeight
                                                      .w700,
                                            ),
                                          ),
                                          const SizedBox(
                                            height:
                                                3,
                                          ),
                                          Text(
                                            subscription
                                                .category,
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
                                    Text(
                                      displayPrice(
                                        subscription,
                                      ),
                                      style:
                                          TextStyle(
                                        color:
                                            service
                                                .color,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                    Icon(
                                      Icons
                                          .chevron_right_rounded,
                                      color: colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _manual,
        icon: const Icon(
          Icons.edit_rounded,
        ),
        label: const Text(
          'Enter manually',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }
}