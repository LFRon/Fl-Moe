import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../../../features/auth/authentication_controller.dart';
import '../../../features/music/favorite_tracks_controller.dart';
import '../../../features/music/music_catalog_controller.dart';
import '../../../features/music/user_playlists_controller.dart';
import '../../../features/navigation/app_navigation_controller.dart';
import '../../../features/player/playback_controller.dart';
import '../../login_dialog.dart';
import '../../scrolling/fl_moe_smooth_scroll.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_list.dart';
import 'widgets/favorite_tracks_view.dart';
import 'widgets/library_card.dart';
import 'widgets/user_playlists_section.dart';

enum _LibraryView { overview, favoriteTracks }

final class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

final class _LibraryPageState extends State<LibraryPage> {
  _LibraryView _view = _LibraryView.overview;
  bool _playlistLoadScheduled = false;

  void _schedulePlaylistLoad(
    AuthenticationController authentication,
    UserPlaylistsController playlists,
  ) {
    if (_playlistLoadScheduled ||
        !authentication.isLoggedIn ||
        playlists.loading ||
        playlists.loaded ||
        playlists.error != null) {
      return;
    }
    _playlistLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playlistLoadScheduled = false;
      if (mounted) unawaited(playlists.load());
    });
  }

  Future<void> _loginForPlaylists(UserPlaylistsController playlists) async {
    if (!await showQrLoginDialog(context) || !mounted) return;
    unawaited(playlists.load(force: true));
  }

  Future<void> _loginForFavorites(
    FavoriteTracksController favorites,
    UserPlaylistsController playlists,
  ) async {
    if (!await showQrLoginDialog(context) || !mounted) return;
    unawaited(playlists.load(force: true));
    unawaited(favorites.load(force: true));
  }

  Future<void> _openFavorites(
    AuthenticationController authentication,
    FavoriteTracksController favorites,
    UserPlaylistsController playlists,
  ) async {
    if (!authentication.isLoggedIn && !await showQrLoginDialog(context)) return;
    if (!mounted) return;
    setState(() => _view = _LibraryView.favoriteTracks);
    unawaited(playlists.load());
    unawaited(favorites.load());
  }

  Future<void> _openPlaylist(
    UserPlaylist playlist,
    FavoriteTracksController favorites,
  ) async {
    if (playlist.isFavorite) {
      setState(() => _view = _LibraryView.favoriteTracks);
      await favorites.load();
      return;
    }
    final collection = playlist.collection;
    Get.find<AppNavigationController>().openCollection(collection);
    await Get.find<MusicCollectionDetailController>().load(collection);
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AuthenticationController>(
    filter: (authentication) => authentication.isLoggedIn,
    builder: (authentication) => GetBuilder<UserPlaylistsController>(
      filter: (playlists) => (
        loaded: playlists.loaded,
        loading: playlists.loading,
        error: playlists.error,
        all: playlists.allPlaylists,
        created: playlists.createdPlaylists,
        collected: playlists.collectedPlaylists,
      ),
      builder: (playlists) => GetBuilder<FavoriteTracksController>(
        filter: (favorites) => (
          loaded: favorites.loaded,
          loading: favorites.loading,
          loadingMore: favorites.loadingMore,
          hasMore: favorites.hasMore,
          error: favorites.error,
          tracks: favorites.tracks,
          total: favorites.totalCount,
        ),
        builder: (favorites) {
          _schedulePlaylistLoad(authentication, playlists);
          return switch (_view) {
            _LibraryView.favoriteTracks => FavoriteTracksView(
              controller: favorites,
              loggedIn: authentication.isLoggedIn,
              onBack: () => setState(() => _view = _LibraryView.overview),
              onLogin: () => _loginForFavorites(favorites, playlists),
            ),
            _LibraryView.overview => GetBuilder<PlaybackController>(
              // The overview only renders recent history. Playback position,
              // buffering and volume ticks must not rebuild every card above
              // the list.
              filter: (player) => player.recentTracks,
              builder: (player) => _LibraryOverview(
                player: player,
                playlists: playlists,
                loggedIn: authentication.isLoggedIn,
                favoriteSubtitle: _favoriteCardSubtitle(
                  authentication,
                  favorites,
                ),
                onOpenFavorites: () => unawaited(
                  _openFavorites(authentication, favorites, playlists),
                ),
                onLoginForPlaylists: () => _loginForPlaylists(playlists),
                onOpenPlaylist: (playlist) =>
                    _openPlaylist(playlist, favorites),
              ),
            ),
          };
        },
      ),
    ),
  );
}

final class _LibraryOverview extends StatelessWidget {
  const _LibraryOverview({
    required this.player,
    required this.playlists,
    required this.loggedIn,
    required this.favoriteSubtitle,
    required this.onOpenFavorites,
    required this.onLoginForPlaylists,
    required this.onOpenPlaylist,
  });

  final PlaybackController player;
  final UserPlaylistsController playlists;
  final bool loggedIn;
  final String favoriteSubtitle;
  final VoidCallback onOpenFavorites;
  final Future<void> Function() onLoginForPlaylists;
  final Future<void> Function(UserPlaylist playlist) onOpenPlaylist;

  @override
  Widget build(BuildContext context) {
    final recentTracks = player.recentTracks;
    final hasRecent = recentTracks.isNotEmpty;
    return SilkyCustomScrollView(
      silkyConfig: flMoeSmoothScrollConfig,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
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
              const SizedBox(height: 28),
            ]),
          ),
        ),
        UserPlaylistsSliver(
          key: const ValueKey<String>('user-playlists-section'),
          controller: playlists,
          loggedIn: loggedIn,
          onLogin: onLoginForPlaylists,
          onOpenPlaylist: onOpenPlaylist,
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    key: const ValueKey<String>('clear-recent-tracks'),
                    onPressed: recentTracks.isEmpty
                        ? null
                        : () => unawaited(
                            _confirmAndClearRecentTracks(context, player),
                          ),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 19),
                    label: const Text('清空列表'),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${recentTracks.length} 首',
                    key: const ValueKey<String>('recent-tracks-count'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        if (hasRecent)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return SongListItem(
                  track: recentTracks[index],
                  sourceTracks: recentTracks,
                  index: index,
                  compact: false,
                );
              }, childCount: recentTracks.length),
            ),
          )
        else
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            sliver: SliverToBoxAdapter(
              child: EmptyState(
                title: '还没有播放记录',
                message: '从搜索页播放一首歌后，这里会自动保存最近记录。',
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

String _favoriteCardSubtitle(
  AuthenticationController authentication,
  FavoriteTracksController favorites,
) {
  if (!authentication.isLoggedIn) return '登录酷狗后查看“我喜欢”歌单';
  if (favorites.loading && favorites.tracks.isEmpty) {
    return '正在从酷狗同步“我喜欢”…';
  }
  if (favorites.error != null && favorites.tracks.isEmpty) {
    return '同步失败，点击进入后重试';
  }
  if (favorites.loaded) return '${favorites.totalCount} 首收藏歌曲';
  return '直接进入酷狗账号的“我喜欢”歌单';
}

Future<void> _confirmAndClearRecentTracks(
  BuildContext context,
  PlaybackController player,
) async {
  final confirmed = await confirmListClear(
    context,
    listName: '最近播放',
    itemCount: player.recentTracks.length,
  );
  if (confirmed) await player.clearRecentTracks();
}
