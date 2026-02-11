import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'core/app_colors.dart';
import 'screens/visor_screen.dart';

import 'providers/visor_provider.dart';
import 'services/app_config_service.dart';
import 'services/hardware_scanner_service.dart';
import 'services/visor_config_service.dart';
import 'services/image_cache_service.dart';

import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfigService().init();
  await VisorConfigService().init();
  await ImageCacheService().init();
  await HardwareScannerService.init();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    if (Platform.isWindows) {
      await flutter_acrylic.Window.initialize();
      await flutter_acrylic.Window.hideWindowControls();
    }

    await windowManager.ensureInitialized();

    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setMinimumSize(const Size(800, 600));

    windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.maximize();
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
    return Sizer(
      builder: (context, orientation, deviceType) {
        return ChangeNotifierProvider(
          create: (_) => VisorProvider()..initialize(),
          child: MaterialApp(
            title: 'TheosVisor',
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
      },
    );
  }
}
