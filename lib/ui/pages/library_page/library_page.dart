import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/auth/authentication_controller.dart';
import '../../../features/music/favorite_tracks_controller.dart';
import '../../../features/player/playback_controller.dart';
import '../../login_dialog.dart';
import '../../scrolling/fl_moe_smooth_scroll.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_list.dart';
import 'widgets/favorite_tracks_view.dart';
import 'widgets/library_card.dart';

final class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

final class _LibraryPageState extends State<LibraryPage> {
  bool _showFavorites = false;

  Future<void> _openFavorites(
    AuthenticationController authentication,
    FavoriteTracksController favorites,
  ) async {
    if (!authentication.isLoggedIn && !await showQrLoginDialog(context)) return;
    if (!mounted) return;
    setState(() => _showFavorites = true);
    unawaited(favorites.load());
  }

  Future<void> _loginForFavorites(FavoriteTracksController favorites) async {
    if (!await showQrLoginDialog(context) || !mounted) return;
    unawaited(favorites.load(force: true));
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AuthenticationController>(
    builder: (authentication) => GetBuilder<FavoriteTracksController>(
      builder: (favorites) => _showFavorites
          ? FavoriteTracksView(
              controller: favorites,
              loggedIn: authentication.isLoggedIn,
              onBack: () => setState(() => _showFavorites = false),
              onLogin: () => _loginForFavorites(favorites),
            )
          : GetBuilder<PlaybackController>(
              builder: (player) => _LibraryOverview(
                player: player,
                favoriteSubtitle: _favoriteCardSubtitle(
                  authentication,
                  favorites,
                ),
                onOpenFavorites: () =>
                    unawaited(_openFavorites(authentication, favorites)),
              ),
            ),
    ),
  );
}

final class _LibraryOverview extends StatelessWidget {
  const _LibraryOverview({
    required this.player,
    required this.favoriteSubtitle,
    required this.onOpenFavorites,
  });

  final PlaybackController player;
  final String favoriteSubtitle;
  final VoidCallback onOpenFavorites;

  @override
  Widget build(BuildContext context) {
    final recentTracks = player.recentTracks;
    return SilkyListView(
      silkyConfig: flMoeSmoothScrollConfig,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      children: <Widget>[
        const PageHeading(
          title: '我的音乐',
          subtitle: '播放历史存放在 Fl-Moe 自己的 Hive CE 数据库中',
        ),
        const SizedBox(height: 24),
        LibraryCard(
          key: const ValueKey<String>('favorite-library-card'),
          title: '我的收藏',
          subtitle: favoriteSubtitle,
          asset: 'assets/images/favorites.png',
          onPressed: onOpenFavorites,
        ),
        const SizedBox(height: 18),
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
          const EmptyState(title: '还没有播放记录', message: '从搜索页播放一首歌后，这里会自动保存最近记录。')
        else
          SongList(tracks: recentTracks),
      ],
    );
  }
}

String _favoriteCardSubtitle(
  AuthenticationController authentication,
  FavoriteTracksController favorites,
) {
  if (!authentication.isLoggedIn) return '登录酷狗后查看“我喜欢”中的歌曲';
  if (favorites.loading) return '正在从酷狗同步收藏…';
  if (favorites.error != null && favorites.tracks.isEmpty) {
    return '同步失败，点击进入后重试';
  }
  if (favorites.loaded) {
    return favorites.totalCount == 0
        ? '当前账号还没有收藏歌曲'
        : '${favorites.totalCount} 首收藏歌曲';
  }
  return '按需从酷狗账号同步，不影响音乐库打开速度';
}
