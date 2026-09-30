import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cancelbuddy/app_settings.dart';
import 'package:cancelbuddy/widgets/form_fields.dart';

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
            sectionTitle(
              context,
              'Currency',
              Icons.currency_exchange_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            SettingsCard(
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
            sectionTitle(
              context,
              'Appearance',
              Icons.palette_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            SettingsCard(
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
                  HapticFeedback
                      .selectionClick();

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
            sectionTitle(
              context,
              'About',
              Icons.info_outline_rounded,
            ),
            const SizedBox(
              height:
                  12,
            ),
            SettingsCard(
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
