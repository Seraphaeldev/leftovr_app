//! leftovr expiry report — a zero-bloat CLI for cron / systemd timers.
//!
//!   dart run bin/expiry.dart
//!   dart run bin/expiry.dart --json
//!
//! Reads the local JSON mirror written by the desktop app. Nothing is sent
//! anywhere; no daemon, no notification library, no network.

import 'dart:convert';
import 'dart:io';

import 'package:leftovr/services/expiry.dart';

void main(List<String> args) {
  final file = File(_path());
  if (!file.existsSync()) {
    stderr.writeln(
      'No inventory mirror found at ${file.path}.\n'
      'Open leftovr once so it can create the file.',
    );
    exitCode = 1;
    return;
  }

  List<ExpiryEntry> entries;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) throw const FormatException('Not a list');
    entries = decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => ExpiryEntry(
            id: json['id'] as String? ?? '',
            name: json['name'] as String? ?? 'Item',
            expiry: DateTime.tryParse(json['expiry'] as String? ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();
  } catch (error) {
    stderr.writeln('Could not read inventory mirror: $error');
    exitCode = 1;
    return;
  }

  if (args.contains('--json')) {
    stdout.writeln(jsonEncode(
      entries
          .where((e) => e.daysLeft() <= 3)
          .map(
            (e) => {
              'name': e.name,
              'status': e.statusLabel,
              'daysLeft': e.daysLeft(),
            },
          )
          .toList(),
    ));
    return;
  }

  stdout.write(ExpiryMonitor.report(entries));
}

String _path() {
  final override = Platform.environment['LEFTOVR_DATA_DIR'];
  if (override != null && override.isNotEmpty) {
    return '$override${Platform.pathSeparator}inventory.json';
  }
  final home = Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '.';
  return '$home${Platform.pathSeparator}.leftovr${Platform.pathSeparator}inventory.json';
}
