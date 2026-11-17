import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../features/navigation/app_navigation_controller.dart';
import '../features/player/playback_controller.dart';
import '../features/player/playback_quality.dart';
import 'widgets/common_widgets.dart';
import 'widgets/network_artwork.dart';

final class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<PlaybackController>(
    // Position ticks are isolated in _PlayerProgressSlider/_PlayerTimeLabel.
    // Otherwise every media position event rebuilds the whole bottom bar,
    // including the transport controls and volume UI.
    filter: (player) => (
      track: player.currentTrack,
      playing: player.playing,
      buffering: player.buffering,
      resolving: player.resolving,
      seeking: player.seeking,
      error: player.error,
      quality: player.resolvedQuality,
      canGoPrevious: player.canGoPrevious,
      canGoNext: player.canGoNext,
      playbackMode: player.playbackMode,
    ),
    builder: (player) {
      final track = player.currentTrack;
      final scheme = Theme.of(context).colorScheme;
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
              const _PlayerProgressSlider(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 9),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 300,
                        child: InkWell(
                          key: const ValueKey<String>(
                            'open-now-playing-details',
                          ),
                          mouseCursor: track == null
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                          borderRadius: BorderRadius.circular(14),
                          onTap: track == null
                              ? null
                              : Get.find<AppNavigationController>()
                                    .showNowPlaying,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (track != null)
                                  Icon(
                                    Icons.keyboard_double_arrow_up_rounded,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  ),
                              ],
                            ),
                          ),
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
                                  child:
                                      player.resolving ||
                                          player.buffering ||
                                          player.seeking
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
                              const _PlayerTimeLabel(),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 420,
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
                            if (track != null &&
                                player.resolvedQuality != null) ...<Widget>[
                              const SizedBox(width: 10),
                              Tooltip(
                                message:
                                    '当前播放：${player.resolvedQuality!.settingsLabel}',
                                child: Container(
                                  key: const ValueKey<String>(
                                    'current-playback-quality',
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    player.resolvedQuality!.badgeLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: scheme.onTertiaryContainer,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 15),
                            const _PlayerVolumeControl(),
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

final class _PlayerVolumeControl extends StatelessWidget {
  const _PlayerVolumeControl();

  @override
  Widget build(BuildContext context) => GetBuilder<PlaybackController>(
    // Dragging the volume slider must not rebuild the transport controls or
    // the now-playing summary on every pointer move.
    filter: (player) => player.volume,
    builder: (player) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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
              // Keep the full slider hit area while bringing the visible
              // track closer to the volume icon.
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              key: const ValueKey<String>('player-volume-slider'),
              value: player.volume,
              max: 100,
              onChanged: (value) => unawaited(player.setVolume(value)),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _PlayerProgressSlider extends StatelessWidget {
  const _PlayerProgressSlider();

  @override
  Widget build(BuildContext context) => GetBuilder<PlaybackController>(
    filter: (player) => (
      track: player.currentTrack?.hash,
      position: player.position,
      duration: player.duration,
    ),
    builder: (player) {
      final durationMs = player.duration.inMilliseconds;
      final positionMs = player.position.inMilliseconds.clamp(
        0,
        durationMs > 0 ? durationMs : 1,
      );
      return SizedBox(
        height: 14,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          ),
          child: Slider(
            value: positionMs.toDouble(),
            max: durationMs > 0 ? durationMs.toDouble() : 1,
            onChanged: player.currentTrack == null
                ? null
                : (value) => unawaited(
                    player.seek(Duration(milliseconds: value.round())),
                  ),
          ),
        ),
      );
    },
  );
}

final class _PlayerTimeLabel extends StatelessWidget {
  const _PlayerTimeLabel();

  @override
  Widget build(BuildContext context) => GetBuilder<PlaybackController>(
    filter: (player) => (position: player.position, duration: player.duration),
    builder: (player) => Text(
      '${_format(player.position)} / ${_format(player.duration)}',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
