# CancelBuddy

A Flutter subscription and bill tracker designed to help users keep track of recurring payments, upcoming renewals, and monthly spending.

## Overview

CancelBuddy lets users store and manage subscriptions and recurring bills in one place. It calculates monthly and yearly spending, tracks renewal dates, schedules local reminders, and can convert subscription prices between GBP, USD, and EUR.

The app uses local storage, so subscription data and settings are stored on the device.

## Features

### Subscription management

* Add, edit, and delete subscriptions
* Add subscriptions manually or choose from predefined templates
* Store subscription name, price, currency, category, billing cycle, notes, and management/cancellation URL
* Support for weekly, monthly, and yearly billing cycles
* Automatic calculation of monthly and yearly equivalent costs

### Renewal tracking

* Track the next renewal date for every subscription
* Automatically advance overdue recurring renewals
* Display upcoming renewals in the dashboard
* Show renewal status such as today, tomorrow, or number of days remaining

### Renewal reminders

* Schedule local notifications for upcoming renewals
* Choose reminder timing of 1, 3, 7, or 14 days before renewal
* Choose a custom reminder time
* Enable or disable reminders for individual subscriptions
* Automatically reschedule reminders when subscription details change
* Timezone-aware notification scheduling
* Android and iOS notification support

### Currency conversion

* Supports GBP, USD, and EUR
* Convert subscription prices between supported currencies
* Convert dashboard totals into the selected currency
* Uses the Frankfurter Exchange Rates API for exchange rates
* Caches exchange rates in memory to reduce repeated requests
* Handles API failures and unavailable exchange rates

> Live exchange-rate conversion requires an internet connection.

### Spending insights

* Monthly and yearly spending totals
* Spending breakdown by subscription category
* Category-based progress indicators
* Expandable spending categories

### Predefined subscriptions

The app includes predefined subscription templates across categories including:

* Entertainment
* Music
* AI
* Software
* Cloud Storage
* Gaming
* Fitness
* News & Reading
* Bills

Users can search the catalogue and filter it by category before adding a subscription.

Predefined prices are stored in the application as templates and should not be treated as guaranteed current provider pricing.

### Interface

* Material 3 design
* Light and dark themes
* Service-specific icons and visual styling
* Animated dashboard totals and subscription cards
* Responsive subscription selection and editing screens
* Custom app icon

## Screens

The application includes:

* Dashboard
* Subscription selection
* Add Subscription
* Edit Subscription
* Settings
* Spending Insights
* Renewal Reminder configuration

## Tech Stack

| Technology                  | Purpose                              |
| --------------------------- | ------------------------------------ |
| Flutter                     | Cross-platform application framework |
| Dart                        | Programming language                 |
| Hive                        | Local data storage                   |
| Hive Flutter                | Flutter integration for Hive         |
| HTTP                        | API requests                         |
| Frankfurter API             | Currency exchange rates              |
| flutter_local_notifications | Local notifications                  |
| timezone                    | Timezone-aware scheduling            |
| flutter_timezone            | Device timezone detection            |
| Material 3                  | UI design system                     |

## Project Structure

```text
lib/
├── main.dart
├── choose_subscription.dart
├── currency_utils.dart
├── notification_service.dart
├── predefined.dart
├── service_icons.dart
└── subscription.dart

assets/
└── CB_Icon.png
```

### Main files

**`main.dart`**
Contains the application entry point, settings, dashboard, subscription creation/editing screens, spending insights, and shared UI components.

**`choose_subscription.dart`**
Provides the predefined subscription catalogue, search, category filtering, price conversion, and manual entry.

**`currency_utils.dart`**
Handles currency symbols, exchange-rate requests, conversion, and rate caching.

**`notification_service.dart`**
Initializes notifications, handles permissions, schedules renewal reminders, cancels reminders, and synchronizes notifications.

**`predefined.dart`**
Contains the built-in subscription and bill templates.

**`service_icons.dart`**
Provides service-specific icons, colours, and background styling.

**`subscription.dart`**
Contains the subscription data model, recurring-cost calculations, renewal calculations, validation, and local serialization.

## Getting Started

### Prerequisites

You will need:

* Flutter SDK
* Dart SDK
* Android Studio, VS Code, or another Flutter development environment
* A configured Android or iOS device/emulator

### Clone the repository

```bash
git clone https://github.com/Shiesty227/cancelbuddy.git
cd cancelbuddy
```

### Install dependencies

```bash
flutter pub get
```

### Run the application

```bash
flutter run
```

### Check the project

```bash
flutter analyze
```

## Local Data

CancelBuddy uses Hive for local persistence.

The app stores:

* Subscription records
* Dashboard currency preference
* Dark mode preference
* Default reminder days
* Default reminder time

No account or cloud backend is required for the core subscription tracking functionality.

## Notifications

Notification permissions are requested when needed.

On Android, the app creates a dedicated notification channel for renewal reminders.

On iOS, notification permissions are requested through the native notification system.

Notification scheduling uses the device's local timezone.

## Currency API

Currency conversion uses the Frankfurter API:

https://api.frankfurter.dev/

The application requests exchange rates when converting between supported currencies and caches retrieved rates in memory.

## Current Limitations

* Subscription data is stored locally on the device
* There is currently no user account or cloud synchronization
* Currency conversion depends on the external Frankfurter API
* Predefined subscription prices are static templates
* The application currently supports GBP, USD, and EUR

## Future Improvements

Possible future improvements include:

* Cloud backup and synchronization
* User accounts
* Spending history and charts
* More currencies
* More predefined subscription templates
* Deeper cancellation workflows
* More advanced reminder options
* Subscription statistics and trends

## Version

**1.0.0+1**

## License

This project is currently not published under an open-source license.
