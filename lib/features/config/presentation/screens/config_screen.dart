// lib/features/config/presentation/screens/config_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/emulator.dart';
import '../../../../core/services/providers.dart';
import '../../../../core/services/config_service.dart';
import '../../../../shared/theme/app_theme.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  final String emulatorId;
  const ConfigScreen({super.key, required this.emulatorId});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  bool _pushing = false;
  String? _lastResult;

  Future<void> _pushProfile(ConfigProfile profile, bool isRooted) async {
    setState(() { _pushing = true; _lastResult = null; });

    final service = ref.read(configServiceProvider);
    final result = await service.pushProfile(
      emulatorId: widget.emulatorId,
      profile: profile,
      isRooted: isRooted,
    );

    setState(() {
      _pushing = false;
      _lastResult = result.success
          ? 'Pushed ${result.copiedFiles.length} file(s) successfully.'
          : 'Error: ${result.error}';
    });
  }

  Future<void> _importProfile(Emulator emulator) async {
    final nameController = TextEditingController(text: 'My custom profile');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pick files')),
        ],
      ),
    );
    if (confirmed != true) return;

    final service = ref.read(configServiceProvider);
    final imported = await service.importProfile(
      emulatorId: widget.emulatorId,
      profileName: nameController.text,
    );

    if (imported != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported "${imported.name}" (${imported.files.length} files)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final isRooted = ref.watch(isRootedProvider).valueOrNull ?? false;

    return catalog.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (c) {
        final emulator = c.emulators.firstWhere((e) => e.id == widget.emulatorId);
        final cfg = emulator.config;

        if (cfg == null || !cfg.supported) {
          return Scaffold(
            appBar: AppBar(title: Text('${emulator.name} — config')),
            body: const Center(child: Text('No config support for this emulator.')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text('${emulator.name} — config')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Root/SAF status banner
              _StatusBanner(isRooted: isRooted, emulatorId: widget.emulatorId),
              const SizedBox(height: 20),

              if (_lastResult != null)
                _ResultBanner(message: _lastResult!),

              Text('Bundled profiles',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...cfg.profiles.map((p) => _ProfileTile(
                    profile: p,
                    isRooted: isRooted,
                    pushing: _pushing,
                    onPush: () => _pushProfile(p, isRooted),
                  )),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _importProfile(emulator),
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Import custom profile'),
              ),
              const SizedBox(height: 8),
              Text(
                'Target folder: ${cfg.targetPathHint}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBanner extends ConsumerWidget {
  final bool isRooted;
  final String emulatorId;
  const _StatusBanner({required this.isRooted, required this.emulatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isRooted ? AppColors.amber : AppColors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: (isRooted ? AppColors.amber : AppColors.green).withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(isRooted ? Icons.lock_open : Icons.folder_open,
            color: isRooted ? AppColors.amber : AppColors.green, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isRooted
                ? 'Rooted device — files will be written directly via shell.'
                : 'Non-rooted — you will be asked to select the target folder once per emulator.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ]),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final ConfigProfile profile;
  final bool isRooted;
  final bool pushing;
  final VoidCallback onPush;

  const _ProfileTile({
    required this.profile,
    required this.isRooted,
    required this.pushing,
    required this.onPush,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(profile.description,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text('${profile.files.length} file(s)',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: pushing ? null : onPush,
              child: pushing
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Push'),
            ),
          ]),
        ),
      );
}

class _ResultBanner extends StatelessWidget {
  final String message;
  const _ResultBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final isError = message.startsWith('Error');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? Colors.red : AppColors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: (isError ? Colors.red : AppColors.green).withOpacity(0.3)),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
