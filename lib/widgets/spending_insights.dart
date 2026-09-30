
import 'package:flutter/material.dart';

import 'package:cancelbuddy/subscription.dart';

// ============================================================
// SPENDING INSIGHT
// ============================================================

class SpendingInsightCard
    extends StatefulWidget {
  final List<Subscription>
      subscriptions;

  final Map<String, double>
      convertedMonthlyPrices;

  final String currencySymbol;

  const SpendingInsightCard({
    super.key,
    required this.subscriptions,
    required this.convertedMonthlyPrices,
    required this.currencySymbol,
  });

  @override
  State<SpendingInsightCard> createState() =>
      _SpendingInsightCardState();
}

class _SpendingInsightCardState
    extends State<SpendingInsightCard> {
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
