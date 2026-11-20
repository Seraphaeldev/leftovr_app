import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/fridge_cubit.dart';
import '../models/recipe.dart';
import '../services/markdown_export.dart';
import '../services/recipe_matcher.dart';
import '../theme.dart';
import 'decorations.dart';

/// The right pane: offline recipe matching, meal planning and Markdown export.
class PlanningPane extends StatefulWidget {
  const PlanningPane({super.key});

  @override
  State<PlanningPane> createState() => _PlanningPaneState();
}

class _PlanningPaneState extends State<PlanningPane> {
  int _tab = 0;
  final _recipeSearch = TextEditingController();

  @override
  void dispose() {
    _recipeSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FridgeCubit, FridgeState>(
      buildWhen: (a, b) =>
          a.items != b.items || a.plannedMeals != b.plannedMeals,
      builder: (context, state) {
        final matcher = const RecipeMatcher();
        final matches = matcher.match(state.items, query: _recipeSearch.text);
        final shopping = const MarkdownExporter().shoppingList(
          state.plannedMeals,
          state.items
              .map((i) => FridgeItemLite(i.name, i.quantity))
              .toList(),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
              child: Text('PLAN & COOK', style: AppText.label),
            ),
            const SizedBox(height: 12),
            _tabs(),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (_tab) {
                  0 => _recipes(context, matches),
                  1 => _plan(context, state),
                  _ => _shopping(context, state, shopping),
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tabs() {
    const labels = ['Recipes', 'Plan', 'List'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _tab == i ? AppPalette.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: _tab == i
                        ? [
                            BoxShadow(
                              color: AppPalette.shadow,
                              blurRadius: 5,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: AppText.chip.copyWith(
                        color: _tab == i ? AppPalette.ink : AppPalette.muted,
                        fontWeight:
                            _tab == i ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _recipes(BuildContext context, List<RecipeMatch> matches) {
    return SingleChildScrollView(
      key: const ValueKey('recipes'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _recipeSearch,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, size: 17, color: AppPalette.muted),
              hintText: 'Find a recipe',
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          if (matches.isEmpty)
            Text('No recipes match that search.', style: AppText.bodyMuted),
          for (final match in matches) ...[
            _recipeCard(context, match),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _recipeCard(BuildContext context, RecipeMatch match) {
    final recipe = match.recipe;
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(recipe.title, style: AppText.title),
              ),
              Text('${recipe.minutes}m',
                  style: AppText.bodyMuted),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            match.ready
                ? 'You have everything · ready to cook'
                : 'Missing: ${match.missing.map((m) => m.name).join(', ')}',
            style: AppText.bodyMuted,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: match.coverage,
              minHeight: 4,
              backgroundColor: AppPalette.surfaceSunken,
              color: AppPalette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${match.coverageLabel} in your fridge',
                  style: AppText.bodyMuted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => context.read<FridgeCubit>().planMeal(
                      recipe.id,
                      servings: recipe.servings,
                    ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Cook this'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _plan(BuildContext context, FridgeState state) {
    return SingleChildScrollView(
      key: const ValueKey('plan'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.plannedMeals.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(20),
              radius: 18,
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      size: 34, color: AppPalette.muted),
                  const SizedBox(height: 12),
                  Text('No meals planned', style: AppText.heading),
                  const SizedBox(height: 6),
                  Text(
                    'Pick a recipe from the Recipes tab to build a shopping list.',
                    style: AppText.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          for (final meal in state.plannedMeals) ...[
            AppCard(
              padding: const EdgeInsets.all(16),
              radius: 18,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Recipe.byId(meal.recipeId)?.title ?? meal.recipeId,
                          style: AppText.title,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${meal.servings} servings · ${meal.slot}',
                          style: AppText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  SoftIconButton(
                    icon: Icons.close,
                    size: 28,
                    tooltip: 'Remove ${meal.recipeId}',
                    onTap: () => context
                        .read<FridgeCubit>()
                        .removePlannedMeal(meal.id),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (state.plannedMeals.isNotEmpty) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => context.read<FridgeCubit>().clearPlan(),
              child: const Text('Clear plan'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _shopping(
    BuildContext context,
    FridgeState state,
    List<ShoppingItem> shopping,
  ) {
    final markdown = const MarkdownExporter().render(
      plan: state.plannedMeals,
      shopping: shopping,
    );
    return SingleChildScrollView(
      key: const ValueKey('shopping'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('MARKDOWN PREVIEW', style: AppText.label),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    child: SelectableText(markdown, style: AppText.mono),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showExport(context, markdown),
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('Export Markdown'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExport(BuildContext context, String markdown) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Shopping list', style: AppText.heading),
        content: SizedBox(
          width: 520,
          height: 380,
          child: SingleChildScrollView(
            child: SelectableText(markdown, style: AppText.mono),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: markdown));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Markdown copied')),
              );
            },
            icon: const Icon(Icons.copy_all_outlined, size: 15),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
