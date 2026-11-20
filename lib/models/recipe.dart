/// A single ingredient needed by a recipe. Pure data — no Flutter dependency,
/// so the offline catalog can also be reasoned about from the CLI tooling.
class RecipeIngredient {
  const RecipeIngredient(
    this.name,
    this.quantity, [
    this.unit = 'pcs',
  ]);

  final String name;
  final int quantity;
  final String unit;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        json['name'] as String? ?? 'Ingredient',
        (json['quantity'] as num?)?.toInt() ?? 1,
        json['unit'] as String? ?? 'pcs',
      );
}

/// A complete offline recipe. The catalog ships with the app; matching and
/// planning never touch the network.
class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.minutes,
    required this.servings,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String title;
  final int minutes;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'minutes': minutes,
        'servings': servings,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'steps': steps,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String? ?? 'recipe',
        title: json['title'] as String? ?? 'Recipe',
        minutes: (json['minutes'] as num?)?.toInt() ?? 15,
        servings: (json['servings'] as num?)?.toInt() ?? 2,
        ingredients: (json['ingredients'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(RecipeIngredient.fromJson)
                .toList() ??
            const [],
        steps: (json['steps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  /// A small, deliberately compact catalog — enough variety to be useful,
  /// small enough to stay instant and completely offline.
  static const List<Recipe> catalog = [
    Recipe(
      id: 'spinach_pasta',
      title: 'Creamy Spinach Pasta',
      minutes: 20,
      servings: 2,
      ingredients: [
        RecipeIngredient('spinach', 1, 'bag'),
        RecipeIngredient('leftover pasta', 1, 'box'),
        RecipeIngredient('milk', 1, 'cup'),
        RecipeIngredient('cheddar', 1, 'handful'),
      ],
      steps: [
        'Wilt the spinach in a hot pan with a splash of water.',
        'Add the pasta and milk, then simmer until creamy.',
        'Fold through the cheddar and season to taste.',
      ],
    ),
    Recipe(
      id: 'tomato_omelette',
      title: 'Tomato & Cheddar Omelette',
      minutes: 12,
      servings: 1,
      ingredients: [
        RecipeIngredient('eggs', 3),
        RecipeIngredient('tomatoes', 2),
        RecipeIngredient('cheddar', 1, 'handful'),
      ],
      steps: [
        'Beat the eggs and season well.',
        'Cook the tomatoes until soft, then pour in the eggs.',
        'Scatter over the cheddar and fold when just set.',
      ],
    ),
    Recipe(
      id: 'chicken_rice',
      title: 'Simple Chicken & Rice',
      minutes: 30,
      servings: 2,
      ingredients: [
        RecipeIngredient('chicken breast', 2),
        RecipeIngredient('rice', 1, 'cup'),
        RecipeIngredient('spinach', 1, 'bag'),
      ],
      steps: [
        'Simmer the rice until tender.',
        'Sear the chicken until golden and cooked through.',
        'Wilt the spinach and serve everything together.',
      ],
    ),
    Recipe(
      id: 'banana_bread',
      title: 'Banana Bread',
      minutes: 50,
      servings: 6,
      ingredients: [
        RecipeIngredient('bananas', 3),
        RecipeIngredient('butter', 1, 'tub'),
        RecipeIngredient('eggs', 2),
        RecipeIngredient('flour', 2, 'cups'),
      ],
      steps: [
        'Mash the bananas and cream with the butter.',
        'Beat in the eggs, then fold in the flour.',
        'Bake at 175°C until a skewer comes out clean.',
      ],
    ),
    Recipe(
      id: 'cheesy_toast',
      title: 'Cheesy Toast',
      minutes: 8,
      servings: 1,
      ingredients: [
        RecipeIngredient('cheddar', 1, 'handful'),
        RecipeIngredient('butter', 1, 'pat'),
        RecipeIngredient('bread', 2, 'slices'),
      ],
      steps: [
        'Butter the bread and top with cheddar.',
        'Grill until bubbling and golden.',
      ],
    ),
    Recipe(
      id: 'garden_salad',
      title: 'Garden Salad',
      minutes: 10,
      servings: 2,
      ingredients: [
        RecipeIngredient('spinach', 1, 'bag'),
        RecipeIngredient('tomatoes', 3),
        RecipeIngredient('olive oil', 1, 'tbsp'),
      ],
      steps: [
        'Wash and tear the spinach into a bowl.',
        'Chop the tomatoes and add them in.',
        'Dress with olive oil and season.',
      ],
    ),
    Recipe(
      id: 'milk_shake',
      title: 'Chocolate Banana Shake',
      minutes: 5,
      servings: 1,
      ingredients: [
        RecipeIngredient('milk', 1, 'cup'),
        RecipeIngredient('bananas', 1),
        RecipeIngredient('dark chocolate', 2, 'bars'),
      ],
      steps: [
        'Blend the milk and banana until smooth.',
        'Add the chocolate and blend again.',
      ],
    ),
    Recipe(
      id: 'tomato_soup',
      title: 'Creamy Tomato Soup',
      minutes: 25,
      servings: 2,
      ingredients: [
        RecipeIngredient('tomatoes', 5),
        RecipeIngredient('milk', 1, 'cup'),
        RecipeIngredient('butter', 1, 'pat'),
      ],
      steps: [
        'Simmer the tomatoes until they collapse.',
        'Blend smooth, then stir in the milk and butter.',
      ],
    ),
    Recipe(
      id: 'fried_rice',
      title: 'Egg Fried Rice',
      minutes: 15,
      servings: 2,
      ingredients: [
        RecipeIngredient('rice', 2, 'cups'),
        RecipeIngredient('eggs', 2),
        RecipeIngredient('soy sauce', 1, 'tbsp'),
      ],
      steps: [
        'Fry the rice in a hot wok.',
        'Push it aside, scramble the eggs, then combine.',
        'Season with soy sauce and serve.',
      ],
    ),
    Recipe(
      id: 'chocolate_mousse',
      title: 'Quick Chocolate Mousse',
      minutes: 15,
      servings: 2,
      ingredients: [
        RecipeIngredient('dark chocolate', 2, 'bars'),
        RecipeIngredient('milk', 1, 'cup'),
        RecipeIngredient('eggs', 2),
      ],
      steps: [
        'Melt the chocolate gently.',
        'Whisk in the milk and egg yolks.',
        'Fold in stiffly beaten whites and chill.',
      ],
    ),
  ];

  static Recipe? byId(String id) {
    for (final recipe in catalog) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }
}
