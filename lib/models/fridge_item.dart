import 'dart:convert';

import 'package:flutter/material.dart';

/// Categories a fridge item can belong to.
///
/// Everything stays in the monochrome palette: [colorValue] is a shade of
/// grey and [icon] is a soft outlined glyph used on cards and chips.
enum ItemCategory {
  dairy('DAIRY', Icons.local_drink_outlined, 0xFFA8A8A2),
  produce('PRODUCE', Icons.eco_outlined, 0xFF7E7E78),
  meat('MEAT', Icons.restaurant_outlined, 0xFF5A5A55),
  drinks('DRINKS', Icons.local_cafe_outlined, 0xFF96968F),
  leftovers('LEFTOVERS', Icons.lunch_dining_outlined, 0xFF6D6D67),
  snacks('SNACKS', Icons.cake_outlined, 0xFFB4B4AE),
  other('OTHER', Icons.inventory_2_outlined, 0xFF8C8C86);

  const ItemCategory(this.label, this.icon, this.colorValue);

  final String label;
  final IconData icon;
  final int colorValue;

  /// Monochrome line-art illustration used on item cards.
  String get image => 'assets/images/categories/$name.png';
}

enum ExpiryStatus { fresh, soon, expired }

extension ExpiryStatusLabel on ExpiryStatus {
  String get label => switch (this) {
        ExpiryStatus.fresh => 'FRESH',
        ExpiryStatus.soon => 'SOON',
        ExpiryStatus.expired => 'OUTDATED',
      };
}

/// A single thing living in the fridge.
class FridgeItem {
  FridgeItem({
    String? id,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.unit = 'pcs',
    required this.expiry,
    this.notes = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String name;
  final ItemCategory category;
  final int quantity;
  final String unit;
  final DateTime expiry;
  final String notes;

  FridgeItem copyWith({int? quantity}) => FridgeItem(
        id: id,
        name: name,
        category: category,
        quantity: quantity ?? this.quantity,
        unit: unit,
        expiry: expiry,
        notes: notes,
      );

  /// Whole days until the expiry date. Negative means already past it.
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(expiry.year, expiry.month, expiry.day);
    return date.difference(today).inDays;
  }

  ExpiryStatus get status {
    final days = daysLeft;
    if (days < 0) return ExpiryStatus.expired;
    if (days <= 3) return ExpiryStatus.soon;
    return ExpiryStatus.fresh;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'quantity': quantity,
        'unit': unit,
        'expiry': _dateToString(expiry),
        'notes': notes,
      };

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'] as String? ?? 'other';
    return FridgeItem(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Item',
      category: ItemCategory.values.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => ItemCategory.other,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String? ?? 'pcs',
      expiry: _dateFromString(json['expiry'] as String?) ??
          DateTime.now().add(const Duration(days: 7)),
      notes: json['notes'] as String? ?? '',
    );
  }

  static String _dateToString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime? _dateFromString(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  static List<FridgeItem> decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(FridgeItem.fromJson)
          .toList();
    } catch (_) {
      return <FridgeItem>[];
    }
  }

  static String encodeList(List<FridgeItem> items) =>
      jsonEncode(items.map((item) => item.toJson()).toList());

  /// A starter stock so the app looks alive on first launch.
  static List<FridgeItem> seed() {
    DateTime inDays(int days) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day)
          .add(Duration(days: days));
    }

    return [
      FridgeItem(name: 'Milk', category: ItemCategory.dairy, quantity: 1, unit: 'L', expiry: inDays(2)),
      FridgeItem(name: 'Eggs', category: ItemCategory.dairy, quantity: 8, expiry: inDays(12)),
      FridgeItem(name: 'Cheddar', category: ItemCategory.dairy, quantity: 1, unit: 'pack', expiry: inDays(6)),
      FridgeItem(name: 'Butter', category: ItemCategory.dairy, quantity: 1, unit: 'tub', expiry: inDays(20)),
      FridgeItem(name: 'Spinach', category: ItemCategory.produce, quantity: 1, unit: 'bag', expiry: inDays(1)),
      FridgeItem(name: 'Tomatoes', category: ItemCategory.produce, quantity: 4, expiry: inDays(5)),
      FridgeItem(name: 'Bananas', category: ItemCategory.produce, quantity: 6, expiry: inDays(4)),
      FridgeItem(name: 'Chicken breast', category: ItemCategory.meat, quantity: 2, expiry: inDays(-1)),
      FridgeItem(name: 'Orange juice', category: ItemCategory.drinks, quantity: 1, unit: 'bottle', expiry: inDays(9)),
      FridgeItem(name: 'Craft beer', category: ItemCategory.drinks, quantity: 6, unit: 'cans', expiry: inDays(30)),
      FridgeItem(name: 'Leftover pasta', category: ItemCategory.leftovers, quantity: 1, unit: 'box', expiry: inDays(0)),
      FridgeItem(name: 'Dark chocolate', category: ItemCategory.snacks, quantity: 2, unit: 'bars', expiry: inDays(60)),
    ];
  }
}
