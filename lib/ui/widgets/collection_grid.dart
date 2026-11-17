import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../../features/music/music_catalog_controller.dart';
import '../../features/music/music_models.dart';
import '../../features/navigation/app_navigation_controller.dart';
import '../../features/player/playback_controller.dart';
import 'network_artwork.dart';

final class CollectionGrid extends StatelessWidget {
  const CollectionGrid({required this.collections, super.key});

  final List<MusicCollection> collections;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = (constraints.maxWidth / 190).floor().clamp(2, 6);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio: 0.84,
        ),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final collection = collections[index];
          return _CollectionCard(
            key: ValueKey<String>(
              '${collection.kind.name}:${collection.id.isEmpty ? collection.accountListId : collection.id}',
            ),
            collection: collection,
          );
        },
      );
    },
  );
}

final class _CollectionCard extends StatefulWidget {
  const _CollectionCard({required this.collection, super.key});

  final MusicCollection collection;

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

final class _CollectionCardState extends State<_CollectionCard> {
  bool _hovered = false;
  bool _startingPlayback = false;

  Future<void> _open() async {
    Get.find<AppNavigationController>().openCollection(widget.collection);
    await Get.find<MusicCollectionDetailController>().load(widget.collection);
  }

  Future<void> _play() async {
    if (_startingPlayback) return;
    setState(() => _startingPlayback = true);
    try {
      final tracks = await Get.find<MusicCollectionDetailController>()
          .fetchTracks(widget.collection);
      if (tracks.isEmpty) {
        if (mounted) _showMessage('这个歌单暂时没有可播放歌曲');
        return;
      }
      final player = Get.find<PlaybackController>();
      await player.playTrack(tracks.first, sourceTracks: tracks);
      final error = player.error;
      if (error != null && mounted) _showMessage('播放失败：$error');
    } on Object catch (error) {
      if (mounted) _showMessage(describeMusicError(error));
    } finally {
      if (mounted) setState(() => _startingPlayback = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (event) => setState(() => _hovered = true),
      onExit: (event) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.018 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        // A non-null quality makes ScaleTransition transform a bitmap of the
        // child while the animation is running instead of re-rendering it for
        // every intermediate scale. Low-quality bilinear sampling is enough
        // for this subtle desktop hover zoom.
        filterQuality: FilterQuality.low,
        child: RepaintBoundary(
          // This boundary must stay inside AnimatedScale so its display list
          // can be reused while only the transform layer changes.
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              mouseCursor: WidgetStateMouseCursor.clickable,
              borderRadius: BorderRadius.circular(17),
              onTap: () => unawaited(_open()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        NetworkArtwork(
                          url: collection.coverUrl,
                          borderRadius: 17,
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: AnimatedOpacity(
                            opacity: _hovered || _startingPlayback ? 1 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: IgnorePointer(
                              ignoring: !_hovered && !_startingPlayback,
                              child: IconButton.filled(
                                key: ValueKey<String>(
                                  'collection-quick-play-${collection.kind.name}-${collection.id}',
                                ),
                                tooltip: '播放《${collection.title}》',
                                style: IconButton.styleFrom(
                                  fixedSize: const Size.square(40),
                                  backgroundColor: scheme.primary,
                                  foregroundColor: scheme.onPrimary,
                                  disabledBackgroundColor: scheme.primary,
                                  disabledForegroundColor: scheme.onPrimary,
                                ),
                                // Keep the nested gesture active while loading
                                // so repeated clicks never fall through to the
                                // card's navigation action.
                                onPressed: () => unawaited(_play()),
                                icon: _startingPlayback
                                    ? SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.onPrimary,
                                        ),
                                      )
                                    : const Icon(Icons.play_arrow_rounded),
                              ),
                            ),
                          ),
                        ),
                        if (collection.playCount > 0)
                          Positioned(
                            top: 9,
                            right: 9,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.headphones_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _compactNumber(collection.playCount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    collection.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _compactNumber(int value) {
  if (value >= 100000000) {
    return '${(value / 100000000).toStringAsFixed(1)}亿';
  }
  if (value >= 10000) return '${(value / 10000).toStringAsFixed(1)}万';
  return '$value';
}
