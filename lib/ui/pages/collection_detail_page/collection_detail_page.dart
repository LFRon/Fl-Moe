import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../../../features/music/music_catalog_controller.dart';
import '../../../features/music/music_models.dart';
import '../../../features/navigation/app_navigation_controller.dart';
import '../../../features/player/playback_controller.dart';
import '../../scrolling/fl_moe_smooth_scroll.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_list.dart';
import 'widgets/collection_header.dart';
import 'widgets/collection_tracks_skeleton.dart';

final class CollectionDetailPage extends StatelessWidget {
  const CollectionDetailPage({super.key});

  @override
  Widget build(BuildContext context) =>
      GetBuilder<MusicCollectionDetailController>(
        builder: (detail) => GetBuilder<AppNavigationController>(
          builder: (navigation) {
            final collection =
                detail.collection ?? navigation.selectedCollection;
            if (collection == null) {
              return EmptyState(
                title: '没有选中内容',
                message: '请从首页或发现页选择一个歌单或排行榜。',
                action: FilledButton(
                  onPressed: navigation.closeCollection,
                  child: const Text('返回发现'),
                ),
              );
            }

            final tracks = detail.tracks;
            final showTracks = !detail.loading && tracks.isNotEmpty;
            return SilkyListView.builder(
              key: ValueKey<String>(
                'collection-detail-${collection.kind.name}-'
                '${collection.id}-${collection.accountListId}',
              ),
              silkyConfig: flMoeSmoothScrollConfig,
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
              itemCount: 2 + (showTracks ? tracks.length : 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _DetailHeader(
                    collection: collection,
                    detail: detail,
                    navigation: navigation,
                    tracks: tracks,
                  );
                }
                if (index == 1) {
                  return _DetailSectionHeader(
                    loading: detail.loading,
                    trackCount: showTracks ? tracks.length : null,
                  );
                }
                if (!showTracks) {
                  return _DetailStatus(collection: collection, detail: detail);
                }
                final trackIndex = index - 2;
                return SongListItem(
                  track: tracks[trackIndex],
                  sourceTracks: tracks,
                  index: trackIndex,
                  compact: false,
                );
              },
            );
          },
        ),
      );
}

final class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.collection,
    required this.detail,
    required this.navigation,
    required this.tracks,
  });

  final MusicCollection collection;
  final MusicCollectionDetailController detail;
  final AppNavigationController navigation;
  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: navigation.closeCollection,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('返回'),
        ),
      ),
      const SizedBox(height: 6),
      RepaintBoundary(
        child: CollectionHeader(
          collection: collection,
          trackCount: detail.loading ? null : tracks.length,
          onPlay: tracks.isEmpty
              ? null
              : () => unawaited(
                  Get.find<PlaybackController>().playTrack(
                    tracks.first,
                    sourceTracks: tracks,
                  ),
                ),
          onRefresh: detail.loading
              ? null
              : () => unawaited(detail.load(collection)),
        ),
      ),
      const SizedBox(height: 26),
    ],
  );
}

final class _DetailSectionHeader extends StatelessWidget {
  const _DetailSectionHeader({required this.loading, required this.trackCount});

  final bool loading;
  final int? trackCount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: <Widget>[
        Text(
          '歌曲列表',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(loading ? '正在获取…' : '${trackCount ?? 0} 首'),
      ],
    ),
  );
}

final class _DetailStatus extends StatelessWidget {
  const _DetailStatus({required this.collection, required this.detail});

  final MusicCollection collection;
  final MusicCollectionDetailController detail;

  @override
  Widget build(BuildContext context) {
    if (detail.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: CollectionTracksSkeleton(),
      );
    }
    return EmptyState(
      title: '暂时没有歌曲',
      message: detail.error ?? '酷狗没有返回可播放的歌曲，请稍后重试。',
      action: FilledButton.tonalIcon(
        onPressed: () => unawaited(detail.load(collection)),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('重新加载'),
      ),
    );
  }
}
