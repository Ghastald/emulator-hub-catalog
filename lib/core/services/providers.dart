// lib/core/services/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'catalog_service.dart';
import 'github_service.dart';
import 'config_service.dart';
import '../models/emulator.dart';

// ── Services ──────────────────────────────────────────────────────────────

final catalogServiceProvider = Provider((_) => CatalogService());
final githubServiceProvider  = Provider((_) => GitHubService());
final configServiceProvider  = Provider((_) => ConfigService());

// ── Catalog ───────────────────────────────────────────────────────────────

final catalogProvider = FutureProvider<EmulatorCatalog>((ref) async {
  return ref.read(catalogServiceProvider).load();
});

// ── Filter state ──────────────────────────────────────────────────────────

class CatalogFilter {
  final String query;
  final String? platform;
  const CatalogFilter({this.query = '', this.platform});
  CatalogFilter copyWith({String? query, String? platform}) =>
      CatalogFilter(query: query ?? this.query, platform: platform ?? this.platform);
}

final catalogFilterProvider = StateProvider((_) => const CatalogFilter());

final filteredCatalogProvider = Provider<AsyncValue<List<Emulator>>>((ref) {
  final catalog = ref.watch(catalogProvider);
  final filter = ref.watch(catalogFilterProvider);
  return catalog.whenData((c) {
    return c.emulators.where((e) {
      final matchesQuery = filter.query.isEmpty ||
          e.name.toLowerCase().contains(filter.query.toLowerCase()) ||
          e.tags.any((t) => t.toLowerCase().contains(filter.query.toLowerCase()));
      final matchesPlatform =
          filter.platform == null || e.platforms.contains(filter.platform);
      return matchesQuery && matchesPlatform;
    }).toList();
  });
});

// ── GitHub release cache (per emulator) ──────────────────────────────────

final githubReleaseProvider =
    FutureProvider.family<GitHubRelease?, String>((ref, emulatorId) async {
  final catalog = await ref.watch(catalogProvider.future);
  final emulator = catalog.emulators.firstWhere((e) => e.id == emulatorId);
  if (emulator.sources.github == null) return null;
  return ref.read(githubServiceProvider).getLatestRelease(emulator.sources.github!);
});

// ── Root detection ────────────────────────────────────────────────────────

final isRootedProvider = FutureProvider<bool>((ref) async {
  try {
    // flutter_jailbreak_detection returns true on rooted devices
    // import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
    // return await FlutterJailbreakDetection.jailbroken;
    //
    // Placeholder until package is wired in:
    return false;
  } catch (_) {
    return false;
  }
});
