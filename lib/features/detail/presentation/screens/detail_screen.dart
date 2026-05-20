// lib/features/detail/presentation/screens/detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/providers.dart';
import '../../../../shared/theme/app_theme.dart';

class DetailScreen extends ConsumerWidget {
  final String emulatorId;
  const DetailScreen({super.key, required this.emulatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final release = ref.watch(githubReleaseProvider(emulatorId));

    return catalog.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (c) {
        final emulator = c.emulators.firstWhere((e) => e.id == emulatorId);

        return Scaffold(
          appBar: AppBar(title: Text(emulator.name)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Version badge
              release.when(
                data: (r) => r != null
                    ? _Badge(label: r.tagName, color: AppColors.green)
                    : const SizedBox.shrink(),
                loading: () => const _Badge(label: 'Fetching…', color: AppColors.muted),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Text(emulator.description,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: emulator.tags.map((t) => Chip(label: Text(t))).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text('Get it', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (emulator.sources.github != null)
                _LinkButton(
                  icon: Icons.code,
                  label: 'GitHub releases',
                  url: emulator.sources.github!.releasesUrl,
                ),
              if (emulator.sources.playStore != null)
                _LinkButton(
                  icon: Icons.shop_outlined,
                  label: 'Play Store',
                  url: emulator.sources.playStore!.storeUrl,
                  fallbackUri: emulator.sources.playStore!.marketUri,
                ),
              if (emulator.config?.supported == true) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push('/emulator/$emulatorId/config'),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Manage config profiles'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      );
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final String? fallbackUri;

  const _LinkButton(
      {required this.icon, required this.label, required this.url, this.fallbackUri});

  Future<void> _launch() async {
    if (fallbackUri != null) {
      final market = Uri.parse(fallbackUri!);
      if (await canLaunchUrl(market)) {
        await launchUrl(market);
        return;
      }
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: _launch,
          icon: Icon(icon, size: 16),
          label: Text(label),
        ),
      );
}
