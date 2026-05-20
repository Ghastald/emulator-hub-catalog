// lib/core/services/github_service.dart
//
// Fetches the latest release tag from GitHub API.
// Results are cached per repo in shared_preferences to avoid rate-limiting.

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emulator.dart';

class GitHubRelease {
  final String tagName;
  final String publishedAt;
  final String releaseUrl;

  const GitHubRelease({
    required this.tagName,
    required this.publishedAt,
    required this.releaseUrl,
  });
}

class GitHubService {
  final Dio _dio;
  GitHubService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              headers: {'Accept': 'application/vnd.github+json'},
              receiveTimeout: const Duration(seconds: 8),
            ));

  Future<GitHubRelease?> getLatestRelease(GitHubSource source) async {
    final cacheKey = 'gh_release_${source.owner}_${source.repo}';
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _dio.get<Map<String, dynamic>>(source.apiUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final release = GitHubRelease(
          tagName: data['tag_name'] as String? ?? 'unknown',
          publishedAt: data['published_at'] as String? ?? '',
          releaseUrl: data['html_url'] as String? ?? source.releasesUrl,
        );
        // Cache the tag so we can show it offline
        await prefs.setString(cacheKey, release.tagName);
        return release;
      }
    } catch (_) {
      // Return cached tag if available
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        return GitHubRelease(
          tagName: cached,
          publishedAt: '',
          releaseUrl: source.releasesUrl,
        );
      }
    }
    return null;
  }
}
