import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/music/music_models.dart';
import '../../features/player/playback_controller.dart';
import 'network_artwork.dart';

final class SongList extends StatelessWidget {
  const SongList({required this.tracks, this.compact = false, super.key});

  final List<MusicTrack> tracks;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    children: List<Widget>.generate(
      tracks.length,
      (index) => _SongRow(
        track: tracks[index],
        queue: tracks,
        index: index,
        compact: compact,
      ),
      growable: false,
    ),
  );
}

final class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.track,
    required this.queue,
    required this.index,
    required this.compact,
  });

  final MusicTrack track;
  final List<MusicTrack> queue;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) => GetBuilder<PlaybackController>(
    builder: (player) {
      final currentHash = player.currentTrack?.hash;
      final selected = currentHash == track.hash;
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.55)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            mouseCursor: WidgetStateMouseCursor.clickable,
            borderRadius: BorderRadius.circular(12),
            onTap: () => unawaited(player.playTrack(track, queue: queue)),
            child: SizedBox(
              height: compact ? 58 : 66,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 44,
                    child: Center(
                      child: selected
                          ? Icon(
                              Icons.graphic_eq_rounded,
                              color: scheme.primary,
                            )
                          : Text(
                              '${index + 1}'.padLeft(2, '0'),
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                    ),
                  ),
                  NetworkArtwork(
                    url: track.coverUrl,
                    size: compact ? 42 : 48,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected ? scheme.primary : null,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (!compact)
                    Expanded(
                      flex: 3,
                      child: Text(
                        track.album.isEmpty ? '—' : track.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      _formatDuration(track.duration),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  IconButton(
                    tooltip: '播放',
                    onPressed: () =>
                        unawaited(player.playTrack(track, queue: queue)),
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

String _formatDuration(Duration duration) {
  if (duration == Duration.zero) return '--:--';
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
