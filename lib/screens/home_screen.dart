import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/fridge_cubit.dart';
import '../models/fridge_item.dart';
import '../services/expiry.dart';
import '../theme.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/decorations.dart';
import '../widgets/navigation_pane.dart';
import '../widgets/planning_pane.dart';
import '../widgets/quick_entry.dart';

Future<void> _addItem(BuildContext context) async {
  final item = await showAddItemDialog(context);
  if (item != null && context.mounted) {
    context.read<FridgeCubit>().addItem(item);
  }
}

// ---- Keyboard intents ----------------------------------------------------

class _FocusQuickIntent extends Intent {
  const _FocusQuickIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _ToggleThemeIntent extends Intent {
  const _ToggleThemeIntent();
}

class _AddIntent extends Intent {
  const _AddIntent();
}

class _ShortcutsHelpIntent extends Intent {
  const _ShortcutsHelpIntent();
}

/// The app root. The palette is resolved at build time by every widget below,
/// so a change must rebuild the whole page — rebuilding MaterialApp alone does
/// NOT rebuild widgets inside an existing Navigator route. Keying the page on
/// the theme guarantees a complete repaint.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FridgeCubit, FridgeState>(
      buildWhen: (a, b) => a.isDark != b.isDark,
      builder: (context, state) {
        AppPalette.brightness =
            state.isDark ? Brightness.dark : Brightness.light;
        return _HomeView(key: ValueKey(state.isDark));
      },
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView({super.key});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _quickFocus = FocusNode();
  final _searchFocus = FocusNode();
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    // Establish a quiet baseline on launch; later ticks surface new crossings
    // as real notifications without flooding the user with seed data.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExpiry(silent: true));
    _expiryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkExpiry(),
    );
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _quickFocus.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _checkExpiry({bool silent = false}) {
    if (!mounted) return;
    final cubit = context.read<FridgeCubit>();
    final monitor = ExpiryMonitor(cubit.notifiedIds);
    final alerts = monitor.check(cubit.expiryEntries);
    cubit.saveNotifiedIds(monitor.notified);
    if (silent || alerts.isEmpty) return;

    final alert = alerts.first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${alert.title} · ${alert.detail}'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const _FocusQuickIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
            const _FocusQuickIntent(),
        LogicalKeySet(LogicalKeyboardKey.slash): const _FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD):
            const _ToggleThemeIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyD):
            const _ToggleThemeIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const _AddIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
            const _AddIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.slash):
            const _ShortcutsHelpIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FocusQuickIntent: CallbackAction<_FocusQuickIntent>(
            onInvoke: (_) {
              _quickFocus.requestFocus();
              return null;
            },
          ),
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              _searchFocus.requestFocus();
              return null;
            },
          ),
          _ToggleThemeIntent: CallbackAction<_ToggleThemeIntent>(
            onInvoke: (_) {
              context.read<FridgeCubit>().toggleTheme();
              return null;
            },
          ),
          _AddIntent: CallbackAction<_AddIntent>(
            onInvoke: (_) {
              _addItem(context);
              return null;
            },
          ),
          _ShortcutsHelpIntent: CallbackAction<_ShortcutsHelpIntent>(
            onInvoke: (_) {
              _showShortcuts(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: AppPalette.background,
            body: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    quickFocus: _quickFocus,
                    onHelp: () => _showShortcuts(context),
                  ),
                  Expanded(child: _Workspace(searchFocus: _searchFocus)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showShortcuts(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Keyboard shortcuts', style: AppText.heading),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ctrl / ⌘ + K   — jump to quick add', style: AppText.body),
            SizedBox(height: 8),
            Text('/   — focus search', style: AppText.body),
            SizedBox(height: 8),
            Text('Ctrl / ⌘ + N   — new item', style: AppText.body),
            SizedBox(height: 8),
            Text('Ctrl / ⌘ + D   — light / dark', style: AppText.body),
            SizedBox(height: 8),
            Text('Ctrl / ⌘ + /   — this help', style: AppText.body),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ---- Three-pane workspace ------------------------------------------------

class _Workspace extends StatelessWidget {
  const _Workspace({required this.searchFocus});

  final FocusNode searchFocus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1000;
        final navWidth = compact ? 166.0 : 224.0;
        final planWidth = compact ? 282.0 : 348.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: navWidth, child: NavigationPane(searchFocus: searchFocus)),
              const VerticalDivider(width: 1),
              const Expanded(child: _Items()),
              const VerticalDivider(width: 1),
              SizedBox(width: planWidth, child: const PlanningPane()),
            ],
          ),
        );
      },
    );
  }
}

// ---- Toolbar -------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.quickFocus, required this.onHelp});

  final FocusNode quickFocus;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppPalette.glass,
        border: Border(bottom: BorderSide(color: AppPalette.line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                const TrayMark(size: 24),
                const SizedBox(width: 10),
                Text(
                  'leftovr',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: AppPalette.ink,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: QuickEntryBar(focusNode: quickFocus),
                  ),
                ),
                const SizedBox(width: 12),
                const _AlertBadge(),
                const SizedBox(width: 10),
                const _SortMenu(),
                const SizedBox(width: 10),
                const _ThemeToggle(),
                const SizedBox(width: 10),
                SoftIconButton(
                  icon: Icons.keyboard_outlined,
                  tooltip: 'Keyboard shortcuts',
                  size: 36,
                  onTap: onHelp,
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => _addItem(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  const _AlertBadge();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FridgeCubit, FridgeState>(
      buildWhen: (a, b) => a.items != b.items,
      builder: (context, state) {
        final count = state.count(ExpiryStatus.soon) +
            state.count(ExpiryStatus.expired);

        return PopupMenuButton<void>(
          tooltip: 'Notifications',
          padding: EdgeInsets.zero,
          color: AppPalette.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppPalette.line),
          ),
          offset: const Offset(0, 44),
          constraints: const BoxConstraints(minWidth: 320, maxWidth: 380),
          itemBuilder: (context) {
            // Recompute on open: an item can cross into "soon" or "expired"
            // purely from the passing date, with no inventory change to
            // rebuild this widget.
            final current = context.read<FridgeCubit>().state;
            final alerts = current.items
                .where((item) =>
                    item.status == ExpiryStatus.soon ||
                    item.status == ExpiryStatus.expired)
                .toList()
              ..sort((a, b) => a.expiry.compareTo(b.expiry));
            return [
              PopupMenuItem<void>(
                value: null,
                enabled: false,
                padding: EdgeInsets.zero,
                child: _NotificationPanel(alerts: alerts),
              ),
            ];
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: count == 0 ? AppPalette.surfaceSunken : AppPalette.ink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  count == 0
                      ? Icons.notifications_none_outlined
                      : Icons.notifications_active_outlined,
                  size: 16,
                  color: count == 0 ? AppPalette.ink : AppPalette.onInk,
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: AppText.value.copyWith(
                    fontSize: 12,
                    color: count == 0 ? AppPalette.ink : AppPalette.onInk,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The dropdown shown by the notification badge. Lists everything that is
/// past its date or close to it, newest expiry first, with a quiet empty state.
class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({required this.alerts});

  final List<FridgeItem> alerts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Text('Expiry alerts', style: AppText.title),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceSunken,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: AppText.badge.copyWith(color: AppPalette.muted),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 28, color: AppPalette.muted),
                  const SizedBox(height: 10),
                  Text('All good — nothing is expiring soon.',
                      style: AppText.bodyMuted),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: alerts.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                ),
                itemBuilder: (context, index) {
                  final item = alerts[index];
                  final statusColor = switch (item.status) {
                    ExpiryStatus.fresh => AppPalette.fresh,
                    ExpiryStatus.soon => AppPalette.soon,
                    ExpiryStatus.expired => AppPalette.expired,
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    child: Row(
                      children: [
                        Icon(item.category.icon,
                            size: 18, color: AppPalette.muted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: AppText.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(_ItemRow._daysLabel(item),
                                  style: AppText.bodyMuted),
                            ],
                          ),
                        ),
                        Text(
                          item.status.label,
                          style: AppText.badge.copyWith(color: statusColor),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FridgeCubit, FridgeState>(
      buildWhen: (a, b) => a.sort != b.sort,
      builder: (context, state) {
        return PopupMenuButton<String>(
          initialValue: state.sort,
          onSelected: (value) => context.read<FridgeCubit>().setSort(value),
          tooltip: 'Sort items',
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'expiry', child: Text('By expiry')),
            PopupMenuItem(value: 'name', child: Text('By name')),
            PopupMenuItem(value: 'qty', child: Text('By quantity')),
            PopupMenuItem(value: 'category', child: Text('By category')),
          ],
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppPalette.surfaceSunken,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_vert, size: 15, color: AppPalette.ink),
                const SizedBox(width: 6),
                Text(
                  'Sort',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppPalette.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FridgeCubit, FridgeState>(
      buildWhen: (a, b) => a.isDark != b.isDark,
      builder: (context, state) {
        return SoftIconButton(
          icon: state.isDark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          tooltip: state.isDark ? 'Switch to light' : 'Switch to dark',
          size: 36,
          onTap: () => context.read<FridgeCubit>().toggleTheme(),
        );
      },
    );
  }
}

// ---- Inventory pane ------------------------------------------------------

class _Items extends StatelessWidget {
  const _Items();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Items', style: AppText.heading),
            const Spacer(),
            BlocBuilder<FridgeCubit, FridgeState>(
              buildWhen: (a, b) => a.items != b.items,
              builder: (context, state) => Text(
                '${state.visible.length} shown',
                style: AppText.bodyMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: DecoratedBox(
              key: const ValueKey('inventory-card'),
              decoration: AppPalette.card(),
              child: BlocBuilder<FridgeCubit, FridgeState>(
                buildWhen: (a, b) =>
                    a.items != b.items ||
                    a.query != b.query ||
                    a.category != b.category ||
                    a.status != b.status ||
                    a.sort != b.sort ||
                    a.ready != b.ready,
                builder: (context, state) {
                  if (!state.ready) {
                    return Center(
                      child: Text('Getting things ready…',
                          style: AppText.bodyMuted),
                    );
                  }
                  if (state.items.isEmpty) {
                    return const _Empty(
                      title: 'Nothing here yet',
                      message: 'Add your first item to start tracking the fridge.',
                    );
                  }
                  final visible = state.visible;
                  if (visible.isEmpty) {
                    return const _Empty(
                      title: 'No matches',
                      message: 'Try another search or category.',
                    );
                  }

                  return ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.zero,
                    itemCount: visible.length + 1,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 22,
                      endIndent: 22,
                    ),
                    itemBuilder: (context, index) {
                      if (index == visible.length) {
                        return InkWell(
                          onTap: () => _addItem(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 17,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline,
                                    size: 18, color: AppPalette.muted),
                                const SizedBox(width: 10),
                                Text(
                                  'Add item',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppPalette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final item = visible[index];
                      return RepaintBoundary(
                        key: ValueKey(item.id),
                        child: _UpdateHighlight(
                          seq: state.changedId == item.id
                              ? state.changeSeq
                              : 0,
                          child: _ItemRow(
                            item: item,
                            onQuantity: (delta) => context
                                .read<FridgeCubit>()
                                .changeQuantity(item, delta),
                            onDelete: () => context
                                .read<FridgeCubit>()
                                .deleteItem(item.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

}

/// Briefly tints a row after its data changes so the update is easy to spot,
/// without moving it in the list or rebuilding anything around it.
class _UpdateHighlight extends StatefulWidget {
  const _UpdateHighlight({required this.seq, required this.child});

  final int seq;
  final Widget child;

  @override
  State<_UpdateHighlight> createState() => _UpdateHighlightState();
}

class _UpdateHighlightState extends State<_UpdateHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didUpdateWidget(covariant _UpdateHighlight old) {
    super.didUpdateWidget(old);
    if (widget.seq != old.seq) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          color:
              AppPalette.ink.withValues(alpha: (1 - _controller.value) * 0.06),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onQuantity,
    required this.onDelete,
  });

  final FridgeItem item;
  final ValueChanged<int> onQuantity;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    final statusColor = switch (status) {
      ExpiryStatus.fresh => AppPalette.fresh,
      ExpiryStatus.soon => AppPalette.soon,
      ExpiryStatus.expired => AppPalette.expired,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        // The status pill is a nicety, not essential — drop it when the middle
        // pane gets narrow so names and controls always fit.
        final showBadge = constraints.maxWidth >= 400;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppPalette.surfaceSunken,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  item.category.image,
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    item.category.icon,
                    size: 17,
                    color: AppPalette.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppText.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_title(item.category.label)}  ·  ${_daysLabel(item)}',
                      style: AppText.bodyMuted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _QuantityStepper(quantity: item.quantity, onQuantity: onQuantity),
              if (showBadge) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceSunken,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.label,
                    style: AppText.badge.copyWith(color: statusColor),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              SoftIconButton(
                icon: Icons.close,
                size: 26,
                tooltip: 'Remove ${item.name}',
                onTap: onDelete,
              ),
            ],
          ),
        );
      },
    );
  }

  static String _title(String value) =>
      value.isEmpty ? value : value[0] + value.substring(1).toLowerCase();

  static String _daysLabel(FridgeItem item) {
    final days = item.daysLeft;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Use today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onQuantity});

  final int quantity;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppPalette.surfaceSunken,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _step(Icons.remove, () => onQuantity(-1)),
          SizedBox(
            width: 24,
            child: Center(
              child:
                  Text('$quantity', style: AppText.value.copyWith(fontSize: 13)),
            ),
          ),
          _step(Icons.add, () => onQuantity(1)),
        ],
      ),
    );
  }

  Widget _step(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 13, color: AppPalette.ink),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: AppPalette.muted),
          const SizedBox(height: 18),
          Text(title, style: AppText.heading),
          const SizedBox(height: 8),
          Text(message, style: AppText.bodyMuted, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _addItem(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add item'),
          ),
        ],
      ),
    );
  }
}
