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
    final filtered = ref.watch(filteredCatalogProvider);
    final filter = ref.watch(catalogFilterProvider);

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
      body: filtered.when(
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
    );
  }
}
