import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../features/music/user_playlists_controller.dart';
import '../../../widgets/loading_skeletons.dart';
import 'user_playlist_card.dart';

enum _PlaylistScope { all, created, collected }

/// The signed-in account's non-favorite playlists embedded in the library.
///
/// “我喜欢” has its own direct entry above this section, so it is deliberately
/// excluded from every scope and count shown here.
final class UserPlaylistsSection extends StatefulWidget {
  const UserPlaylistsSection({
    required this.controller,
    required this.loggedIn,
    required this.onLogin,
    required this.onOpenPlaylist,
    super.key,
  });

  final UserPlaylistsController controller;
  final bool loggedIn;
  final Future<void> Function() onLogin;
  final Future<void> Function(UserPlaylist playlist) onOpenPlaylist;

  @override
  State<UserPlaylistsSection> createState() => _UserPlaylistsSectionState();
}

final class _UserPlaylistsSectionState extends State<UserPlaylistsSection> {
  _PlaylistScope _scope = _PlaylistScope.all;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final created = _withoutFavorite(controller.createdPlaylists);
    final collected = _withoutFavorite(controller.collectedPlaylists);
    final all = _withoutFavorite(controller.allPlaylists);
    final visible = switch (_scope) {
      _PlaylistScope.all => all,
      _PlaylistScope.created => created,
      _PlaylistScope.collected => collected,
    };

    return Column(
      key: const ValueKey<String>('user-playlists-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '我的歌单',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _sectionSubtitle(controller, widget.loggedIn, all.length),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.loggedIn)
              IconButton.filledTonal(
                tooltip: '刷新歌单',
                onPressed: controller.loading
                    ? null
                    : () => unawaited(controller.load(force: true)),
                icon: controller.loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        if (widget.loggedIn &&
            (controller.loaded || controller.allPlaylists.isNotEmpty)) ...[
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_PlaylistScope>(
              segments: <ButtonSegment<_PlaylistScope>>[
                ButtonSegment<_PlaylistScope>(
                  value: _PlaylistScope.all,
                  icon: const Icon(Icons.queue_music_rounded),
                  label: Text('全部 ${all.length}'),
                ),
                ButtonSegment<_PlaylistScope>(
                  value: _PlaylistScope.created,
                  icon: const Icon(Icons.library_add_rounded),
                  label: Text('我创建的 ${created.length}'),
                ),
                ButtonSegment<_PlaylistScope>(
                  value: _PlaylistScope.collected,
                  icon: const Icon(Icons.bookmarks_rounded),
                  label: Text('我收藏的 ${collected.length}'),
                ),
              ],
              selected: <_PlaylistScope>{_scope},
              onSelectionChanged: (selection) {
                setState(() => _scope = selection.single);
              },
            ),
          ),
        ],
        if (controller.error != null && controller.allPlaylists.isNotEmpty) ...[
          const SizedBox(height: 14),
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.sync_problem_rounded),
                  const SizedBox(width: 10),
                  Expanded(child: Text(controller.error!)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildContent(context, visible),
      ],
    );
  }

  Widget _buildContent(BuildContext context, List<UserPlaylist> playlists) {
    final controller = widget.controller;
    if (!widget.loggedIn) {
      return _PlaylistNotice(
        icon: Icons.account_circle_outlined,
        title: '登录后显示账号歌单',
        message: '这里会直接展示除“我喜欢”之外的创建与收藏歌单。',
        action: FilledButton.icon(
          onPressed: () => unawaited(widget.onLogin()),
          icon: const Icon(Icons.qr_code_2_rounded),
          label: const Text('扫码登录'),
        ),
      );
    }
    if (controller.allPlaylists.isEmpty &&
        controller.error == null &&
        (!controller.loaded || controller.loading)) {
      return const FlMoeSkeletonScope(
        key: ValueKey<String>('library-playlists-skeleton'),
        child: SkeletonCollectionGrid(itemCount: 6),
      );
    }
    if (controller.error != null && controller.allPlaylists.isEmpty) {
      return _PlaylistNotice(
        icon: Icons.cloud_off_rounded,
        title: '歌单加载失败',
        message: controller.error!,
        action: FilledButton.tonalIcon(
          onPressed: () => unawaited(controller.load(force: true)),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重新加载'),
        ),
      );
    }
    if (playlists.isEmpty) {
      return _PlaylistNotice(
        icon: Icons.queue_music_rounded,
        title: _scope == _PlaylistScope.collected
            ? '还没有收藏其他歌单'
            : _scope == _PlaylistScope.created
            ? '还没有创建其他歌单'
            : '还没有其他歌单',
        message: _scope == _PlaylistScope.collected
            ? '收藏其他用户的歌单后会显示在这里。'
            : _scope == _PlaylistScope.created
            ? '在酷狗中新建的歌单会显示在这里。'
            : '“我喜欢”已经放在上方的独立入口中。',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 18.0;
        final columnCount = (constraints.maxWidth / 190).floor().clamp(2, 6);
        return GridView.builder(
          key: const ValueKey<String>('user-playlists-grid'),
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 0.84,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return UserPlaylistCard(
              key: ValueKey<String>('user-playlist-${playlist.stableId}'),
              playlist: playlist,
              onPressed: () => widget.onOpenPlaylist(playlist),
            );
          },
        );
      },
    );
  }
}

List<UserPlaylist> _withoutFavorite(List<UserPlaylist> playlists) =>
    playlists.where((playlist) => !playlist.isFavorite).toList(growable: false);

String _sectionSubtitle(
  UserPlaylistsController controller,
  bool loggedIn,
  int visibleCount,
) {
  if (!loggedIn) return '酷狗账号中创建与收藏的其他歌单';
  if (controller.loading && controller.allPlaylists.isEmpty) {
    return '正在从酷狗同步歌单…';
  }
  if (controller.error != null && controller.allPlaylists.isEmpty) {
    return '同步失败，可以在下方重新加载';
  }
  if (!controller.loaded) return '准备同步酷狗账号歌单';
  return visibleCount == 0 ? '当前账号还没有其他歌单' : '共 $visibleCount 个其他歌单';
}

final class _PlaylistNotice extends StatelessWidget {
  const _PlaylistNotice({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 34, color: scheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (action != null) ...<Widget>[const SizedBox(width: 16), action!],
          ],
        ),
      ),
    );
  }
}
