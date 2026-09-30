import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cancelbuddy/currency_utils.dart';
import 'package:cancelbuddy/service_icons.dart';
import 'package:cancelbuddy/subscription.dart';
import 'package:cancelbuddy/utils/helpers.dart';
import 'package:cancelbuddy/widgets/form_fields.dart';

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

    // Keep the subscription's own currency
    // so editing never converts the price.
    currency =
        widget.sub.currency
            .toUpperCase();

    priceCurrency =
        currency;

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
  // CURRENCY CHANGE
  // ==========================================================

  // Switching currency only relabels the
  // price; it never converts the amount.
  void _changeCurrency(
    String? value,
  ) {
    if (value == null ||
        value == currency ||
        isCurrencyConverting) {
      return;
    }

    setState(
      () {
        currency =
            value;

        priceCurrency =
            value;
      },
    );
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

    HapticFeedback.lightImpact();

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
      category,
    ).forBrightness(
      Theme.of(context).brightness,
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
            ServicePreview(
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
                      : _changeCurrency,
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
              Icons
                  .notifications_active_rounded,
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
