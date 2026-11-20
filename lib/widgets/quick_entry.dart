import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/fridge_cubit.dart';
import '../services/quick_entry.dart';
import '../theme.dart';

/// A single-line, keyboard-first way to stock the fridge.
///
/// Examples it understands: `2 milk 3d`, `eggs x6 tomorrow`,
/// `spinach exp 2026-12-01`, `leftover pasta 1d`. Enter commits the item.
class QuickEntryBar extends StatefulWidget {
  const QuickEntryBar({super.key, required this.focusNode});

  final FocusNode focusNode;

  @override
  State<QuickEntryBar> createState() => _QuickEntryBarState();
}

class _QuickEntryBarState extends State<QuickEntryBar> {
  final _controller = TextEditingController();
  QuickEntry? _preview;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() => _preview = const QuickEntryParser().parse(value));
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final added = context.read<FridgeCubit>().addQuickEntry(text);
    if (added == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not understand that entry.')),
      );
      return;
    }
    _controller.clear();
    setState(() => _preview = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${added.summary}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            onChanged: _changed,
            onSubmitted: (_) => _submit(),
            textInputAction: TextInputAction.go,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.bolt_outlined,
                  size: 17, color: AppPalette.muted),
              hintText: 'Quick add — try "2 milk 3d"',
              suffixIcon: Tooltip(
                message: 'Press Enter to add',
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.keyboard_return,
                      size: 16, color: AppPalette.muted),
                ),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          if (_preview != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                _preview!.summary,
                style: AppText.bodyMuted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
