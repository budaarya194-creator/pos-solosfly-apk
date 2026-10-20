import 'package:intl/intl.dart';

class CurrencyFormat {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 2,
  );

  static final NumberFormat _shortFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  /// Format as 40.000,00 (strict format for receipt)
  static String format(num value) {
    return _formatter.format(value).trim();
  }

  /// Format with Rp prefix for dashboard cards: Rp 645.000
  static String formatWithRp(num value) {
    return 'Rp ${_shortFormatter.format(value).trim()}';
  }

  /// Format compact for chart tooltips or labels e.g. 520k / 1.2M
  static String formatCompact(num value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}M';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toStringAsFixed(0);
  }
}
