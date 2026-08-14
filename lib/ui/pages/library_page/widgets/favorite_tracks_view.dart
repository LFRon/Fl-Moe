import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../features/music/favorite_tracks_controller.dart';
import '../../../../features/music/music_models.dart';
import '../../../../features/player/playback_controller.dart';
import '../../../scrolling/fl_moe_smooth_scroll.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/loading_skeletons.dart';
import '../../../widgets/song_list.dart';

final class FavoriteTracksView extends StatefulWidget {
  const FavoriteTracksView({
    required this.controller,
    required this.loggedIn,
    required this.onBack,
    required this.onLogin,
    super.key,
  });

  final FavoriteTracksController controller;
  final bool loggedIn;
  final VoidCallback onBack;
  final Future<void> Function() onLogin;

  @override
  State<FavoriteTracksView> createState() => _FavoriteTracksViewState();
}

final class _FavoriteTracksViewState extends State<FavoriteTracksView> {
  final ScrollController _scrollController = ScrollController();
  bool _loadMoreScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter >= 720 ||
        !widget.controller.hasMore ||
        widget.controller.loadingMore) {
      return;
    }
    unawaited(widget.controller.loadMore());
  }

  void _scheduleLoadMoreCheck() {
    if (_loadMoreScheduled ||
        !widget.loggedIn ||
        !widget.controller.hasMore ||
        widget.controller.loadingMore) {
      return;
    }
    _loadMoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMoreScheduled = false;
      if (mounted) _maybeLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favorites = widget.controller;
    final tracks = favorites.tracks;
    _scheduleLoadMoreCheck();
    return SilkyListView.builder(
      key: const ValueKey<String>('favorite-tracks-view'),
      silkyConfig: flMoeSmoothScrollConfig,
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      itemCount: _itemCount(favorites, tracks),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _FavoriteHeader(
            favorites: favorites,
            loggedIn: widget.loggedIn,
            onBack: widget.onBack,
          );
        }
        if (!widget.loggedIn) {
          return EmptyState(
            title: '登录后查看“我喜欢”',
            message: '收藏歌曲来自当前酷狗账号的“我喜欢”歌单。',
            asset: 'assets/images/favorites.png',
            action: FilledButton.icon(
              onPressed: () => unawaited(widget.onLogin()),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('扫码登录'),
            ),
          );
        }
        if (tracks.isEmpty) {
          if (favorites.loading) {
            return const Padding(
              padding: EdgeInsets.only(top: 16),
              child: FlMoeSkeletonScope(child: SkeletonSongList(itemCount: 9)),
            );
          }
          final error = favorites.error;
          if (error != null) {
            return EmptyState(
              title: '收藏加载失败',
              message: error,
              action: FilledButton.tonalIcon(
                onPressed: () => unawaited(favorites.load(force: true)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重新加载'),
              ),
            );
          }
          return EmptyState(
            title: favorites.loaded ? '还没有收藏歌曲' : '准备同步收藏',
            message: favorites.loaded
                ? '在酷狗音乐中收藏歌曲后，刷新这里即可看到。'
                : '点击按钮后从酷狗“我喜欢”歌单获取歌曲。',
            asset: 'assets/images/favorites.png',
            action: favorites.loaded
                ? null
                : FilledButton.tonalIcon(
                    onPressed: () => unawaited(favorites.load()),
                    icon: const Icon(Icons.cloud_download_rounded),
                    label: const Text('开始同步'),
                  ),
          );
        }

        final trackIndex = index - 1;
        if (trackIndex < tracks.length) {
          return SongListItem(
            track: tracks[trackIndex],
            sourceTracks: tracks,
            index: trackIndex,
            compact: false,
          );
        }
        return _FavoriteListFooter(favorites: favorites);
      },
    );
  }
}

int _itemCount(FavoriteTracksController favorites, List<MusicTrack> tracks) {
  if (tracks.isEmpty) return 2;
  final hasFooter =
      favorites.hasMore || favorites.loadingMore || favorites.error != null;
  return 1 + tracks.length + (hasFooter ? 1 : 0);
}

final class _FavoriteHeader extends StatelessWidget {
  const _FavoriteHeader({
    required this.favorites,
    required this.loggedIn,
    required this.onBack,
  });

  final FavoriteTracksController favorites;
  final bool loggedIn;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('返回音乐库'),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Image.asset(
              'assets/images/favorites.png',
              width: 92,
              height: 92,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '我喜欢',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _headerSubtitle(favorites, loggedIn),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (loggedIn)
              IconButton.filledTonal(
                tooltip: '刷新收藏',
                onPressed: favorites.loading
                    ? null
                    : () => unawaited(favorites.load(force: true)),
                icon: favorites.loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            if (_tracksCanPlay(favorites)) ...<Widget>[
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => unawaited(
                  Get.find<PlaybackController>().playTrack(
                    favorites.tracks.first,
                    sourceTracks: favorites.tracks,
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('播放'),
              ),
            ],
          ],
        ),
        if (favorites.error != null && favorites.tracks.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.sync_problem_rounded,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(favorites.error!)),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

bool _tracksCanPlay(FavoriteTracksController favorites) =>
    favorites.tracks.isNotEmpty && !favorites.loading;

String _headerSubtitle(FavoriteTracksController favorites, bool loggedIn) {
  if (!loggedIn) return '登录酷狗后同步“我喜欢”中的歌曲';
  if (favorites.loading && favorites.tracks.isEmpty) return '正在从酷狗同步收藏…';
  if (favorites.tracks.isEmpty) return '酷狗账号的“我喜欢”歌单';
  if (favorites.hasMore) {
    return '已加载 ${favorites.tracks.length} / ${favorites.totalCount} 首';
  }
  return '共 ${favorites.tracks.length} 首收藏歌曲';
}

final class _FavoriteListFooter extends StatelessWidget {
  const _FavoriteListFooter({required this.favorites});

  final FavoriteTracksController favorites;

  @override
  Widget build(BuildContext context) {
    if (favorites.error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () => unawaited(favorites.loadMore()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试加载更多'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: favorites.loadingMore
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : TextButton.icon(
                onPressed: () => unawaited(favorites.loadMore()),
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('加载更多'),
              ),
      ),
    );
  }
}
