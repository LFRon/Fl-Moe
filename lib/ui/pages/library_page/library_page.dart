import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/player/playback_controller.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_list.dart';
import 'widgets/library_card.dart';

final class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<PlaybackController>(
    builder: (player) {
      final recentTracks = player.recentTracks;
      return ListView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        children: <Widget>[
          const PageHeading(
            title: '我的音乐',
            subtitle: '播放历史存放在 Fl-Moe 自己的 Hive CE 数据库中',
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: <Widget>[
                Expanded(
                  child: LibraryCard(
                    title: '本地音乐',
                    subtitle: '扫描与管理电脑上的音乐文件',
                    asset: 'assets/images/local_music.png',
                    onPressed: () => showReservedFeature(context, '本地音乐扫描'),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: LibraryCard(
                    title: '我的云盘',
                    subtitle: '酷狗云盘接口已经内嵌，可在云盘页登录使用',
                    asset: 'assets/images/cloud_disk.png',
                    onPressed: () => showReservedFeature(context, '云盘批量管理'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: <Widget>[
              Text(
                '最近播放',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text('${recentTracks.length} 首'),
            ],
          ),
          const SizedBox(height: 12),
          if (recentTracks.isEmpty)
            const EmptyState(
              title: '还没有播放记录',
              message: '从搜索页播放一首歌后，这里会自动保存最近记录。',
            )
          else
            SongList(tracks: recentTracks),
        ],
      );
    },
  );
}
