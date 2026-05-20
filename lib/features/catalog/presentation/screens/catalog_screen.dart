// lib/features/catalog/presentation/screens/catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/providers.dart';
import '../../../../shared/theme/app_theme.dart';
import '../widgets/emulator_card.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered      = ref.watch(filteredCatalogProvider);
    final filter        = ref.watch(catalogFilterProvider);
    final catalog       = ref.watch(catalogProvider);
    final networkError  = ref.watch(catalogNetworkErrorProvider);

    final allPlatforms = catalog.asData != null
        ? (catalog.asData!.value.emulators
            .expand((e) => e.platforms)
            .toSet()
            .toList()
          ..sort())
        : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emulator Hub'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Search emulators…',
              leading: const Icon(Icons.search, size: 18),
              backgroundColor: const WidgetStatePropertyAll(AppColors.card),
              shadowColor: const WidgetStatePropertyAll(Colors.transparent),
              onChanged: (q) => ref
                  .read(catalogFilterProvider.notifier)
                  .update((f) => f.copyWith(query: q)),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network error banner
          if (networkError != null)
            _NetworkErrorBanner(
              onDismiss: () =>
                  ref.read(catalogNetworkErrorProvider.notifier).state = null,
            ),

          // Platform filter chips
          if (allPlatforms.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: allPlatforms.map((p) {
                  final selected = filter.platform == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(p),
                      selected: selected,
                      onSelected: (_) => ref
                          .read(catalogFilterProvider.notifier)
                          .update((f) => f.withPlatform(selected ? null : p)),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Emulator list
          Expanded(
            child: filtered.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (emulators) => emulators.isEmpty
                  ? const Center(child: Text('No emulators found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: emulators.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => EmulatorCard(
                        emulator: emulators[i],
                        onTap: () => ctx.push('/emulator/${emulators[i].id}'),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkErrorBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _NetworkErrorBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) => MaterialBanner(
        content: const Text('Could not refresh catalog — showing cached data.'),
        leading: const Icon(Icons.cloud_off, size: 18),
        actions: [
          TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
        ],
      );
}
