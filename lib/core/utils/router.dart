// lib/core/utils/router.dart

import 'package:go_router/go_router.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/detail/presentation/screens/detail_screen.dart';
import '../../features/config/presentation/screens/config_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const CatalogScreen(),
    ),
    GoRoute(
      path: '/emulator/:id',
      builder: (_, state) => DetailScreen(emulatorId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/emulator/:id/config',
      builder: (_, state) => ConfigScreen(emulatorId: state.pathParameters['id']!),
    ),
  ],
);
