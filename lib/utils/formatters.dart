/// Shared formatting utilities used across screens.
library;

/// Formats an integer as a comma-separated currency string without symbol.
/// e.g. 1234567 → "1,234,567"
String fmtNumber(num v) =>
    v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

/// Formats a double as a short Naira string.
/// e.g. 200000 → "₦200K"
String fmtCurrencyShort(double v) {
  if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '₦${(v / 1000).round()}K';
  return '₦${v.round()}';
}

/// Formats an integer as a Naira currency string.
/// e.g. 12500 → "₦12,500"
String fmtNaira(num v) => '₦${fmtNumber(v)}';
