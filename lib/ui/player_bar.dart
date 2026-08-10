import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../features/player/playback_controller.dart';
import 'widgets/common_widgets.dart';
import 'widgets/network_artwork.dart';

final class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<PlaybackController>(
    builder: (player) {
      final track = player.currentTrack;
      final scheme = Theme.of(context).colorScheme;
      final durationMs = player.duration.inMilliseconds;
      final positionMs = player.position.inMilliseconds.clamp(
        0,
        durationMs > 0 ? durationMs : 1,
      );
      return Material(
        color: scheme.surfaceContainerLowest,
        child: Container(
          height: 94,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 14,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 4.5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: positionMs.toDouble(),
                    max: durationMs > 0 ? durationMs.toDouble() : 1,
                    onChanged: track == null
                        ? null
                        : (value) => unawaited(
                            player.seek(Duration(milliseconds: value.round())),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 9),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 300,
                        child: Row(
                          children: <Widget>[
                            NetworkArtwork(
                              url: track?.coverUrl ?? '',
                              size: 58,
                              borderRadius: 13,
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    track?.title ?? '还没有播放歌曲',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    track?.artist ?? '从搜索结果中选择一首歌吧',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                IconButton(
                                  tooltip: '上一首',
                                  onPressed: player.canGoPrevious
                                      ? () => unawaited(player.previous())
                                      : null,
                                  icon: const Icon(Icons.skip_previous_rounded),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  onPressed: track == null || player.resolving
                                      ? null
                                      : () => unawaited(player.toggle()),
                                  child: player.resolving || player.buffering
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          player.playing
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          size: 25,
                                        ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: '下一首',
                                  onPressed: player.canGoNext
                                      ? () => unawaited(player.next())
                                      : null,
                                  icon: const Icon(Icons.skip_next_rounded),
                                ),
                              ],
                            ),
                            if (player.error != null)
                              Text(
                                player.error!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: scheme.error),
                              )
                            else
                              Text(
                                '${_format(player.position)} / ${_format(player.duration)}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 345,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            IconButton(
                              tooltip: '桌面歌词（暂未实现）',
                              onPressed: () =>
                                  showReservedFeature(context, '桌面歌词'),
                              // This glyph's visible bounds lean one logical
                              // pixel to the right despite a centered layout.
                              icon: Transform.translate(
                                offset: const Offset(-1, 0),
                                child: const Icon(
                                  Icons.lyrics_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: '状态栏歌词（暂未实现）',
                              onPressed: () =>
                                  showReservedFeature(context, '状态栏歌词'),
                              icon: const Icon(
                                Icons.subtitles_outlined,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Icon(
                              player.volume == 0
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              size: 20,
                            ),
                            SizedBox(
                              width: 105,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  // Keep the full slider hit area while
                                  // bringing the visible track closer to the
                                  // volume icon.
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                ),
                                child: Slider(
                                  key: const ValueKey<String>(
                                    'player-volume-slider',
                                  ),
                                  value: player.volume,
                                  max: 100,
                                  onChanged: (value) =>
                                      unawaited(player.setVolume(value)),
                                ),
                              ),
                            ),
                            PopupMenuButton<PlaybackMode>(
                              tooltip:
                                  '播放模式：${_playbackModeLabel(player.playbackMode)}',
                              onSelected: (mode) =>
                                  unawaited(player.setPlaybackMode(mode)),
                              icon: Icon(
                                _playbackModeIcon(player.playbackMode),
                                size: 21,
                              ),
                              itemBuilder: (context) => PlaybackMode.values
                                  .map<PopupMenuEntry<PlaybackMode>>(
                                    (mode) => PopupMenuItem<PlaybackMode>(
                                      value: mode,
                                      child: Row(
                                        children: <Widget>[
                                          Icon(
                                            _playbackModeIcon(mode),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _playbackModeLabel(mode),
                                            ),
                                          ),
                                          if (mode == player.playbackMode)
                                            const Icon(
                                              Icons.check_rounded,
                                              size: 19,
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            IconButton(
                              tooltip: '播放队列',
                              onPressed: () => _showQueue(context, player),
                              icon: const Icon(
                                Icons.queue_music_rounded,
                                size: 21,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showQueue(BuildContext context, PlaybackController player) {
  showModalBottomSheet<void>(
    context: context,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  '播放队列',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text('${player.queue.length} 首'),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: player.queue.isEmpty
                  ? const Center(child: Text('播放队列还是空的'))
                  : ListView.builder(
                      itemCount: player.queue.length,
                      itemBuilder: (context, index) {
                        final track = player.queue[index];
                        return ListTile(
                          mouseCursor: WidgetStateMouseCursor.clickable,
                          leading: NetworkArtwork(
                            url: track.coverUrl,
                            size: 42,
                            borderRadius: 9,
                          ),
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: player.currentTrack?.hash == track.hash,
                          onTap: () {
                            Navigator.pop(context);
                            unawaited(
                              player.playTrack(track, queue: player.queue),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _format(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _playbackModeLabel(PlaybackMode mode) => switch (mode) {
  PlaybackMode.shuffle => '随机播放',
  PlaybackMode.listLoop => '列表循环',
  PlaybackMode.singleLoop => '单曲循环',
  PlaybackMode.sequential => '顺序播放',
};

IconData _playbackModeIcon(PlaybackMode mode) => switch (mode) {
  PlaybackMode.shuffle => Icons.shuffle_rounded,
  PlaybackMode.listLoop => Icons.repeat_rounded,
  PlaybackMode.singleLoop => Icons.repeat_one_rounded,
  PlaybackMode.sequential => Icons.format_list_numbered_rounded,
};
