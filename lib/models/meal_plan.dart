import 'dart:convert';

/// A recipe the user has chosen to cook. Stored locally and used to build the
/// shopping list of ingredients that are missing from the fridge.
class PlannedMeal {
  PlannedMeal({
    String? id,
    required this.recipeId,
    this.servings = 2,
    this.slot = 'Dinner',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String recipeId;
  final int servings;
  final String slot;

  PlannedMeal copyWith({int? servings, String? slot}) => PlannedMeal(
        id: id,
        recipeId: recipeId,
        servings: servings ?? this.servings,
        slot: slot ?? this.slot,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'servings': servings,
        'slot': slot,
      };

  factory PlannedMeal.fromJson(Map<String, dynamic> json) => PlannedMeal(
        id: json['id'] as String?,
        recipeId: json['recipeId'] as String? ?? '',
        servings: (json['servings'] as num?)?.toInt() ?? 2,
        slot: json['slot'] as String? ?? 'Dinner',
      );

  static List<PlannedMeal> decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <PlannedMeal>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PlannedMeal.fromJson)
          .toList();
    } catch (_) {
      return <PlannedMeal>[];
    }
  }

  static String encodeList(List<PlannedMeal> meals) =>
      jsonEncode(meals.map((m) => m.toJson()).toList());
}
