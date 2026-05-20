// lib/core/services/providers.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safe_device/safe_device.dart';
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
  return ref.read(catalogServiceProvider).load(
    onNetworkError: (e) {
      Future.microtask(
          () => ref.read(catalogNetworkErrorProvider.notifier).state = e);
    },
  );
});

// ── Network error banner ──────────────────────────────────────────────────

final catalogNetworkErrorProvider = StateProvider<String?>((_) => null);

// ── Filter state ──────────────────────────────────────────────────────────

class CatalogFilter {
  final String query;
  final String? platform;
  const CatalogFilter({this.query = '', this.platform});

  CatalogFilter copyWith({String? query, String? platform}) =>
      CatalogFilter(query: query ?? this.query, platform: platform ?? this.platform);

  CatalogFilter withPlatform(String? p) =>
      CatalogFilter(query: query, platform: p);
}

final catalogFilterProvider = StateProvider((_) => const CatalogFilter());

final filteredCatalogProvider = Provider<AsyncValue<List<Emulator>>>((ref) {
  final catalog = ref.watch(catalogProvider);
  final filter  = ref.watch(catalogFilterProvider);
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
  final catalog  = await ref.watch(catalogProvider.future);
  final emulator = catalog.emulators.firstWhere((e) => e.id == emulatorId);
  if (emulator.sources.github == null) return null;
  return ref.read(githubServiceProvider).getLatestRelease(emulator.sources.github!);
});

// ── SAF saved folder URI per emulator ────────────────────────────────────

final savedFolderUriProvider =
    FutureProvider.family<String?, String>((ref, emulatorId) async {
  return ref.read(configServiceProvider).getSavedFolderUri(emulatorId);
});

// ── Root detection ────────────────────────────────────────────────────────

final isRootedProvider = FutureProvider<bool>((ref) async {
  try {
    return await SafeDevice.isJailBroken;
  } catch (_) {
    return false;
  }
});

// ── Imported profiles persistence ─────────────────────────────────────────

class ImportedProfileMeta {
  final String id;
  final String name;
  final String emulatorId;
  final String importedBasePath;
  final List<String> fileNames;

  const ImportedProfileMeta({
    required this.id,
    required this.name,
    required this.emulatorId,
    required this.importedBasePath,
    required this.fileNames,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emulator_id': emulatorId,
        'imported_base_path': importedBasePath,
        'file_names': fileNames,
      };

  factory ImportedProfileMeta.fromJson(Map<String, dynamic> j) =>
      ImportedProfileMeta(
        id: j['id'] as String,
        name: j['name'] as String,
        emulatorId: j['emulator_id'] as String,
        importedBasePath: j['imported_base_path'] as String,
        fileNames: List<String>.from(j['file_names'] ?? []),
      );

  ConfigProfile toConfigProfile() => ConfigProfile(
        id: id,
        name: name,
        description: 'Imported profile',
        files: fileNames.map((f) => ConfigFile(src: f, dest: f)).toList(),
        importedBasePath: importedBasePath,
      );
}

class ImportedProfilesNotifier
    extends AsyncNotifier<List<ImportedProfileMeta>> {
  static const _prefsKey = 'imported_profiles_v1';

  @override
  Future<List<ImportedProfileMeta>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((j) => ImportedProfileMeta.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(ImportedProfileMeta meta) async {
    final current = await future;
    final updated = [...current, meta];
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> remove(String profileId) async {
    final current = await future;
    final updated = current.where((m) => m.id != profileId).toList();
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> _persist(List<ImportedProfileMeta> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey, jsonEncode(list.map((m) => m.toJson()).toList()));
  }
}

final importedProfilesProvider = AsyncNotifierProvider<ImportedProfilesNotifier,
    List<ImportedProfileMeta>>(ImportedProfilesNotifier.new);
