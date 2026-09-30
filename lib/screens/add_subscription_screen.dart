import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cancelbuddy/app_settings.dart';
import 'package:cancelbuddy/currency_utils.dart';
import 'package:cancelbuddy/service_icons.dart';
import 'package:cancelbuddy/subscription.dart';
import 'package:cancelbuddy/utils/helpers.dart';
import 'package:cancelbuddy/widgets/form_fields.dart';

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

  // The user types the price in the currency
  // they pay in, so switching currency only
  // relabels the price instead of converting it.
  void _changeCurrency(
    String value,
  ) {
    if (value ==
            currency ||
        isCurrencyConverting) {
      return;
    }

    setState(() {
      currency =
          value;

      priceCurrency =
          value;
    });
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

    HapticFeedback.lightImpact();

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
      category,
    ).forBrightness(
      Theme.of(context).brightness,
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
            ServicePreview(
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
            sectionTitle(
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
                    'e.g. Streaming service',
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
            DropdownField<
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
            sectionTitle(
              context,
              'Category',
              Icons.category_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            DropdownField<
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
            sectionTitle(
              context,
              'Billing cycle',
              Icons.autorenew_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            BillingCycleSelector(
              value:
                  cycle,
              onChanged:
                  _changeBillingCycle,
            ),
            const SizedBox(
              height:
                  24,
            ),
            sectionTitle(
              context,
              'Renewal date',
              Icons.event_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            DateCard(
              date:
                  date,
              onTap:
                  _pickDate,
            ),
            const SizedBox(
              height:
                  24,
            ),
            sectionTitle(
              context,
              'Renewal reminders',
              Icons.notifications_active_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            SettingsCard(
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
            sectionTitle(
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
