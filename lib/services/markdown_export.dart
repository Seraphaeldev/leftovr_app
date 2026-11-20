import '../models/meal_plan.dart';
import '../models/recipe.dart';

/// One aggregated line in the shopping list.
class ShoppingItem {
  ShoppingItem(this.name, this.quantity, this.unit)
      : key = '${name.trim().toLowerCase()}|${unit.trim().toLowerCase()}';

  final String name;
  final int quantity;
  final String unit;
  final String key;
}

/// Builds and renders the shopping list entirely offline.
class MarkdownExporter {
  const MarkdownExporter();

  List<ShoppingItem> shoppingList(
    List<PlannedMeal> plan,
    List<FridgeItemLite> stock,
  ) {
    // Aggregate the whole plan first, so several meals drawing on the same
    // ingredient share one stock balance instead of each seeing it in full.
    final needs = <String, _Need>{};
    for (final meal in plan) {
      final recipe = Recipe.byId(meal.recipeId);
      if (recipe == null) continue;
      for (final ingredient in recipe.ingredients) {
        final key =
            '${ingredient.name.trim().toLowerCase()}|${_normalizeUnit(ingredient.unit)}';
        final need = needs.putIfAbsent(
          key,
          () => _Need(ingredient.name, ingredient.unit),
        );
        need.quantity +=
            (ingredient.quantity * meal.servings / recipe.servings).ceil();
      }
    }

    final totals = <String, ShoppingItem>{};
    for (final need in needs.values) {
      final available = stock.fold<int>(
        0,
        (sum, s) =>
            sum + (_matches(s.name, need.name) ? _availableInUnit(s, need.unit) : 0),
      );
      final short = need.quantity - available;
      if (short <= 0) continue;

      final key =
          '${need.name.trim().toLowerCase()}|${_normalizeUnit(need.unit)}';
      totals[key] = ShoppingItem(need.name, short, need.unit);
    }

    final items = totals.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  /// Stock only counts towards a need written in a compatible unit.
  int _availableInUnit(FridgeItemLite item, String unit) {
    return _normalizeUnit(item.unit) == _normalizeUnit(unit) ? item.quantity : 0;
  }

  /// Lowercase and fold singular/plural spellings such as `cup`/`cups`.
  static String _normalizeUnit(String unit) {
    final value = unit.trim().toLowerCase();
    if (value.length > 1 && value.endsWith('s')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  String render({
    required List<PlannedMeal> plan,
    required List<ShoppingItem> shopping,
    DateTime? now,
  }) {
    final date = now ?? DateTime.now();
    final buffer = StringBuffer()
      ..writeln('# leftovr shopping list')
      ..writeln()
      ..writeln('_Generated ${_formatDate(date)} · offline · no account needed_')
      ..writeln()
      ..writeln('## Shopping')
      ..writeln();

    if (shopping.isEmpty) {
      buffer.writeln('_Nothing to buy — you already have everything planned._');
    } else {
      for (final item in shopping) {
        buffer.writeln('- [ ] ${item.quantity} × ${item.name} (${item.unit})');
      }
    }

    buffer
      ..writeln()
      ..writeln('## Meal plan')
      ..writeln();

    if (plan.isEmpty) {
      buffer.writeln('_No meals planned yet._');
    } else {
      for (final meal in plan) {
        final recipe = Recipe.byId(meal.recipeId);
        final title = recipe?.title ?? meal.recipeId;
        buffer.writeln('- **$title** — ${meal.servings} serving(s), ${meal.slot}');
      }
    }

    buffer
      ..writeln()
      ..writeln('---')
      ..writeln()
      ..writeln('Made locally with leftovr.');

    return buffer.toString();
  }

  bool _matches(String actual, String wanted) {
    final a = actual.toLowerCase();
    final w = wanted.toLowerCase();
    if (a.contains(w) || w.contains(a)) return true;
    if (w.endsWith('s') && a.contains(w.substring(0, w.length - 1))) return true;
    if (a.endsWith('s') && w.contains(a.substring(0, a.length - 1))) return true;
    return false;
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

/// One ingredient's total demand across the whole meal plan.
class _Need {
  _Need(this.name, this.unit);

  final String name;
  final String unit;
  int quantity = 0;
}

/// The tiny slice of an inventory item the exporter needs. Kept separate so
/// pure-Dart tooling can supply it without depending on Flutter.
class FridgeItemLite {
  const FridgeItemLite(this.name, this.quantity, [this.unit = 'pcs']);

  final String name;
  final int quantity;
  final String unit;
}
