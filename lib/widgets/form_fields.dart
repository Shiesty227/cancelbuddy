
import 'package:flutter/material.dart';

import 'package:cancelbuddy/service_icons.dart';
import 'package:cancelbuddy/utils/helpers.dart';

// ============================================================
// SERVICE PREVIEW
// ============================================================

class ServicePreview
    extends StatelessWidget {
  final String name;
  final ServiceStyle service;
  final String subtitle;

  const ServicePreview({
    super.key,
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

class BillingCycleSelector
    extends StatelessWidget {
  final String value;
  final ValueChanged<String>
      onChanged;

  const BillingCycleSelector({
    super.key,
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

class DateCard
    extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const DateCard({
    super.key,
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

class DropdownField<T>
    extends StatelessWidget {
  final String label;
  final T value;
  final IconData icon;
  final List<T> items;
  final String Function(T)?
      itemLabel;

  final ValueChanged<T?>?
      onChanged;

  const DropdownField({
    super.key,
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

class SettingsCard
    extends StatelessWidget {
  final Widget child;

  const SettingsCard({
    super.key,
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

Widget sectionTitle(
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
