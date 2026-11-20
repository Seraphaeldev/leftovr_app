import '../models/fridge_item.dart';

/// The structured result of parsing one line of typed quick-entry text.
class QuickEntry {
  const QuickEntry({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.expiry,
  });

  final String name;
  final int quantity;
  final String unit;
  final ItemCategory category;
  final DateTime expiry;

  FridgeItem toItem() => FridgeItem(
        name: name,
        category: category,
        quantity: quantity,
        unit: unit,
        expiry: expiry,
      );

  String get summary =>
      '$quantity × $name · ${_title(category.label)} · ${_when(expiry)}';

  static String _title(String value) =>
      value.isEmpty ? value : value[0] + value.substring(1).toLowerCase();

  static String _when(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = DateTime(date.year, date.month, date.day)
        .difference(today)
        .inDays;
    if (days < 0) return 'past date';
    if (days == 0) return 'use today';
    if (days == 1) return 'use tomorrow';
    return 'use in $days days';
  }
}

/// Parses short, natural lines like `2 milk 3d`, `eggs x6 tomorrow` or
/// `spinach exp 2026-12-01` into a fridge item. Entirely local and synchronous.
class QuickEntryParser {
  const QuickEntryParser();

  static const _units = [
    'bottle', 'bottles', 'cans', 'can', 'pack', 'packs', 'bag', 'bags',
    'tub', 'tubs', 'box', 'boxes', 'bars', 'bar', 'slices', 'slice',
    'cups', 'cup', 'kg', 'g', 'l', 'ml', 'tbsp', 'pcs', 'pc',
  ];

  static const _categoryWords = <ItemCategory, List<String>>{
    ItemCategory.dairy: [
      'milk', 'cheese', 'cheddar', 'yogurt', 'yoghurt', 'butter', 'eggs',
      'egg', 'cream',
    ],
    ItemCategory.produce: [
      'spinach', 'tomato', 'tomatoes', 'banana', 'bananas', 'apple', 'apples',
      'carrot', 'carrots', 'lettuce', 'onion', 'potato', 'cucumber', 'lemon',
    ],
    ItemCategory.meat: [
      'chicken', 'beef', 'pork', 'fish', 'salmon', 'turkey', 'bacon',
    ],
    ItemCategory.drinks: [
      'juice', 'beer', 'soda', 'water', 'coffee', 'tea', 'lemonade',
    ],
    ItemCategory.leftovers: [
      'leftover', 'leftovers', 'pasta', 'soup', 'curry', 'rice', 'stew',
    ],
    ItemCategory.snacks: [
      'chocolate', 'chips', 'cookie', 'cookies', 'biscuit', 'crisps', 'nuts',
    ],
  };

  QuickEntry? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    var working = text.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var days = 7;
    var dateSet = false;

    // Explicit ISO date wins over relative days.
    final iso = RegExp(r'\b(\d{4}-\d{2}-\d{2})\b').firstMatch(working);
    if (iso != null) {
      final parsed = DateTime.tryParse(iso.group(1)!);
      if (parsed != null) {
        days = DateTime(parsed.year, parsed.month, parsed.day)
            .difference(today)
            .inDays;
        dateSet = true;
      }
      working = working.replaceFirst(iso.group(0)!, ' ');
    }

    if (!dateSet) {
      final relative =
          RegExp(r'\b(\d+)\s*(?:d|days?|w|weeks?)\b').firstMatch(working);
      if (relative != null) {
        final amount = int.tryParse(relative.group(1)!) ?? 1;
        final token = relative.group(0)!.toLowerCase();
        days = token.contains('w') ? amount * 7 : amount;
        dateSet = true;
        working = working.replaceFirst(relative.group(0)!, ' ');
      }
    }

    if (!dateSet) {
      if (working.contains(RegExp(r'\btomorrow\b'))) {
        days = 1;
        dateSet = true;
      } else if (working.contains(RegExp(r'\btoday\b'))) {
        days = 0;
        dateSet = true;
      } else if (working.contains(RegExp(r'next\s+week'))) {
        days = 7;
        dateSet = true;
      }
      working = working
          .replaceAll(RegExp(r'\btomorrow\b'), ' ')
          .replaceAll(RegExp(r'\btoday\b'), ' ')
          .replaceAll(RegExp(r'next\s+week'), ' ');
    }

    // Quantity: leading "2 milk", "x2 milk" or trailing "milk x2".
    var quantity = 1;
    final leading = RegExp(r'^\s*(\d+)\s+').firstMatch(working);
    if (leading != null) {
      quantity = int.tryParse(leading.group(1)!) ?? 1;
      working = working.replaceFirst(leading.group(0)!, ' ');
    } else {
      final xQty = RegExp(r'\bx\s*(\d+)\b').firstMatch(working);
      if (xQty != null) {
        quantity = int.tryParse(xQty.group(1)!) ?? 1;
        working = working.replaceFirst(xQty.group(0)!, ' ');
      }
    }

    // Unit: prefer an explicit token, otherwise infer a gentle default.
    var unit = 'pcs';
    for (final candidate in _units) {
      if (working.contains(RegExp('\\b$candidate\\b'))) {
        unit = candidate;
        working = working.replaceFirst(RegExp('\\b$candidate\\b'), ' ');
        break;
      }
    }

    // Drop common filler words before treating what's left as the name.
    for (final filler in ['exp', 'expires', 'use', 'by', 'in', 'add', 'a', 'an']) {
      working = working.replaceAll(RegExp('\\b$filler\\b'), ' ');
    }

    final words = working
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return null;

    final name = words
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    final lowered = name.toLowerCase();

    var category = ItemCategory.other;
    for (final entry in _categoryWords.entries) {
      if (entry.value.any((word) => lowered.contains(word))) {
        category = entry.key;
        break;
      }
    }

    return QuickEntry(
      name: name,
      quantity: quantity < 1 ? 1 : quantity,
      unit: unit,
      category: category,
      expiry: today.add(Duration(days: days)),
    );
  }
}
