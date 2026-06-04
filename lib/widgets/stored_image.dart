import 'package:flutter/material.dart';

import '../services/local_image_store.dart';
import '../theme/app_theme.dart';

class StoredImage extends StatelessWidget {
  const StoredImage({
    required this.imageRef,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image_not_supported_outlined,
    super.key,
  });

  final String imageRef;
  final BoxFit fit;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final localImages = LocalImageStore.instance;

    if (!localImages.isLocalImageRef(imageRef)) {
      return Image.network(
        imageRef,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _ImagePlaceholder(
          icon: placeholderIcon,
          label: 'Foto tidak tersedia',
        ),
      );
    }

    return FutureBuilder(
      future: localImages.readImage(imageRef),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(
            color: AppColors.skyBlue,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (bytes == null || bytes.isEmpty) {
          return _ImagePlaceholder(
            icon: placeholderIcon,
            label: 'Foto lokal tidak ditemukan',
          );
        }

        return Image.memory(bytes, fit: fit, gaplessPlayback: true);
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.skyBlue,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.deepBlue),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
