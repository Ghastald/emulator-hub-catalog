// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/router.dart';
import 'shared/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: EmulatorHubApp()));
}

class EmulatorHubApp extends StatelessWidget {
  const EmulatorHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Emulator Hub',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
