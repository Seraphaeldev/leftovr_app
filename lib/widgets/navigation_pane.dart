import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/fridge_cubit.dart';
import '../models/fridge_item.dart';
import '../theme.dart';
import 'decorations.dart';

/// The left pane: search, freshness filters and category navigation.
class NavigationPane extends StatefulWidget {
  const NavigationPane({super.key, required this.searchFocus});

  final FocusNode searchFocus;

  @override
  State<NavigationPane> createState() => _NavigationPaneState();
}

class _NavigationPaneState extends State<NavigationPane> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FridgeCubit, FridgeState>(
      buildWhen: (a, b) =>
          a.items != b.items ||
          a.category != b.category ||
          a.status != b.status ||
          a.ready != b.ready,
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('YOUR FRIDGE', style: AppText.label),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(18),
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL ITEMS', style: AppText.label),
                    const SizedBox(height: 6),
                    Text(
                      '${state.items.length}',
                      style: AppText.bigNumber.copyWith(fontSize: 34),
                    ),
                    const SizedBox(height: 4),
                    Text('all in one place', style: AppText.bodyMuted),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _search,
                focusNode: widget.searchFocus,
                onChanged: (value) =>
                    context.read<FridgeCubit>().setQuery(value),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search,
                      size: 18, color: AppPalette.muted),
                  hintText: 'Search',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 26),
              Text('FRESHNESS', style: AppText.label),
              const SizedBox(height: 10),
              _navTile(
                context,
                label: 'All items',
                selected: state.status == null,
                count: state.items.length,
                onTap: () => context.read<FridgeCubit>().setStatus(null),
              ),
              for (final status in ExpiryStatus.values)
                _navTile(
                  context,
                  label: _label(status),
                  selected: state.status == status,
                  count: state.count(status),
                  onTap: () =>
                      context.read<FridgeCubit>().setStatus(status),
                ),
              const SizedBox(height: 26),
              Text('CATEGORIES', style: AppText.label),
              const SizedBox(height: 10),
              _navTile(
                context,
                label: 'All',
                selected: state.category == null,
                count: state.items.length,
                onTap: () => context.read<FridgeCubit>().setCategory(null),
              ),
              for (final category in ItemCategory.values)
                _navTile(
                  context,
                  label: _title(category.label),
                  icon: category.icon,
                  selected: state.category == category,
                  count: state.countCategory(category),
                  onTap: () =>
                      context.read<FridgeCubit>().setCategory(category),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _navTile(
    BuildContext context, {
    required String label,
    required bool selected,
    required int count,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppPalette.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppPalette.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon ?? Icons.circle_outlined,
                size: 15,
                color: selected ? AppPalette.ink : AppPalette.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppText.chip.copyWith(
                    color: selected ? AppPalette.ink : AppPalette.muted,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('$count',
                  style: AppText.value.copyWith(
                    fontSize: 11,
                    color: selected ? AppPalette.ink : AppPalette.muted,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(ExpiryStatus status) => switch (status) {
        ExpiryStatus.fresh => 'Fresh',
        ExpiryStatus.soon => 'Use soon',
        ExpiryStatus.expired => 'Outdated',
      };

  static String _title(String value) =>
      value.isEmpty ? value : value[0] + value.substring(1).toLowerCase();
}
