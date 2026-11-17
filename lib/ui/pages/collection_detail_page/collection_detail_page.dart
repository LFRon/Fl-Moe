import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../../../features/music/music_catalog_controller.dart';
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
            return SilkyListView(
              silkyConfig: flMoeSmoothScrollConfig,
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
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
                CollectionHeader(
                  collection: collection,
                  trackCount: detail.loading ? null : detail.tracks.length,
                  onPlay: detail.tracks.isEmpty
                      ? null
                      : () => unawaited(
                          Get.find<PlaybackController>().playTrack(
                            detail.tracks.first,
                            sourceTracks: detail.tracks,
                          ),
                        ),
                  onRefresh: detail.loading
                      ? null
                      : () => unawaited(detail.load(collection)),
                ),
                const SizedBox(height: 26),
                if (detail.loading) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        '歌曲列表',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Text('正在获取…'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const CollectionTracksSkeleton(),
                ] else if (detail.tracks.isEmpty)
                  EmptyState(
                    title: '暂时没有歌曲',
                    message: detail.error ?? '酷狗没有返回可播放的歌曲，请稍后重试。',
                    action: FilledButton.tonalIcon(
                      onPressed: () => unawaited(detail.load(collection)),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('重新加载'),
                    ),
                  )
                else ...<Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        '歌曲列表',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text('${detail.tracks.length} 首'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SongList(tracks: detail.tracks),
                ],
              ],
            );
          },
        ),
      );
}
