// lib/features/catalog/presentation/widgets/emulator_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
              EmulatorIcon(url: emulator.iconUrl, size: 48),
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

  Widget _tags(BuildContext ctx) => Wrap(
        spacing: 4,
        runSpacing: 4,
        children: emulator.tags
            .take(3)
            .map((t) => Chip(
                  label: Text(t),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ))
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

/// Reusable rounded-square emulator icon with bundled SVG fallback.
class EmulatorIcon extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  const EmulatorIcon({
    super.key,
    required this.url,
    this.size = 48,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        imageBuilder: (_, img) => _frame(child: Image(image: img, fit: BoxFit.cover)),
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _frame({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(width: size, height: size, child: child),
      );

  Widget _fallback() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: EdgeInsets.all(size * 0.18),
        child: SvgPicture.asset(
          'assets/icons/fallback.svg',
          fit: BoxFit.contain,
        ),
      );
}
