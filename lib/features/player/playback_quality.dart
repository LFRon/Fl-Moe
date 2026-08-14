import '../../kugou_api.dart';

/// Audio qualities exposed by MoeKoe Music, ordered from lowest to highest.
const List<KugouPlaybackQuality> selectablePlaybackQualities =
    <KugouPlaybackQuality>[
      KugouPlaybackQuality.standard,
      KugouPlaybackQuality.high,
      KugouPlaybackQuality.lossless,
      KugouPlaybackQuality.hiRes,
      KugouPlaybackQuality.atmos,
      KugouPlaybackQuality.clear,
      KugouPlaybackQuality.master,
    ];

extension PlaybackQualityPresentation on KugouPlaybackQuality {
  String get badgeLabel => switch (this) {
    KugouPlaybackQuality.standard => '标准',
    KugouPlaybackQuality.high => '高品',
    KugouPlaybackQuality.lossless => 'FLAC',
    KugouPlaybackQuality.hiRes => 'Hi-Res',
    KugouPlaybackQuality.atmos => '全景声',
    KugouPlaybackQuality.clear => '超清',
    KugouPlaybackQuality.master => '母带',
    _ => wireValue,
  };

  String get settingsLabel => switch (this) {
    KugouPlaybackQuality.standard => '标准音质 · 128 Kbps',
    KugouPlaybackQuality.high => '高品音质 · 320 Kbps',
    KugouPlaybackQuality.lossless => 'FLAC 无损',
    KugouPlaybackQuality.hiRes => 'Hi-Res 无损',
    KugouPlaybackQuality.atmos => '蝰蛇全景',
    KugouPlaybackQuality.clear => '蝰蛇超清',
    KugouPlaybackQuality.master => '蝰蛇母带',
    _ => wireValue,
  };
}

KugouPlaybackQuality normalizeSelectablePlaybackQuality(
  KugouPlaybackQuality quality,
) => selectablePlaybackQualities.contains(quality)
    ? quality
    : KugouPlaybackQuality.standard;

List<KugouPlaybackQuality> playbackQualityFallbackChain(
  KugouPlaybackQuality maximum,
) {
  final normalized = normalizeSelectablePlaybackQuality(maximum);
  final maximumIndex = selectablePlaybackQualities.indexOf(normalized);
  return selectablePlaybackQualities
      .take(maximumIndex + 1)
      .toList(growable: false)
      .reversed
      .toList(growable: false);
}
