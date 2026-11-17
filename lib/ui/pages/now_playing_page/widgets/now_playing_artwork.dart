import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../features/music/music_models.dart';
import '../../../../features/player/playback_controller.dart';
import '../../../../features/player/playback_quality.dart';
import '../../../widgets/network_artwork.dart';

final class NowPlayingArtwork extends StatelessWidget {
  const NowPlayingArtwork({
    required this.track,
    required this.player,
    super.key,
  });

  final MusicTrack track;
  final PlaybackController player;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scheme = Theme.of(context).colorScheme;
      // The full-window page owns its playback controls, so reserve their
      // height before sizing the cover instead of relying on the hidden
      // bottom player bar.
      final availableHeight = math.max(130, constraints.maxHeight - 226);
      final availableWidth = math.max(130, constraints.maxWidth - 28);
      final coverSize = math
          .min(math.min(availableWidth, availableHeight), 380)
          .toDouble();
      final durationMs = player.duration.inMilliseconds;
      final positionMs = player.position.inMilliseconds.clamp(
        0,
        durationMs > 0 ? durationMs : 1,
      );
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.24),
                    blurRadius: 38,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: NetworkArtwork(
                url: track.coverUrl,
                size: coverSize,
                borderRadius: 28,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            track.album.isEmpty
                ? track.artist
                : '${track.artist} · ${track.album}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Text(
                _format(player.position),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Expanded(
                child: Slider(
                  value: positionMs.toDouble(),
                  max: durationMs > 0 ? durationMs.toDouble() : 1,
                  onChanged: (value) => unawaited(
                    player.seek(Duration(milliseconds: value.round())),
                  ),
                ),
              ),
              Text(
                _format(player.duration),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (player.resolvedQuality != null) ...<Widget>[
                const SizedBox(width: 10),
                Container(
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton.filledTonal(
                tooltip: '上一首',
                onPressed: player.canGoPrevious
                    ? () => unawaited(player.previous())
                    : null,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              const SizedBox(width: 14),
              FilledButton(
                key: const ValueKey<String>('now-playing-play-pause'),
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: player.resolving
                    ? null
                    : () => unawaited(player.toggle()),
                child: player.resolving || player.buffering || player.seeking
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        player.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 27,
                      ),
              ),
              const SizedBox(width: 14),
              IconButton.filledTonal(
                tooltip: '下一首',
                onPressed: player.canGoNext
                    ? () => unawaited(player.next())
                    : null,
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ],
          ),
        ],
      );
    },
  );
}

String _format(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
