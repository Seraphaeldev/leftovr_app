import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/fridge_cubit.dart';
import '../theme.dart';
import 'home_screen.dart';

/// Smoothstep between [a] and [b] — shared by the animation and its painter.
double _smoothstep(double a, double b, double t) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  final x = (t - a) / (b - a);
  return x * x * (3 - 2 * x);
}

/// A pure-white splash: a faint matrix of dots breathes, then the word
/// "leftovr" materialises out of it in a rhythmic wave and settles into bold
/// black type. Tap anywhere to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _name = 'leftovr';

  late final AnimationController _controller;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_leaving || !mounted) return;
    _leaving = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _controller.value;

    // The whole matrix eases in, holds, then gives way to the app.
    final appear = _smoothstep(0, 0.12, t);
    final exit = 1 - _smoothstep(0.90, 1.0, t);
    final opacity = (appear * exit).clamp(0.0, 1.0);

    // Once formed, the word shrinks a touch into its final resting place.
    final settle = _smoothstep(0.70, 0.90, t);
    final scale = 1.04 - 0.04 * settle;

    return BlocBuilder<FridgeCubit, FridgeState>(
      buildWhen: (a, b) => a.isDark != b.isDark,
      builder: (context, state) {
        AppPalette.brightness =
            state.isDark ? Brightness.dark : Brightness.light;
        return Scaffold(
          key: ValueKey(state.isDark),
          backgroundColor: AppPalette.background,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _finish,
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 430,
                      height: 110,
                      child: DotMatrixText(text: _name, progress: t),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Renders [text] in a 5x7 dot matrix. A faint grid of dots breathes
/// rhythmically while a scanning wave materialises the letters in bold black;
/// the remaining grid dots then fade away, leaving the settled word.
class DotMatrixText extends StatefulWidget {
  const DotMatrixText({
    super.key,
    required this.text,
    required this.progress,
    this.color,
  });

  final String text;
  final double progress;
  final Color? color;

  @override
  State<DotMatrixText> createState() => _DotMatrixTextState();
}

class _DotMatrixTextState extends State<DotMatrixText>
    with SingleTickerProviderStateMixin {
  /// A free-running clock gives the grid its gentle rhythmic pulse even when
  /// [progress] is held still (such as at the end of the splash).
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => CustomPaint(
        painter: _DotMatrixPainter(
          text: widget.text,
          progress: widget.progress,
          pulse: _pulse.value,
          color: widget.color ?? AppPalette.ink,
        ),
      ),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  const _DotMatrixPainter({
    required this.text,
    required this.progress,
    required this.pulse,
    required this.color,
  });

  static const _font = <String, List<String>>{
    'l': [
      '10000', '10000', '10000', '10000', '10000', '10000', '11111',
    ],
    'e': [
      '00000', '01110', '10001', '11111', '10000', '10001', '01110',
    ],
    'f': [
      '00111', '00010', '00010', '11111', '00010', '00010', '00010',
    ],
    't': [
      '00010', '00010', '11111', '00010', '00010', '00010', '00111',
    ],
    'o': [
      '00000', '01110', '10001', '10001', '10001', '10001', '01110',
    ],
    'v': [
      '10001', '10001', '10001', '10001', '10001', '01010', '00100',
    ],
    'r': [
      '00000', '10110', '11001', '10000', '10000', '10000', '10000',
    ],
  };

  static const _colsPerGlyph = 5;
  static const _rows = 7;
  static const _glyphGap = 2;
  static const _padX = 3;
  static const _padY = 3;

  final String text;
  final double progress;
  final double pulse;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final chars = text.toLowerCase().split('');
    final textCols =
        chars.length * _colsPerGlyph + (chars.length - 1) * _glyphGap;
    final gridCols = textCols + _padX * 2;
    final gridRows = _rows + _padY * 2;

    final cell = min(size.width / gridCols, size.height / gridRows);
    final startX = (size.width - gridCols * cell) / 2;
    final startY = (size.height - gridRows * cell) / 2;

    // Map every grid cell to whether it belongs to a glyph.
    final letter = List.generate(
      gridCols,
      (_) => List<bool>.filled(gridRows, false),
    );
    for (var ci = 0; ci < chars.length; ci++) {
      final glyph = _font[chars[ci]];
      if (glyph == null) continue;
      for (var r = 0; r < _rows; r++) {
        for (var c = 0; c < _colsPerGlyph; c++) {
          if (glyph[r][c] == '1') {
            letter[_padX + ci * (_colsPerGlyph + _glyphGap) + c]
                [_padY + r] = true;
          }
        }
      }
    }

    final p = progress.clamp(0.0, 1.0);
    // Scan front travels from just before the first column to past the last.
    final front = -0.12 + _smoothstep(0.08, 0.64, p) * 1.24;
    // The surrounding grid vanishes once the word has formed.
    final fieldOut = 1 - _smoothstep(0.58, 0.82, p);

    for (var gx = 0; gx < gridCols; gx++) {
      final cx = gx / (gridCols - 1);
      final dx = front - cx;
      for (var gy = 0; gy < gridRows; gy++) {
        final x = startX + gx * cell + cell / 2;
        final y = startY + gy * cell + cell / 2;

        if (letter[gx][gy]) {
          final reveal = (dx / 0.14).clamp(0.0, 1.0);
          if (reveal <= 0) continue;
          final e = _smoothstep(0, 1, reveal);
          // A small swell at the moment each dot ignites.
          final pop = sin(reveal * pi) * 0.10;
          canvas.drawCircle(
            Offset(x, y),
            cell * (0.30 + 0.18 * e + pop),
            Paint()..color = color.withValues(alpha: e),
          );
        } else {
          // Rhythmic breathing plus a brief brightening as the scan passes.
          final rhythm = 0.5 + 0.5 * sin(pulse * 2 * pi + gx * 0.55 + gy * 0.7);
          final glow = (1 - (dx.abs() / 0.09)).clamp(0.0, 1.0);
          final alpha = (0.05 + 0.03 * rhythm + 0.16 * glow) * fieldOut;
          if (alpha <= 0.003) continue;
          canvas.drawCircle(
            Offset(x, y),
            cell * 0.15,
            Paint()..color = color.withValues(alpha: alpha),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotMatrixPainter old) =>
      text != old.text ||
      progress != old.progress ||
      pulse != old.pulse ||
      color != old.color;
}
