import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'screens/visor_screen.dart';

import 'providers/visor_provider.dart';
import 'services/app_config_service.dart';
import 'services/visor_config_service.dart';
import 'services/image_cache_service.dart';

import 'dart:io';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfigService().init();
  await VisorConfigService().init();
  await ImageCacheService().init();

  // Try to fetch latest config on startup, but don't block if it fails
  VisorConfigService().fetchAndSaveConfig().catchError((e) {
    debugPrint('Failed to fetch initial config: $e');
    return VisorConfigService().getConfig();
  });

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1366, 768),
      minimumSize: Size(1366, 768),
      center: true,
      title: 'Visor de Precios',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const VisorApp());
}

class VisorApp extends StatelessWidget {
  const VisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VisorProvider()..initialize(),
      child: MaterialApp(
        title: 'Visor de Precios',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.brandPrimary,
            brightness: Brightness.light,
            surface: AppColors.surface,
          ),
          fontFamily: 'OpenSans',
        ),
        home: const VisorScreen(),
      ),
    );
  }
}
