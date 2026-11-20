import 'package:flutter/material.dart';

import '../models/fridge_item.dart';
import '../theme.dart';

/// Presents the add-item sheet with a gentle Apple-style scale and fade.
Future<FridgeItem?> showAddItemDialog(BuildContext context) {
  return showGeneralDialog<FridgeItem>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add item',
    barrierColor: AppPalette.scrim,
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const _AddItemDialog(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          ),
          child: child,
        ),
      );
    },
  );
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: 'pcs');
  final _notesController = TextEditingController();

  ItemCategory _category = ItemCategory.produce;
  late DateTime _expiry;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _expiry = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'USE-BY DATE',
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give it a name first');
      return;
    }
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final unit = _unitController.text.trim().isEmpty
        ? 'pcs'
        : _unitController.text.trim();

    Navigator.of(context).pop(
      FridgeItem(
        name: name,
        category: _category,
        quantity: quantity < 1 ? 1 : quantity,
        unit: unit,
        expiry: _expiry,
        notes: _notesController.text.trim(),
      ),
    );
  }

  Widget _field(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label.toUpperCase(), style: AppText.label),
        const SizedBox(height: 9),
        child,
      ],
    );
  }

  Widget _categoryChip(ItemCategory category, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _category = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppPalette.ink : AppPalette.surfaceSunken,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 14,
              color: selected ? AppPalette.onInk : AppPalette.inkSoft,
            ),
            const SizedBox(width: 7),
            Text(
              _title(category.label),
              style: AppText.chip.copyWith(
                color: selected ? AppPalette.onInk : AppPalette.inkSoft,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height - 80,
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('NEW ITEM', style: AppText.label),
                const SizedBox(height: 8),
                Text('Add to fridge', style: AppText.heading),
                const SizedBox(height: 6),
                Text(
                  'It will appear in your inventory right away.',
                  style: AppText.bodyMuted,
                ),
                const SizedBox(height: 26),
                const Divider(height: 1),
                const SizedBox(height: 24),

                _field(
                  'Name',
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. Greek yogurt',
                      errorText: _nameError,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                _field(
                  'Category',
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ItemCategory.values
                        .map((category) =>
                            _categoryChip(category, category == _category))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _field(
                        'Quantity',
                        TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '1'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: _field(
                        'Unit',
                        TextField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            hintText: 'pcs / L / pack',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                _field(
                  'Use by',
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        suffixIcon:
                            Icon(Icons.calendar_today_outlined, size: 18),
                      ),
                      child: Text(
                        _formatDate(_expiry),
                        style: AppText.value.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                _field(
                  'Notes (optional)',
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Anything worth remembering',
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                const Divider(height: 1),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Add item'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _title(String value) =>
      value[0] + value.substring(1).toLowerCase();

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}
