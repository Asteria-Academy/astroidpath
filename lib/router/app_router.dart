// lib/router/app_router.dart
import 'package:flutter/material.dart';

// === Import halamanmu ===
import '../screens/splash_gate.dart';
import '../screens/home_screen.dart';
import '../screens/draw_path.dart';
// import '../screens/settings_page.dart';

/// Kumpulan nama route supaya konsisten & mudah diubah
class AppRoutes {
  static const splash = '/splash';
  static const home = '/home';
  static const settings = '/settings';
  static const drawPath = '/draw-path';
}

/// Router utama: hubungkan name → page
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return _page(const SplashGate());

    case AppRoutes.home:
      return _page(const HomeScreen());

    case AppRoutes.drawPath:
      final args = settings.arguments as DrawPathScreenArgs?;
      return MaterialPageRoute(
        builder: (_) => DrawPathScreen(initialArgs: args),
        settings: settings,
      );

    default:
      return _notFound(settings.name);
  }
}

/// Helper bikin MaterialPageRoute singkat
MaterialPageRoute _page(Widget child) =>
    MaterialPageRoute(builder: (_) => child);

/// Route not found
Route<dynamic> _notFound(String? name) =>
    MaterialPageRoute(builder: (_) => const HomeScreen());
