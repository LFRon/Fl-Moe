import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../../../core/window/desktop_window_service.dart';
import '../../../features/navigation/app_navigation_controller.dart';
import '../../../features/player/lyrics_controller.dart';
import '../../../features/player/lyrics_models.dart';
import '../../../features/player/playback_controller.dart';
import '../../window_drag_region.dart';
import 'widgets/lyrics_panel.dart';
import 'widgets/now_playing_artwork.dart';
import 'widgets/now_playing_background.dart';

final class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({required this.window, super.key});

  final DesktopWindowService window;

  @override
  Widget build(BuildContext context) => GetBuilder<PlaybackController>(
    filter: (value) => (track: value.currentTrack),
    builder: (player) {
      final track = player.currentTrack;
      final lyrics = Get.find<LyricsController>();
      if (track != null && lyrics.trackHash != track.hash) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(lyrics.loadFor(track));
        });
      }
      return ClipRect(
        key: const ValueKey<String>('now-playing-page'),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            NowPlayingBackground(coverUrl: track?.coverUrl ?? ''),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 28, 22),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 48,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Positioned.fill(
                          left: 58,
                          right: 58,
                          child: FlMoeWindowDragRegion(
                            key: const ValueKey<String>(
                              'now-playing-window-drag-region',
                            ),
                            window: window,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton.filledTonal(
                            key: const ValueKey<String>('close-now-playing'),
                            tooltip: '收起播放详情',
                            onPressed: Get.find<AppNavigationController>()
                                .hideNowPlaying,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                        ),
                        IgnorePointer(
                          child: Center(
                            child: Text(
                              '正在播放',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: track == null
                        ? Center(
                            child: Text(
                              '还没有播放歌曲',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 760) {
                                return Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: const _ReactiveNowPlayingArtwork(),
                                    ),
                                    const SizedBox(height: 14),
                                    const Expanded(
                                      child: _ReactiveLyricsPanel(),
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 9,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: const _ReactiveNowPlayingArtwork(),
                                    ),
                                  ),
                                  const SizedBox(width: 22),
                                  const Expanded(
                                    flex: 11,
                                    child: _ReactiveLyricsPanel(),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Rebuilds only the control/artwork column for playback fields it renders.
/// The full-window background and outer layout remain untouched by position
/// stream events.
final class _ReactiveNowPlayingArtwork extends StatelessWidget {
  const _ReactiveNowPlayingArtwork();

  @override
  Widget build(BuildContext context) => GetBuilder<PlaybackController>(
    filter: (value) => (
      track: value.currentTrack,
      position: value.position,
      duration: value.duration,
      playing: value.playing,
      buffering: value.buffering,
      resolving: value.resolving,
      seeking: value.seeking,
      quality: value.resolvedQuality,
      canGoPrevious: value.canGoPrevious,
      canGoNext: value.canGoNext,
    ),
    builder: (player) {
      final track = player.currentTrack;
      return track == null
          ? const SizedBox.shrink()
          : NowPlayingArtwork(track: track, player: player);
    },
  );
}

/// Rebuilds lyrics for lyric-data changes or when playback crosses into a new
/// timed line. Sub-line position ticks no longer rebuild the lyrics list.
final class _ReactiveLyricsPanel extends StatelessWidget {
  const _ReactiveLyricsPanel();

  @override
  Widget build(BuildContext context) => GetBuilder<LyricsController>(
    builder: (lyrics) => GetBuilder<PlaybackController>(
      key: ObjectKey(lyrics.lines),
      filter: (value) => (
        track: value.currentTrack,
        activeIndex: activeLyricLineIndex(lyrics.lines, value.position),
      ),
      builder: (player) => LyricsPanel(lyrics: lyrics, player: player),
    ),
  );
}
