import 'package:intl/intl.dart';

class AppUtils {
  // Date formatting utilities
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    return DateFormat(format).format(date);
  }
  
  static String formatDateTime(DateTime dateTime, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    return DateFormat(format).format(dateTime);
  }
  
  static DateTime? parseDate(String dateString, {String format = 'yyyy-MM-dd'}) {
    try {
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  static DateTime? parseDateTime(String dateTimeString, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    try {
      return DateFormat(format).parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }
  
  // Number formatting utilities
  static String formatCurrency(double amount, {String currency = 'SAR'}) {
    final formatter = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: currency,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
  
  static String formatNumber(double number, {int decimalDigits = 2}) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: 'ar_SA',
      decimalDigits: decimalDigits,
    );
    return formatter.format(number);
  }
  
  static double? parseNumber(String numberString) {
    try {
      return NumberFormat.decimalPattern('ar_SA').parse(numberString).toDouble();
    } catch (e) {
      try {
        return double.tryParse(numberString);
      } catch (e) {
        return null;
      }
    }
  }
  
  // String utilities
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  }
  
  static bool isEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }
  
  static bool isNotEmpty(String? text) {
    return !isEmpty(text);
  }
  
  // Validation utilities
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
  
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[+]?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= 8;
  }
  
  static bool isValidAmount(String amount) {
    final amountRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    return amountRegex.hasMatch(amount);
  }
  
  // File size utilities
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  // Time utilities
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} يوم مضى';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة مضت';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة مضت';
    } else {
      return 'الآن';
    }
  }
  
  // Arabic number utilities
  static String convertToArabicNumbers(String input) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = '';
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char.contains(RegExp(r'[0-9]'))) {
        result += arabicNumbers[int.parse(char)];
      } else {
        result += char;
      }
    }
    return result;
  }
  
  static String convertToLatinNumbers(String input) {
    const latinNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = '';
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final index = arabicNumbers.indexOf(char);
      if (index != -1) {
        result += latinNumbers[index];
      } else {
        result += char;
      }
    }
    return result;
  }
}
