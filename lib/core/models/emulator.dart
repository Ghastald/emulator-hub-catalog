// lib/core/models/emulator.dart

class EmulatorSource {
  final GitHubSource? github;
  final PlayStoreSource? playStore;

  const EmulatorSource({this.github, this.playStore});

  factory EmulatorSource.fromJson(Map<String, dynamic> j) => EmulatorSource(
        github: j['github'] != null ? GitHubSource.fromJson(j['github']) : null,
        playStore: j['play_store'] != null ? PlayStoreSource.fromJson(j['play_store']) : null,
      );
}

class GitHubSource {
  final String owner;
  final String repo;
  final String assetPattern;

  const GitHubSource({required this.owner, required this.repo, required this.assetPattern});

  factory GitHubSource.fromJson(Map<String, dynamic> j) => GitHubSource(
        owner: j['owner'] as String,
        repo: j['repo'] as String,
        assetPattern: j['asset_pattern'] as String,
      );

  String get releasesUrl => 'https://github.com/$owner/$repo/releases/latest';
  String get apiUrl => 'https://api.github.com/repos/$owner/$repo/releases/latest';
}

class PlayStoreSource {
  final String packageId;

  const PlayStoreSource({required this.packageId});

  factory PlayStoreSource.fromJson(Map<String, dynamic> j) =>
      PlayStoreSource(packageId: j['package_id'] as String);

  String get storeUrl => 'https://play.google.com/store/apps/details?id=$packageId';
  String get marketUri => 'market://details?id=$packageId';
}

class ConfigProfile {
  final String id;
  final String name;
  final String description;
  final List<ConfigFile> files;

  // null = bundled asset; non-null = user-imported absolute path
  final String? importedBasePath;

  const ConfigProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.files,
    this.importedBasePath,
  });

  bool get isBundled => importedBasePath == null;

  factory ConfigProfile.fromJson(Map<String, dynamic> j) => ConfigProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        files: (j['files'] as List).map((f) => ConfigFile.fromJson(f)).toList(),
      );

  ConfigProfile copyWithImportedPath(String basePath) => ConfigProfile(
        id: id,
        name: name,
        description: description,
        files: files,
        importedBasePath: basePath,
      );
}

class ConfigFile {
  final String src;  // assets/... path OR absolute path if imported
  final String dest; // relative filename within the emulator's config folder

  const ConfigFile({required this.src, required this.dest});

  factory ConfigFile.fromJson(Map<String, dynamic> j) =>
      ConfigFile(src: j['src'] as String, dest: j['dest'] as String);
}

class EmulatorConfig {
  final bool supported;
  final String format;       // cfg | ini | json
  final String targetPathHint;
  final List<ConfigProfile> profiles;

  const EmulatorConfig({
    required this.supported,
    required this.format,
    required this.targetPathHint,
    required this.profiles,
  });

  factory EmulatorConfig.fromJson(Map<String, dynamic> j) => EmulatorConfig(
        supported: j['supported'] as bool,
        format: j['format'] as String,
        targetPathHint: j['target_path_hint'] as String,
        profiles: (j['profiles'] as List? ?? [])
            .map((p) => ConfigProfile.fromJson(p))
            .toList(),
      );
}

class Emulator {
  final String id;
  final String name;
  final String description;
  final List<String> platforms;
  final List<String> tags;
  final String? iconUrl;
  final EmulatorSource sources;
  final EmulatorConfig? config;

  const Emulator({
    required this.id,
    required this.name,
    required this.description,
    required this.platforms,
    required this.tags,
    this.iconUrl,
    required this.sources,
    this.config,
  });

  factory Emulator.fromJson(Map<String, dynamic> j) => Emulator(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        platforms: List<String>.from(j['platforms'] ?? []),
        tags: List<String>.from(j['tags'] ?? []),
        iconUrl: j['icon_url'] as String?,
        sources: EmulatorSource.fromJson(j['sources']),
        config: j['config'] != null ? EmulatorConfig.fromJson(j['config']) : null,
      );
}

class EmulatorCatalog {
  final String version;
  final String updatedAt;
  final List<Emulator> emulators;

  const EmulatorCatalog({
    required this.version,
    required this.updatedAt,
    required this.emulators,
  });

  factory EmulatorCatalog.fromJson(Map<String, dynamic> j) => EmulatorCatalog(
        version: j['catalog_version'] as String,
        updatedAt: j['updated_at'] as String,
        emulators: (j['emulators'] as List).map((e) => Emulator.fromJson(e)).toList(),
      );
}
