import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import 'loading_skeletons.dart';

final class NetworkArtwork extends StatelessWidget {
  const NetworkArtwork({
    required this.url,
    this.size,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.fallbackAsset = 'assets/images/app_mascot.png',
    super.key,
  });

  final String url;
  final double? size;
  final double? width;
  final double? height;
  final double borderRadius;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = size ?? width;
    final resolvedHeight = size ?? height;
    final fallback = Image.asset(
      fallbackAsset,
      width: resolvedWidth,
      height: resolvedHeight,
      fit: BoxFit.cover,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: url,
              width: resolvedWidth,
              height: resolvedHeight,
              fit: BoxFit.cover,
              // List and grid thumbnails are often built together while a page
              // transition is running. A 500 ms cross-fade would keep every
              // visible image in its own opacity layer during that frame budget.
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholderFadeInDuration: Duration.zero,
              memCacheWidth: resolvedWidth == null
                  ? null
                  : (resolvedWidth * MediaQuery.devicePixelRatioOf(context))
                        .round(),
              placeholder: (context, value) =>
                  const FlMoeSkeletonBox(borderRadius: BorderRadius.zero),
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
    );
  }
}
