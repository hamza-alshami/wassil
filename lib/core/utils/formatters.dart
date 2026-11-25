import 'package:intl/intl.dart' show NumberFormat;

/// Formats [amount] as Yemeni Rial with Arabic thousands separators.
String formatYemeniRial(double amount) {
  return '${NumberFormat('#,##0.##', 'ar').format(amount)} ر.ي';
}

/// Returns a localised Arabic label for an item count.
String itemsCountLabel(int count) => switch (count) {
      0 => 'لا توجد أصناف',
      1 => 'صنف واحد',
      2 => 'صنفان',
      < 11 => '$count أصناف',
      _ => '$count صنفًا',
    };
