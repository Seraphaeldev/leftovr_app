import 'dart:io';

import '../models/fridge_item.dart';

/// Writes a plain JSON mirror of the inventory so the tiny CLI can read the
/// exact same data the app sees. Uses only `dart:io` — no packages, no network.
/// All failures are swallowed: persistence in SharedPreferences is canonical.
class InventoryFile {
  InventoryFile._();

  static String get directory {
    final override = Platform.environment['LEFTOVR_DATA_DIR'];
    if (override != null && override.isNotEmpty) return override;
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$home${Platform.pathSeparator}.leftovr';
  }

  static String get path => '$directory${Platform.pathSeparator}inventory.json';

  static Future<void> write(List<FridgeItem> items) async {
    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(FridgeItem.encodeList(items));
    } catch (_) {
      // A read-only home or a locked-down profile must never break the app.
    }
  }
}
