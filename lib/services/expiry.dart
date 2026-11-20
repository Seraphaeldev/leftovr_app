import 'dart:convert';

/// The minimal facts the expiry monitor needs. Shared by the desktop app and
/// the CLI so both calculate freshness exactly the same way.
class ExpiryEntry {
  const ExpiryEntry({
    required this.id,
    required this.name,
    required this.expiry,
  });

  final String id;
  final String name;
  final DateTime expiry;

  int daysLeft([DateTime? now]) {
    final t = now ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final date = DateTime(expiry.year, expiry.month, expiry.day);
    return date.difference(today).inDays;
  }

  String get statusLabel {
    final days = daysLeft();
    if (days < 0) return 'EXPIRED';
    if (days <= 3) return 'USE SOON';
    return 'FRESH';
  }
}

/// A grouped batch of newly attention-worthy items.
class ExpiryAlert {
  const ExpiryAlert({
    required this.title,
    required this.detail,
    required this.count,
  });

  final String title;
  final String detail;
  final int count;
}

/// Zero-dependency expiry checking. The app runs this on a lightweight timer;
/// the CLI runs the exact same code over the mirrored inventory file.
class ExpiryMonitor {
  ExpiryMonitor([Set<String>? alreadyNotified])
      : _notified = alreadyNotified?.toSet() ?? <String>{};

  final Set<String> _notified;

  Set<String> get notified => Set<String>.from(_notified);

  /// Returns only alerts for items that crossed into "soon" or "expired"
  /// since the last check. Calling twice in a row yields no duplicate alerts.
  List<ExpiryAlert> check(List<ExpiryEntry> entries, {DateTime? now}) {
    final expired = <ExpiryEntry>[];
    final soon = <ExpiryEntry>[];

    for (final entry in entries) {
      final days = entry.daysLeft(now);
      if (days >= 0 && days > 3) {
        _notified.remove(entry.id);
        continue;
      }
      if (_notified.contains(entry.id)) continue;
      _notified.add(entry.id);
      (days < 0 ? expired : soon).add(entry);
    }

    final alerts = <ExpiryAlert>[];
    if (expired.isNotEmpty) {
      alerts.add(ExpiryAlert(
        title: '${expired.length} item(s) past their date',
        detail: expired.map((e) => e.name).take(3).join(', '),
        count: expired.length,
      ));
    }
    if (soon.isNotEmpty) {
      alerts.add(ExpiryAlert(
        title: '${soon.length} item(s) to use soon',
        detail: soon.map((e) => e.name).take(3).join(', '),
        count: soon.length,
      ));
    }
    return alerts;
  }

  String encode() => jsonEncode(_notified.toList()..sort());

  static Set<String> decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Plain-text report used by the CLI and by systemd/cron timers.
  static String report(List<ExpiryEntry> entries, {DateTime? now}) {
    final expired = <ExpiryEntry>[];
    final soon = <ExpiryEntry>[];
    for (final entry in entries) {
      final days = entry.daysLeft(now);
      if (days < 0) {
        expired.add(entry);
      } else if (days <= 3) {
        soon.add(entry);
      }
    }
    expired.sort((a, b) => a.daysLeft(now).compareTo(b.daysLeft(now)));
    soon.sort((a, b) => a.daysLeft(now).compareTo(b.daysLeft(now)));

    final buffer = StringBuffer()
      ..writeln('leftovr expiry report')
      ..writeln('=====================')
      ..writeln();

    if (expired.isEmpty && soon.isEmpty) {
      buffer.writeln('All good — nothing is expiring in the next 3 days.');
      return buffer.toString();
    }

    if (expired.isNotEmpty) {
      buffer.writeln('PAST DATE (${expired.length})');
      for (final entry in expired) {
        final days = -entry.daysLeft(now);
        buffer.writeln('  • ${entry.name} — $days day(s) ago');
      }
      buffer.writeln();
    }
    if (soon.isNotEmpty) {
      buffer.writeln('USE SOON (${soon.length})');
      for (final entry in soon) {
        final days = entry.daysLeft(now);
        final when = days == 0 ? 'today' : 'in $days day(s)';
        buffer.writeln('  • ${entry.name} — $when');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
