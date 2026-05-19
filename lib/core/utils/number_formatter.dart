import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NumberFormatter {
  static const String _useArabicFormatKey = 'use_arabic_number_format';
  static const String _currencyKey = 'selected_currency';
  static const String _useShortFormatKey = 'use_short_number_format';
  static bool _useArabicFormat = false;
  static String _selectedCurrency = 'SYP';
  static bool _useShortFormat = true; // Default: use short format (1M, 1K)

  // Available currencies
  static final Map<String, String> _currencySymbols = {
    'SYP': 'ل.س',
    'USD': r'$',
    'EUR': '€',
    'TRY': '₺',
  };

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useArabicFormat = prefs.getBool(_useArabicFormatKey) ?? false;
      _selectedCurrency = prefs.getString(_currencyKey) ?? 'SYP';
      _useShortFormat = prefs.getBool(_useShortFormatKey) ?? true;
    } catch (e) {
      if (kDebugMode) print('Error loading number format preference: $e');
      _useArabicFormat = false;
      _selectedCurrency = 'SYP';
    }
  }

  static Future<void> setArabicFormat(bool useArabic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useArabicFormatKey, useArabic);
      _useArabicFormat = useArabic;
    } catch (e) {
      if (kDebugMode) print('Error saving number format preference: $e');
    }
  }

  static Future<void> setCurrency(String currencyCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, currencyCode);
      _selectedCurrency = currencyCode;
    } catch (e) {
      if (kDebugMode) print('Error saving currency preference: $e');
    }
  }

  static Future<void> setUseShortFormat(bool useShort) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useShortFormatKey, useShort);
      _useShortFormat = useShort;
    } catch (e) {
      if (kDebugMode) print('Error saving short format preference: $e');
    }
  }

  static bool get isArabicFormat => _useArabicFormat;
  static String get selectedCurrency => _selectedCurrency;
  static bool get useShortFormat => _useShortFormat;

  static String getCurrencySymbol() {
    return _currencySymbols[_selectedCurrency] ?? _selectedCurrency;
  }

  static List<String> get availableCurrencies => _currencySymbols.keys.toList();

  static String format(num number) {
    if (_useArabicFormat) {
      return _formatArabic(number);
    } else {
      return _formatStandard(number);
    }
  }

  static String _formatStandard(num number) {
    if (number is int) {
      return number.toStringAsFixed(2);
    }
    return number.toStringAsFixed(2);
  }

  static String _formatArabic(num number) {
    if (number == 0) return '0.00';

    final absNumber = number.abs();
    final isNegative = number < 0;
    String result = '';

    if (absNumber >= 1000000000) {
      final billions = absNumber / 1000000000;
      result = '${billions.toStringAsFixed(2)} مليار';
    } else if (absNumber >= 1000000) {
      final millions = absNumber / 1000000;
      result = '${millions.toStringAsFixed(2)} ميليون';
    } else if (absNumber >= 1000) {
      final thousands = absNumber / 1000;
      result = '${thousands.toStringAsFixed(2)} ألف';
    } else {
      result = absNumber.toStringAsFixed(2);
    }

    return isNegative ? '-$result' : result;
  }

  // Format for currency with suffix
  static String formatCurrency(num number) {
    final formattedNumber = format(number);
    final currencySuffix = _useArabicFormat ? 'ل.س' : 'l.s';
    return '$formattedNumber $currencySuffix';
  }

  // Format for short display (like in charts)
  // If user disabled short format, returns full number without K/M suffix
  static String formatShort(num number) {
    // If short format is disabled, return full number
    if (!_useShortFormat) {
      return format(number);
    }
    // Otherwise use short format
    if (_useArabicFormat) {
      return _formatArabic(number);
    } else {
      return _formatShortStandard(number);
    }
  }

  static String _formatShortStandard(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(2);
  }
}
