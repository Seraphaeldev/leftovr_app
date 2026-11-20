import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// A quiet white surface with soft, layered shadow — the basic Apple card.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 26,
    this.fill,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppPalette.card(fill: fill, radius: radius),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Backwards-compatible name used by older call sites.
class BentoCard extends AppCard {
  const BentoCard({
    super.key,
    required super.child,
    super.padding,
    super.radius,
    super.fill,
  });
}

/// The leftovr mark: the monochrome tray from artwork/icon.svg, drawn in the
/// current ink colour so it reads in both light and dark themes.
class TrayMark extends StatelessWidget {
  const TrayMark({
    super.key,
    required this.size,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TrayPainter(color ?? AppPalette.ink)),
    );
  }
}

class _TrayPainter extends CustomPainter {
  const _TrayPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 128;
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    // Tray body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(28 * s, 6 * s, 72 * s, 116 * s),
        Radius.circular(18 * s),
      ),
      ink,
    );

    // Divider beneath the two dots.
    canvas.drawLine(
      Offset(31 * s, 42 * s),
      Offset(97 * s, 42 * s),
      ink,
    );

    // Handle dots and the two indicator pills.
    canvas.drawCircle(Offset(48 * s, 23 * s), 5 * s, fill);
    canvas.drawCircle(Offset(68 * s, 23 * s), 5 * s, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(84 * s, 18 * s, 6 * s, 12 * s),
        Radius.circular(3 * s),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(84 * s, 52 * s, 6 * s, 14 * s),
        Radius.circular(3 * s),
      ),
      fill,
    );

    // The smile.
    canvas.drawPath(
      Path()
        ..moveTo(46 * s, 84 * s)
        ..quadraticBezierTo(64 * s, 104 * s, 82 * s, 84 * s),
      ink,
    );
  }

  @override
  bool shouldRepaint(covariant _TrayPainter old) => color != old.color;
}

/// Three concentric rings in the spirit of Apple's activity rings, rendered
/// in shades of black and grey.
class FreshnessRings extends StatelessWidget {
  const FreshnessRings({
    super.key,
    required this.fresh,
    required this.soon,
    required this.expired,
    this.size = 132,
  });

  final double fresh;
  final double soon;
  final double expired;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingsPainter(fresh: fresh, soon: soon, expired: expired),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({
    required this.fresh,
    required this.soon,
    required this.expired,
  });

  final double fresh;
  final double soon;
  final double expired;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = min(size.width, size.height);
    final values = [fresh, soon, expired];
    final colors = [
      AppPalette.fresh,
      AppPalette.soon,
      AppPalette.expired,
    ];

    for (var i = 0; i < 3; i++) {
      final radius = base / 2 - 5 - i * (base * 0.135);
      final stroke = (base * 0.075).clamp(5.0, 11.0);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final track = Paint()
        ..color = AppPalette.surfaceSunken
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -pi / 2, 2 * pi, false, track);

      final fraction = values[i].clamp(0.0, 1.0);
      if (fraction > 0) {
        canvas.drawArc(
          rect,
          -pi / 2,
          2 * pi * fraction,
          false,
          Paint()
            ..color = colors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      fresh != old.fresh || soon != old.soon || expired != old.expired;
}

/// A pill-shaped, springy icon button used across the toolbar and cards.
class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 34,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: filled ? AppPalette.ink : AppPalette.surfaceSunken,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: 16,
            color: filled ? AppPalette.onInk : AppPalette.ink,
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
