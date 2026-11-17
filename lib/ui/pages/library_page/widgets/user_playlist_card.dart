import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../features/music/user_playlists_controller.dart';
import '../../../widgets/network_artwork.dart';

final class UserPlaylistCard extends StatelessWidget {
  const UserPlaylistCard({
    required this.playlist,
    required this.onPressed,
    super.key,
  });

  final UserPlaylist playlist;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          mouseCursor: WidgetStateMouseCursor.clickable,
          onTap: () => unawaited(onPressed()),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      NetworkArtwork(
                        url: playlist.coverUrl,
                        borderRadius: 14,
                        fallbackAsset: playlist.isFavorite
                            ? 'assets/images/favorites.png'
                            : 'assets/images/app_mascot.png',
                      ),
                      if (playlist.isFavorite)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer.withValues(
                                alpha: 0.94,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(7),
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  playlist.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${playlist.trackCount} 首歌曲',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
