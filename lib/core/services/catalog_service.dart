// lib/core/services/catalog_service.dart
//
// Priority order:
//   1. Remote GitHub raw URL (fresh fetch, cached on success)
//   2. Cached version in shared_preferences (last successful fetch)
//   3. Bundled assets/catalog.json (always available, ships with app)

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emulator.dart';

const _kCatalogUrl =
    'https://raw.githubusercontent.com/Ghastald/emulator-hub-catalog/main/assets/catalog.json';
const _kCacheKey = 'catalog_json_cache';
const _kCacheTimeKey = 'catalog_cache_time';
const _kCacheTtlHours = 6;

class CatalogService {
  final Dio _dio;
  CatalogService({Dio? dio}) : _dio = dio ?? Dio();

  Future<EmulatorCatalog> load() async {
    // 1 — try remote
    try {
      final response = await _dio.get<String>(
        _kCatalogUrl,
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      if (response.statusCode == 200 && response.data != null) {
        await _cache(response.data!);
        return EmulatorCatalog.fromJson(jsonDecode(response.data!));
      }
    } catch (_) {
      // network unavailable — fall through
    }

    // 2 — try cache
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kCacheKey);
    if (cached != null) {
      return EmulatorCatalog.fromJson(jsonDecode(cached));
    }

    // 3 — bundled fallback
    final bundled = await rootBundle.loadString('assets/catalog.json');
    return EmulatorCatalog.fromJson(jsonDecode(bundled));
  }

  Future<void> _cache(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCacheKey, json);
    await prefs.setInt(_kCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isCacheStale() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_kCacheTimeKey);
    if (ts == null) return true;
    final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    return age.inHours >= _kCacheTtlHours;
  }
}
