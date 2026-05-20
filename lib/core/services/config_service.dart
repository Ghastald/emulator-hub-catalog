// lib/core/services/config_service.dart
//
// Handles writing config profile files to the target emulator folder.
//
// Two paths:
//   • No root  → Storage Access Framework (SAF). User picks folder once;
//                URI is persisted in shared_preferences and reused.
//   • Root     → Shell `cp` via `su -c`, no picker needed.
//
// Imported profiles are stored in getApplicationDocumentsDirectory()
// under profiles/<emulator_id>/<profile_id>/.

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emulator.dart';

class ConfigPushResult {
  final bool success;
  final List<String> copiedFiles;
  final String? error;

  const ConfigPushResult({required this.success, this.copiedFiles = const [], this.error});
}

class ConfigService {
  // ── SAF folder grant ──────────────────────────────────────────────────────

  String _safKey(String emulatorId) => 'saf_uri_$emulatorId';

  Future<String?> getSavedFolderUri(String emulatorId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_safKey(emulatorId));
  }

  Future<String?> pickAndSaveFolderUri(String emulatorId) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_safKey(emulatorId), result);
    return result;
  }

  Future<void> clearFolderUri(String emulatorId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_safKey(emulatorId));
  }

  // ── Push a profile ────────────────────────────────────────────────────────

  Future<ConfigPushResult> pushProfile({
    required String emulatorId,
    required ConfigProfile profile,
    required bool isRooted,
    String? targetFolderPath, // pre-supplied for root path; null = use SAF grant
  }) async {
    final copied = <String>[];

    if (isRooted && targetFolderPath != null) {
      return _pushViaRoot(profile, targetFolderPath, copied);
    }

    // SAF path
    final folderPath = targetFolderPath ??
        await getSavedFolderUri(emulatorId) ??
        await pickAndSaveFolderUri(emulatorId);

    if (folderPath == null) {
      return const ConfigPushResult(success: false, error: 'No folder selected.');
    }

    return _pushViaSaf(profile, folderPath, copied);
  }

  Future<ConfigPushResult> _pushViaSaf(
      ConfigProfile profile, String folderPath, List<String> copied) async {
    try {
      for (final f in profile.files) {
        final bytes = await _readProfileFile(profile, f);
        final dest = File('$folderPath/${f.dest}');
        await dest.parent.create(recursive: true);
        await dest.writeAsBytes(bytes);
        copied.add(f.dest);
      }
      return ConfigPushResult(success: true, copiedFiles: copied);
    } catch (e) {
      return ConfigPushResult(success: false, copiedFiles: copied, error: e.toString());
    }
  }

  Future<ConfigPushResult> _pushViaRoot(
      ConfigProfile profile, String targetPath, List<String> copied) async {
    try {
      // Write files to app temp dir first, then cp as root
      final tmp = await getTemporaryDirectory();
      for (final f in profile.files) {
        final bytes = await _readProfileFile(profile, f);
        final tmpFile = File('${tmp.path}/${f.dest}');
        await tmpFile.writeAsBytes(bytes);

        final result = await Process.run('su', ['-c', 'cp "${tmpFile.path}" "$targetPath/${f.dest}"']);
        if (result.exitCode != 0) {
          return ConfigPushResult(
              success: false,
              copiedFiles: copied,
              error: 'Root cp failed for ${f.dest}: ${result.stderr}');
        }
        copied.add(f.dest);
      }
      return ConfigPushResult(success: true, copiedFiles: copied);
    } on ProcessException catch (e) {
      return ConfigPushResult(
          success: false,
          copiedFiles: copied,
          error: 'Root write failed: ${e.message}');
    } catch (e) {
      return ConfigPushResult(success: false, copiedFiles: copied, error: e.toString());
    }
  }

  Future<List<int>> _readProfileFile(ConfigProfile profile, ConfigFile f) async {
    if (profile.isBundled) {
      final data = await rootBundle.load(f.src);
      return data.buffer.asUint8List();
    } else {
      return File('${profile.importedBasePath}/${f.src}').readAsBytes();
    }
  }

  // ── Import a custom profile ───────────────────────────────────────────────

  Future<ConfigProfile?> importProfile({
    required String emulatorId,
    required String profileName,
  }) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final profileId = 'imported_${DateTime.now().millisecondsSinceEpoch}';
    final destDir = Directory('${docsDir.path}/profiles/$emulatorId/$profileId');
    await destDir.create(recursive: true);

    final files = <ConfigFile>[];
    for (final picked in result.files) {
      if (picked.path == null) continue;
      final src = File(picked.path!);
      final destFile = File('${destDir.path}/${picked.name}');
      await src.copy(destFile.path);
      files.add(ConfigFile(src: picked.name, dest: picked.name));
    }

    return ConfigProfile(
      id: profileId,
      name: profileName,
      description: 'Imported ${DateTime.now().toLocal()}',
      files: files,
      importedBasePath: destDir.path,
    );
  }
}
