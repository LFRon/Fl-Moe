import 'dart:ui' as ui;

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

/// A softly blurred cover backdrop for the now-playing surface.
///
/// [ImageFiltered] is intentionally used instead of [BackdropFilter]: only the
/// static cover needs filtering, so changes to lyrics and playback progress do
/// not repeatedly blur the complete page underneath this route-like overlay.
final class NowPlayingBackground extends StatelessWidget {
  const NowPlayingBackground({required this.coverUrl, super.key});

  static const double blurSigma = 24;
  static const String _fallbackAsset = 'assets/images/app_mascot.png';

  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return IgnorePointer(
      child: RepaintBoundary(
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ColoredBox(
                key: const ValueKey<String>('now-playing-background-base'),
                color: scheme.surface,
              ),
              ImageFiltered(
                key: const ValueKey<String>('now-playing-background-blur'),
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                  tileMode: ui.TileMode.clamp,
                ),
                child: Transform.scale(
                  // Keep blurred sampling away from the image boundary so no
                  // transparent halo appears around the window edges.
                  scale: 1.12,
                  child: _CoverImage(coverUrl: coverUrl),
                ),
              ),
              DecoratedBox(
                key: const ValueKey<String>('now-playing-background-tint'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      scheme.primaryContainer.withValues(
                        alpha: isDark ? 0.66 : 0.76,
                      ),
                      scheme.surface.withValues(alpha: isDark ? 0.72 : 0.78),
                      scheme.tertiaryContainer.withValues(
                        alpha: isDark ? 0.64 : 0.72,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverUrl});

  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      NowPlayingBackground._fallbackAsset,
      fit: BoxFit.cover,
    );
    if (coverUrl.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (context, value) => fallback,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
