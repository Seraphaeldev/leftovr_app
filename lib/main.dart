import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cubit/fridge_cubit.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(LeftovrApp(prefs: prefs));
}

class LeftovrApp extends StatelessWidget {
  const LeftovrApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FridgeCubit(prefs)..load(),
      child: BlocBuilder<FridgeCubit, FridgeState>(
        buildWhen: (a, b) => a.isDark != b.isDark,
        builder: (context, state) {
          // The palette is resolved from this value at build time throughout
          // the tree; rebuilding MaterialApp repaints the whole app in the new
          // monochrome variant.
          AppPalette.brightness =
              state.isDark ? Brightness.dark : Brightness.light;
          final overlay = state.isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay.copyWith(statusBarColor: AppPalette.background),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'leftovr',
              theme: buildTheme(),
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
