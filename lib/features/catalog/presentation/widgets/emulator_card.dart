// lib/features/catalog/presentation/widgets/emulator_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/emulator.dart';
import '../../../../shared/theme/app_theme.dart';

class EmulatorCard extends StatelessWidget {
  final Emulator emulator;
  final VoidCallback onTap;

  const EmulatorCard({super.key, required this.emulator, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _icon(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emulator.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(emulator.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    _tags(context),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _sourceIcons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon() {
    if (emulator.iconUrl != null) {
      return CachedNetworkImage(
        imageUrl: emulator.iconUrl!,
        width: 48,
        height: 48,
        imageBuilder: (_, img) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(image: img, fit: BoxFit.cover),
          ),
        ),
        placeholder: (_, __) => _iconPlaceholder(),
        errorWidget: (_, __, ___) => _iconPlaceholder(),
      );
    }
    return _iconPlaceholder();
  }

  Widget _iconPlaceholder() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.videogame_asset_outlined,
            color: AppColors.muted, size: 22),
      );

  Widget _tags(BuildContext ctx) => Wrap(
        spacing: 4,
        runSpacing: 4,
        children: emulator.tags
            .take(3)
            .map((t) => Chip(label: Text(t), padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))
            .toList(),
      );

  Widget _sourceIcons() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emulator.sources.github != null)
            const Tooltip(
              message: 'GitHub',
              child: Icon(Icons.code, color: AppColors.muted, size: 18),
            ),
          if (emulator.sources.playStore != null)
            const Tooltip(
              message: 'Play Store',
              child: Icon(Icons.shop_outlined, color: AppColors.muted, size: 18),
            ),
        ],
      );
}
