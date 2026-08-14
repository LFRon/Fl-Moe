import 'package:flutter/material.dart';

import '../../../../features/player/playback_quality.dart';
import '../../../../kugou_api.dart';

final class PlaybackQualityPopup extends StatelessWidget {
  const PlaybackQualityPopup({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final KugouPlaybackQuality selected;
  final ValueChanged<KugouPlaybackQuality> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<KugouPlaybackQuality>(
      key: const ValueKey<String>('maximum-playback-quality-popup'),
      tooltip: '选择最高播放音质',
      initialValue: selected,
      position: PopupMenuPosition.under,
      borderRadius: BorderRadius.circular(20),
      splashRadius: 20,
      onSelected: onSelected,
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      itemBuilder: (context) => selectablePlaybackQualities
          .map<PopupMenuEntry<KugouPlaybackQuality>>(
            (quality) => CheckedPopupMenuItem<KugouPlaybackQuality>(
              key: ValueKey<String>('playback-quality-${quality.name}'),
              value: quality,
              checked: quality == selected,
              child: Text(quality.settingsLabel),
            ),
          )
          .toList(growable: false),
      child: Semantics(
        button: true,
        label: '最高播放音质，当前为${selected.settingsLabel}',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            key: const ValueKey<String>('maximum-playback-quality-button'),
            constraints: const BoxConstraints(minWidth: 174),
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 18,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selected.badgeLabel,
                      style: TextStyle(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: scheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
