import 'package:intl/intl.dart';

class Helpers {
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'ZWG':
        return 'ZWG ';
      case 'ZAR':
        return 'R ';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'USD':
      default:
        return '\$';
    }
  }

  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String getCurrentMonth() {
    return DateFormat('yyyy-MM').format(DateTime.now());
  }

  static String getMonthName(String yearMonth) {
    final date = DateTime.parse('$yearMonth-01');
    return DateFormat('MMMM yyyy').format(date);
  }
}