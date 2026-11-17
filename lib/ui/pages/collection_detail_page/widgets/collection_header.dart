import 'package:material_ui/material_ui.dart';

import '../../../../features/music/music_models.dart';
import '../../../widgets/network_artwork.dart';

final class CollectionHeader extends StatelessWidget {
  const CollectionHeader({
    required this.collection,
    required this.trackCount,
    required this.onPlay,
    required this.onRefresh,
    super.key,
  });

  final MusicCollection collection;
  final int? trackCount;
  final VoidCallback? onPlay;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 225,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            scheme.primaryContainer.withValues(alpha: 0.86),
            scheme.secondaryContainer.withValues(alpha: 0.58),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: <Widget>[
          NetworkArtwork(url: collection.coverUrl, size: 177, borderRadius: 20),
          const SizedBox(width: 26),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  collection.kind == MusicCollectionKind.ranking
                      ? '排行榜'
                      : '精选歌单',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  collection.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  collection.subtitle.isEmpty
                      ? trackCount == null
                            ? '正在获取歌曲列表…'
                            : '$trackCount 首歌曲'
                      : collection.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('播放全部'),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: '刷新歌曲列表',
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
