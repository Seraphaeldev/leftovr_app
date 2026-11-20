import '../models/fridge_item.dart';
import '../models/recipe.dart';

/// One recipe scored against what is currently in the fridge.
class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.have,
    required this.missing,
  });

  final Recipe recipe;
  final List<RecipeIngredient> have;
  final List<RecipeIngredient> missing;

  double get coverage => recipe.ingredients.isEmpty
      ? 0
      : have.length / recipe.ingredients.length;

  bool get ready => missing.isEmpty;

  String get coverageLabel => '${(coverage * 100).round()}%';
}

/// Scores the offline catalog against the inventory. No network, no services —
/// just string matching, so it works on a plane or in a basement.
class RecipeMatcher {
  const RecipeMatcher();

  List<RecipeMatch> match(
    List<FridgeItem> items, {
    String query = '',
    bool readyOnly = false,
  }) {
    final q = query.trim().toLowerCase();
    final matches = <RecipeMatch>[];

    for (final recipe in Recipe.catalog) {
      if (q.isNotEmpty && !recipe.title.toLowerCase().contains(q)) continue;

      final have = <RecipeIngredient>[];
      final missing = <RecipeIngredient>[];
      for (final ingredient in recipe.ingredients) {
        if (_haveIngredient(items, ingredient)) {
          have.add(ingredient);
        } else {
          missing.add(ingredient);
        }
      }

      final match = RecipeMatch(
        recipe: recipe,
        have: have,
        missing: missing,
      );
      if (readyOnly && !match.ready) continue;
      matches.add(match);
    }

    matches.sort((a, b) {
      final byCoverage = b.coverage.compareTo(a.coverage);
      if (byCoverage != 0) return byCoverage;
      return a.recipe.title.compareTo(b.recipe.title);
    });
    return matches;
  }

  bool _haveIngredient(List<FridgeItem> items, RecipeIngredient ingredient) {
    final wanted = ingredient.name.toLowerCase();
    for (final item in items) {
      final actual = item.name.toLowerCase();
      if (actual.contains(wanted) || wanted.contains(actual)) return true;
      // Crude singular/plural tolerance: tomato / tomatoes, banana / bananas.
      if (wanted.endsWith('s') && actual.contains(wanted.substring(0, wanted.length - 1))) {
        return true;
      }
      if (actual.endsWith('s') && wanted.contains(actual.substring(0, actual.length - 1))) {
        return true;
      }
    }
    return false;
  }
}
