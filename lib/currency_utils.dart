import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyUtils {
  CurrencyUtils._();

  static final Map<String, double> _rateCache = {};

  static String symbolOf(String code) {
    switch (code.toUpperCase()) {
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      default:
        return code;
    }
  }

  static Future<double> exchangeRate(
    String from,
    String to,
  ) async {
    final source = from.toUpperCase();
    final target = to.toUpperCase();

    if (source == target) {
      return 1.0;
    }

    final cacheKey = '$source->$target';

    final cached = _rateCache[cacheKey];

    if (cached != null) {
      return cached;
    }

    final uri = Uri.parse(
      'https://api.frankfurter.dev/v2/rate/'
      '${source.toLowerCase()}/${target.toLowerCase()}',
    );

    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Currency API returned ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    final rawRate = data['rate'];

    if (rawRate is! num) {
      throw Exception(
        'Invalid exchange rate',
      );
    }

    final rate = rawRate.toDouble();

    _rateCache[cacheKey] = rate;

    return rate;
  }

  static Future<double> convertAmount(
    double amount,
    String from,
    String to,
  ) async {
    if (amount == 0) {
      return 0;
    }

    final source = from.toUpperCase();
    final target = to.toUpperCase();

    if (source == target) {
      return amount;
    }

    final rate = await exchangeRate(
      source,
      target,
    );

    return amount * rate;
  }

  static void clearCache() {
    _rateCache.clear();
  }
}