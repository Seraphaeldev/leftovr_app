import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fridge_item.dart';
import '../models/meal_plan.dart';
import '../services/expiry.dart';
import '../services/inventory_file.dart';
import '../services/quick_entry.dart';

class FridgeState extends Equatable {
  const FridgeState({
    this.items = const <FridgeItem>[],
    this.query = '',
    this.category,
    this.status,
    this.sort = 'expiry',
    this.ready = false,
    this.changedId,
    this.changeSeq = 0,
    this.isDark = false,
    this.plannedMeals = const <PlannedMeal>[],
  });

  final List<FridgeItem> items;
  final String query;
  final ItemCategory? category;
  final ExpiryStatus? status;
  final String sort;
  final bool ready;

  /// The item that was just added or adjusted, used for a brief highlight so
  /// an update is visible without reordering or flickering the whole list.
  final String? changedId;
  final int changeSeq;

  /// Whether the strict black-and-white palette is in its dark variant.
  final bool isDark;

  /// Recipes queued for cooking, stored locally.
  final List<PlannedMeal> plannedMeals;

  FridgeState copyWith({
    List<FridgeItem>? items,
    String? query,
    ItemCategory? category,
    bool clearCategory = false,
    ExpiryStatus? status,
    bool clearStatus = false,
    String? sort,
    bool? ready,
    String? changedId,
    bool clearChangedId = false,
    int? changeSeq,
    bool? isDark,
    List<PlannedMeal>? plannedMeals,
  }) {
    return FridgeState(
      items: items ?? this.items,
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      status: clearStatus ? null : (status ?? this.status),
      sort: sort ?? this.sort,
      ready: ready ?? this.ready,
      changedId: clearChangedId ? null : (changedId ?? this.changedId),
      changeSeq: changeSeq ?? this.changeSeq,
      isDark: isDark ?? this.isDark,
      plannedMeals: plannedMeals ?? this.plannedMeals,
    );
  }

  List<FridgeItem> get visible {
    final q = query.trim().toLowerCase();
    final list = items.where((item) {
      final matchesCategory = category == null || item.category == category;
      final matchesStatus = status == null || item.status == status;
      final matchesQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.category.label.toLowerCase().contains(q);
      return matchesCategory && matchesStatus && matchesQuery;
    }).toList();

    switch (sort) {
      case 'name':
        list.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case 'qty':
        list.sort((a, b) => b.quantity.compareTo(a.quantity));
      case 'category':
        list.sort((a, b) => a.category.name.compareTo(b.category.name));
      default:
        list.sort((a, b) => a.expiry.compareTo(b.expiry));
    }
    return list;
  }

  int count(ExpiryStatus status) =>
      items.where((item) => item.status == status).length;

  int countCategory(ItemCategory category) =>
      items.where((item) => item.category == category).length;

  @override
  List<Object?> get props => [
        items,
        query,
        category,
        status,
        sort,
        ready,
        changedId,
        changeSeq,
        isDark,
        plannedMeals,
      ];
}

/// Holds all fridge state in one place; widgets rebuild only for the slice
/// they care about via [BlocBuilder.buildWhen]. Everything is local — the app
/// has no network code at all.
class FridgeCubit extends Cubit<FridgeState> {
  FridgeCubit(this._prefs) : super(const FridgeState());

  static const _storageKey = 'fridge_items_v1';
  static const _planKey = 'meal_plan_v1';
  static const _themeKey = 'theme_dark';
  static const _notifiedKey = 'expiry_notified_v1';

  final SharedPreferences _prefs;

  Future<void> load() async {
    final raw = _prefs.getString(_storageKey);
    final loaded = raw == null ? null : FridgeItem.decodeList(raw);
    final items = (loaded == null || loaded.isEmpty) ? FridgeItem.seed() : loaded;
    final planRaw = _prefs.getString(_planKey);
    emit(state.copyWith(
      items: items,
      ready: true,
      isDark: _prefs.getBool(_themeKey) ?? false,
      plannedMeals:
          planRaw == null ? const <PlannedMeal>[] : PlannedMeal.decodeList(planRaw),
    ));
    await _persist();
  }

  Future<void> _persist() async {
    await _prefs.setString(_storageKey, FridgeItem.encodeList(state.items));
    await InventoryFile.write(state.items);
  }

  Future<void> _persistPlan() =>
      _prefs.setString(_planKey, PlannedMeal.encodeList(state.plannedMeals));

  // ---- Appearance -------------------------------------------------------

  void toggleTheme() => setDark(!state.isDark);

  void setDark(bool value) {
    emit(state.copyWith(isDark: value));
    _prefs.setBool(_themeKey, value);
  }

  // ---- Browsing ---------------------------------------------------------

  void setQuery(String query) => emit(state.copyWith(query: query));

  void setSort(String sort) => emit(state.copyWith(sort: sort));

  void setCategory(ItemCategory? category) => emit(
        category == null
            ? state.copyWith(clearCategory: true)
            : state.copyWith(category: category),
      );

  void setStatus(ExpiryStatus? status) => emit(
        status == null
            ? state.copyWith(clearStatus: true)
            : state.copyWith(status: status),
      );

  // ---- Inventory --------------------------------------------------------

  void addItem(FridgeItem item) {
    emit(state.copyWith(
      items: [...state.items, item],
      changedId: item.id,
      changeSeq: state.changeSeq + 1,
    ));
    _persist();
  }

  /// Parses and adds a line of keyboard quick-entry text, e.g. `2 milk 3d`.
  QuickEntry? addQuickEntry(String text) {
    final parsed = const QuickEntryParser().parse(text);
    if (parsed == null) return null;
    addItem(parsed.toItem());
    return parsed;
  }

  void deleteItem(String id) {
    emit(
      state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
        clearChangedId: true,
      ),
    );
    _persist();
  }

  void changeQuantity(FridgeItem item, int delta) {
    final next = item.quantity + delta;
    final updated = next <= 0
        ? state.items.where((entry) => entry.id != item.id).toList()
        : state.items
            .map((entry) =>
                entry.id == item.id ? entry.copyWith(quantity: next) : entry)
            .toList();
    emit(state.copyWith(
      items: updated,
      changedId: next <= 0 ? null : item.id,
      clearChangedId: next <= 0,
      changeSeq: state.changeSeq + 1,
    ));
    _persist();
  }

  // ---- Meal planning ----------------------------------------------------

  void planMeal(String recipeId, {int servings = 2, String slot = 'Dinner'}) {
    emit(state.copyWith(
      plannedMeals: [
        ...state.plannedMeals,
        PlannedMeal(recipeId: recipeId, servings: servings, slot: slot),
      ],
    ));
    _persistPlan();
  }

  void removePlannedMeal(String id) {
    emit(state.copyWith(
      plannedMeals:
          state.plannedMeals.where((meal) => meal.id != id).toList(),
    ));
    _persistPlan();
  }

  void clearPlan() {
    emit(state.copyWith(plannedMeals: const <PlannedMeal>[]));
    _persistPlan();
  }

  // ---- Expiry notification bookkeeping ---------------------------------

  Set<String> get notifiedIds =>
      ExpiryMonitor.decode(_prefs.getString(_notifiedKey) ?? '[]');

  void saveNotifiedIds(Set<String> ids) =>
      _prefs.setString(_notifiedKey, ExpiryMonitor(ids).encode());

  List<ExpiryEntry> get expiryEntries => state.items
      .map(
        (item) => ExpiryEntry(
          id: item.id,
          name: item.name,
          expiry: item.expiry,
        ),
      )
      .toList();
}
