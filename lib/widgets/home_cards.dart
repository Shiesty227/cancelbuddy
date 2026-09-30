import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cancelbuddy/currency_utils.dart';
import 'package:cancelbuddy/savings.dart';
import 'package:cancelbuddy/service_icons.dart';
import 'package:cancelbuddy/subscription.dart';

// ============================================================
// LIVE OVERVIEW
// ============================================================

class LiveOverviewCard
    extends StatelessWidget {
  final String message;
  final Subscription? nextRenewal;
  final String? renewalText;
  final String? dateText;
  final double? price;
  final String? cycle;
  final String currencySymbol;
  final ServiceStyle? service;

  const LiveOverviewCard({
    super.key,
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

class AnimatedTotalCard
    extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final String currencySymbol;
  final bool isRight;

  const AnimatedTotalCard({
    super.key,
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
// ANIMATED SUBSCRIPTION CARD
// ============================================================

class AnimatedSubscriptionCard
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

  const AnimatedSubscriptionCard({
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
                        const SizedBox(
                          height:
                              6,
                        ),
                        _RenewalProgressBar(
                          subscription:
                              subscription,
                          baseColor:
                              service.color,
                          colorScheme:
                              colorScheme,
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
// RENEWAL PROGRESS BAR
// ============================================================

// Fills up as the renewal date approaches. Turns
// amber in the final week and red on the last day.
class _RenewalProgressBar
    extends StatelessWidget {
  final Subscription subscription;
  final Color baseColor;
  final ColorScheme colorScheme;

  const _RenewalProgressBar({
    required this.subscription,
    required this.baseColor,
    required this.colorScheme,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final renewal = DateTime(
      subscription.renewalDate.year,
      subscription.renewalDate.month,
      subscription.renewalDate.day,
    );

    final daysLeft =
        renewal.difference(today).inDays;

    final Color color;

    if (daysLeft <= 1) {
      color = colorScheme.error;
    } else if (daysLeft <= 7) {
      color = Colors.amber.shade700;
    } else {
      color = baseColor;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: subscription
            .renewalProgress(now),
      ),
      duration: const Duration(
        milliseconds: 900,
      ),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) {
        return ClipRRect(
          borderRadius:
              BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            color: color,
            backgroundColor:
                color.withValues(
              alpha: 0.15,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// SAVINGS CARD
// ============================================================

class SavingsCard
    extends StatelessWidget {
  final double perMonth;
  final double soFar;
  final int count;
  final String currencySymbol;
  final VoidCallback onTap;

  const SavingsCard({
    super.key,
    required this.perMonth,
    required this.soFar,
    required this.count,
    required this.currencySymbol,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final accent = isDark
        ? const Color(0xFF66BB6A)
        : const Color(0xFF2E7D32);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: accent.withValues(
        alpha: isDark ? 0.14 : 0.09,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
        side: BorderSide(
          color: accent.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(
            16,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: 0.16,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  Icons.savings_rounded,
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<
                        double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: perMonth * 12,
                      ),
                      duration:
                          const Duration(
                        milliseconds: 900,
                      ),
                      curve: Curves
                          .easeOutCubic,
                      builder:
                          (_, value, _) {
                        return Text(
                          'Saving $currencySymbol'
                          '${value.toStringAsFixed(2)} a year',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .w800,
                            color: accent,
                          ),
                        );
                      },
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      '$currencySymbol'
                      '${soFar.toStringAsFixed(2)} saved so far · '
                      '$count cancelled',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
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
  }
}

// ============================================================
// CANCELLED LIST
// ============================================================

class CancelledListSheet
    extends StatefulWidget {
  final Future<void> Function(
    CancelledSubscription item,
  ) onRemove;

  const CancelledListSheet({
    super.key,
    required this.onRemove,
  });

  @override
  State<CancelledListSheet>
      createState() =>
          _CancelledListSheetState();
}

class _CancelledListSheetState
    extends State<CancelledListSheet> {
  static const months = [
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final items = SavingsStore.all;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context)
                      .size
                      .height *
                  0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                8,
              ),
              child: Text(
                'Cancelled subscriptions',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child: Text(
                  'Nothing cancelled yet.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.fromLTRB(
                    8,
                    0,
                    8,
                    16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item =
                        items[index];

                    final date =
                        item.cancelledAt;

                    return ListTile(
                      leading: Icon(
                        serviceStyle(
                          item.name,
                          item.category,
                        ).icon,
                      ),
                      title: Text(
                        item.name,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${CurrencyUtils.symbolOf(item.currency)}'
                        '${item.monthlyPrice.toStringAsFixed(2)}/month · '
                        'cancelled ${date.day} '
                        '${months[date.month - 1]} '
                        '${date.year}',
                      ),
                      trailing: IconButton(
                        tooltip:
                            'Remove from savings',
                        icon: const Icon(
                          Icons
                              .close_rounded,
                        ),
                        onPressed: () async {
                          HapticFeedback
                              .lightImpact();

                          await widget
                              .onRemove(item);

                          if (!mounted) {
                            return;
                          }

                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class EmptySubscriptionsCard
    extends StatelessWidget {
  final VoidCallback onAdd;

  const EmptySubscriptionsCard({
    super.key,
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
