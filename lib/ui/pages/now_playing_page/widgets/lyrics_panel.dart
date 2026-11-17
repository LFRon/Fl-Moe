import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
// The public LyricView owns a Scrollable and its own browsing state. Fl-Moe
// keeps the rendering core so desktop wheel input, click-to-seek and the
// single-canvas repaint boundary remain under one controller.
// ignore: implementation_imports
import 'package:flutter_lyric/src/rendering/line_transition.dart';
// ignore: implementation_imports
import 'package:flutter_lyric/src/rendering/lyric_layout.dart';
// ignore: implementation_imports
import 'package:flutter_lyric/src/rendering/lyric_painter.dart';
// ignore: implementation_imports
import 'package:flutter_lyric/src/rendering/resolved_preset.dart';

import '../../../../features/player/lyrics_controller.dart';
import '../../../../features/player/lyrics_models.dart';
import '../../../../features/player/playback_controller.dart';
import '../../../scrolling/fl_moe_smooth_scroll.dart';
import '../../../widgets/loading_skeletons.dart';

final class LyricsPanel extends StatelessWidget {
  const LyricsPanel({required this.lyrics, required this.player, super.key});

  final LyricsController lyrics;
  final PlaybackController player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow.withValues(alpha: 0.92),
      clipBehavior: Clip.antiAlias,
      child: switch (lyrics.state) {
        LyricsLoadState.idle => const _LyricsMessage(
          icon: Icons.lyrics_outlined,
          title: '选择一首歌曲开始播放',
        ),
        LyricsLoadState.loading => const _LyricsLoading(),
        LyricsLoadState.empty => const _LyricsMessage(
          icon: Icons.music_off_rounded,
          title: '这首歌暂时没有歌词',
          subtitle: '纯音乐也值得认真听完',
        ),
        LyricsLoadState.failed => _LyricsMessage(
          icon: Icons.cloud_off_rounded,
          title: '歌词获取失败',
          subtitle: lyrics.error ?? '请检查网络后重试',
          action: FilledButton.tonalIcon(
            onPressed: () => unawaited(lyrics.retry()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新获取'),
          ),
        ),
        LyricsLoadState.ready => _PaintedLyricsView(
          lines: lyrics.lines,
          activeIndex: activeLyricLineIndex(lyrics.lines, player.position),
          onSeek: (position) => unawaited(player.seek(position)),
        ),
      },
    );
  }
}

/// Canvas-based lyrics backed by flutter_lyric's layout and paint engine.
///
/// Fl-Moe owns the desktop interaction and animation state while retaining
/// flutter_lyric's cached TextPainters and single-canvas renderer. The public
/// LyricView is intentionally not used because its Scrollable would compete
/// with Fl-Moe's smooth wheel clock and click-to-center state machine.
final class _PaintedLyricsView extends StatefulWidget {
  const _PaintedLyricsView({
    required this.lines,
    required this.activeIndex,
    required this.onSeek,
  });

  final List<TimedLyricLine> lines;
  final int activeIndex;
  final ValueChanged<Duration> onSeek;

  @override
  State<_PaintedLyricsView> createState() => _PaintedLyricsViewState();
}

final class _PaintedLyricsViewState extends State<_PaintedLyricsView>
    with SingleTickerProviderStateMixin {
  static const Duration _manualScrollIdle = Duration(seconds: 1);
  static const Curve _manualScrollCurve = Curves.easeOutCubic;

  late final AnimationController _scrollController;
  late final _LyricsPaintState _paintState;
  late LyricDocument _document;
  Timer? _manualResumeTimer;
  LyricLayout? _layout;
  ResolvedPreset? _layoutResolved;
  Size _layoutSize = Size.zero;
  late int _actualActiveIndex;
  double? _manualTargetScrollY;
  double _animationStart = 0;
  double _animationTarget = 0;
  Curve _animationCurve = Curves.linear;
  bool _manualScrolling = false;
  int _tapRequestId = 0;

  @override
  void initState() {
    super.initState();
    _actualActiveIndex = widget.activeIndex;
    _document = _buildDocument(widget.lines);
    _paintState = _LyricsPaintState(_safeActualIndex);
    _scrollController = AnimationController(vsync: this)
      ..addListener(_handleScrollAnimationTick);
    PaintingBinding.instance.systemFonts.addListener(_handleSystemFontsChange);
  }

  @override
  void didUpdateWidget(covariant _PaintedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.lines, widget.lines)) {
      _tapRequestId += 1;
      _manualResumeTimer?.cancel();
      _manualScrolling = false;
      _manualTargetScrollY = null;
      _actualActiveIndex = widget.activeIndex;
      _invalidateLayout();
      _document = _buildDocument(widget.lines);
      _stopScrollAnimation();
      _paintState.replace(activeIndex: _safeActualIndex, scrollY: 0);
      return;
    }
    if (oldWidget.activeIndex == widget.activeIndex) return;
    _actualActiveIndex = widget.activeIndex;
    final safeIndex = _safeActualIndex;
    final shouldMoveViewport =
        !_manualScrolling && safeIndex != _paintState.activeIndex;
    _paintState.update(activeIndex: safeIndex);
    if (shouldMoveViewport) _animateToIndex(safeIndex);
  }

  LyricDocument _buildDocument(List<TimedLyricLine> lines) => LyricDocument(
    lines: <LyricLine>[
      for (final line in lines)
        LyricLine(
          start: line.start,
          end: line.end,
          text: line.text,
          translation: line.translation.isEmpty ? null : line.translation,
        ),
    ],
  );

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.scrollDelta.dy == 0) return;
    _handleWheelDelta(event.scrollDelta.dy);
  }

  void _handleWheelDelta(double delta) {
    final layout = _layout;
    if (!mounted || layout == null || widget.lines.isEmpty || delta == 0) {
      return;
    }
    _beginManualScroll();
    final target =
        (_manualTargetScrollY ?? _paintState.scrollY) +
        delta * flMoeSmoothScrollConfig.scrollSpeed;
    _manualTargetScrollY = _clampScrollY(layout, target);
    _animateScrollTo(
      _manualTargetScrollY!,
      duration: flMoeSmoothScrollConfig.silkyScrollDuration,
      curve: _manualScrollCurve,
    );
    _scheduleManualResume();
  }

  int get _safeActualIndex {
    if (widget.lines.isEmpty) return 0;
    return _actualActiveIndex.clamp(0, widget.lines.length - 1).toInt();
  }

  void _beginManualScroll() {
    _manualResumeTimer?.cancel();
    if (_manualScrolling) return;
    _manualScrolling = true;
    _manualTargetScrollY = _paintState.scrollY;
  }

  void _scheduleManualResume() {
    _manualResumeTimer?.cancel();
    _manualResumeTimer = Timer(_manualScrollIdle, () {
      if (!mounted) return;
      _manualScrolling = false;
      _manualTargetScrollY = null;
      final activeIndex = _safeActualIndex;
      _paintState.update(activeIndex: activeIndex);
      _animateToIndex(activeIndex);
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.lines.isEmpty) return;
    final canvasPosition = details.localPosition;
    for (final entry in _paintState.visibleLineRects.entries) {
      if (!entry.value.contains(canvasPosition)) continue;
      _handleLineTap(entry.key);
      return;
    }
  }

  void _handleLineTap(int index) {
    if (widget.lines.isEmpty || index < 0 || index >= widget.lines.length) {
      return;
    }
    final requestId = ++_tapRequestId;
    _manualResumeTimer?.cancel();
    _manualScrolling = false;
    _manualTargetScrollY = null;
    _paintState.update(activeIndex: index);
    _animateToIndex(index);
    final position = widget.lines[index].start;

    // Paint the selected line and begin its canvas translation first. Native
    // media seeking is dispatched on the next frame and never owns this
    // animation's ticker, so buffering cannot freeze the visual response.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || requestId != _tapRequestId) return;
      widget.onSeek(position);
    });
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    if (_layout == null) return;
    _beginManualScroll();
    _stopScrollAnimation();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final layout = _layout;
    if (layout == null) return;
    final target = _clampScrollY(
      layout,
      _paintState.scrollY - details.delta.dy,
    );
    _manualTargetScrollY = target;
    _paintState.update(scrollY: target);
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final layout = _layout;
    if (layout == null) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (velocity.abs() >= 80) {
      final target = _clampScrollY(
        layout,
        _paintState.scrollY - velocity * 0.12,
      );
      _manualTargetScrollY = target;
      _animateScrollTo(
        target,
        duration: flMoeSmoothScrollConfig.silkyScrollDuration,
        curve: _manualScrollCurve,
      );
    }
    _scheduleManualResume();
  }

  void _handleVerticalDragCancel() {
    if (!_manualScrolling) return;
    _scheduleManualResume();
  }

  void _handleScrollAnimationTick() {
    if (!_scrollController.isAnimating && _scrollController.value == 0) return;
    final progress = _animationCurve.transform(_scrollController.value);
    _paintState.update(
      scrollY:
          _animationStart + (_animationTarget - _animationStart) * progress,
    );
  }

  void _animateToIndex(int index) {
    final layout = _layout;
    if (layout == null || widget.lines.isEmpty) return;
    final safeIndex = index.clamp(0, widget.lines.length - 1).toInt();
    final anchor = layout.style.preset.activeAnchor;
    final target = layout.lineOffsetY(safeIndex, safeIndex, anchor);
    final safeTarget = _clampScrollY(layout, target, activeIndex: safeIndex);
    final animation = layout.style.preset.scrollAnimation.resolve(
      (safeTarget - _paintState.scrollY).abs(),
    );
    _animateScrollTo(
      safeTarget,
      duration: animation.duration,
      curve: animation.curve,
    );
  }

  void _animateScrollTo(
    double target, {
    required Duration duration,
    required Curve curve,
  }) {
    final start = _paintState.scrollY;
    if ((start - target).abs() < 0.1 || duration == Duration.zero) {
      _stopScrollAnimation();
      _paintState.update(scrollY: target);
      return;
    }
    _scrollController.stop();
    _animationStart = start;
    _animationTarget = target;
    _animationCurve = curve;
    _scrollController.duration = duration;
    _scrollController.forward(from: 0);
  }

  void _stopScrollAnimation() {
    if (_scrollController.isAnimating) _scrollController.stop();
  }

  double _clampScrollY(LyricLayout layout, double value, {int? activeIndex}) {
    if (layout.metrics.isEmpty) return 0;
    final active = (activeIndex ?? _paintState.activeIndex)
        .clamp(0, layout.metrics.length - 1)
        .toInt();
    final first = layout.firstIndex;
    final last = first + layout.metrics.length - 1;
    final style = layout.style;
    final firstActive = layout.lineOffsetY(
      first,
      active,
      style.preset.activeAnchor,
    );
    final firstSelection = layout.lineOffsetY(
      first,
      active,
      style.preset.selectionAnchor,
    );
    final minimum = math.min(
      -style.padding.top,
      math.min(firstActive, firstSelection),
    );
    var maximum = math.max(
      layout.contentHeight(active) -
          layout.viewSize.height +
          style.padding.bottom,
      math.max(
        layout.lineOffsetY(last, active, style.preset.activeAnchor),
        layout.lineOffsetY(last, active, style.preset.selectionAnchor),
      ),
    );
    maximum = math.max(minimum, maximum);
    return value.clamp(minimum, maximum).toDouble();
  }

  void _handleSystemFontsChange() {
    if (!mounted) return;
    setState(() {
      _stopScrollAnimation();
      _invalidateLayout();
      _paintState.replace(
        activeIndex: _safeActualIndex,
        scrollY: _paintState.scrollY,
      );
    });
  }

  LyricPreset _preset(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseStyle = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final translationStyle = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.68),
          height: 1.2,
        );
    return LyricPreset(
      displayMode: LyricDisplayMode.scrollable,
      textStyle: baseStyle,
      activeTextStyle: baseStyle.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w800,
      ),
      translationInheritsTextStyle: false,
      translationTextStyle: translationStyle,
      activeTranslationTextStyle: TextStyle(
        color: scheme.primary.withValues(alpha: 0.78),
      ),
      selectedTextColor: scheme.primary,
      selectedTranslationTextColor: scheme.primary.withValues(alpha: 0.78),
      textAlign: TextAlign.left,
      contentAlignment: LyricContentAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 44),
      lineSpacing: 25,
      translationSpacing: 3,
      activeAnchor: const LyricAnchor.fraction(0.5),
      selectionAnchor: const LyricAnchor.fraction(0.5),
      highlight: const LyricHighlight.none(),
      edgeFade: const LyricEdgeFade.none(),
      countdown: const LyricCountdown.none(),
      scrollAnimation: LyricScrollAnimation.byDistance(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        durations: <double, Duration>{
          180: const Duration(milliseconds: 320),
          420: const Duration(milliseconds: 380),
          760: const Duration(milliseconds: 440),
        },
      ),
      lineTransition: const LyricLineTransition.none(),
      layoutMode: LyricLayoutMode.dualStyle,
      lineMotion: const LyricLineMotion(),
      wordEffects: const LyricWordEffects(),
      distanceBlur: const LyricDistanceBlur(),
      interactive: true,
      selectionSnapMode: LyricSelectionSnapMode.none,
      resumeDelay: _manualScrollIdle,
      resumeOnTap: true,
    );
  }

  ResolvedPreset _resolvedPreset(BuildContext context) {
    final media = MediaQuery.of(context);
    return ResolvedPreset(
      _preset(context),
      ambient: Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
      direction: Directionality.of(context),
      textScaleFactor: MediaQuery.textScalerOf(context).scale(1),
      devicePixelRatio: media.devicePixelRatio,
      locale: Localizations.maybeLocaleOf(context),
    );
  }

  LyricLayout _ensureLayout(ResolvedPreset resolved, Size size) {
    final cached = _layout;
    if (cached != null &&
        _layoutSize == size &&
        _sameResolvedStyle(_layoutResolved, resolved)) {
      return cached;
    }
    _stopScrollAnimation();
    final computed = LyricLayout.compute(_document, resolved, size);
    _layout?.dispose();
    _layout = computed;
    _layoutResolved = resolved;
    _layoutSize = size;
    final activeIndex = _safeActualIndex;
    final target = computed.lineOffsetY(
      activeIndex,
      activeIndex,
      resolved.preset.activeAnchor,
    );
    _paintState.replace(
      activeIndex: activeIndex,
      scrollY: _clampScrollY(computed, target, activeIndex: activeIndex),
    );
    _manualScrolling = false;
    _manualTargetScrollY = null;
    return computed;
  }

  bool _sameResolvedStyle(ResolvedPreset? cached, ResolvedPreset next) {
    if (cached == null) return false;
    return cached.preset == next.preset &&
        cached.textStyle == next.textStyle &&
        cached.activeTextStyle == next.activeTextStyle &&
        cached.translationTextStyle == next.translationTextStyle &&
        cached.activeTranslationTextStyle == next.activeTranslationTextStyle &&
        cached.padding == next.padding &&
        cached.direction == next.direction &&
        cached.textScaleFactor == next.textScaleFactor &&
        cached.locale == next.locale;
  }

  void _invalidateLayout() {
    _layout?.dispose();
    _layout = null;
    _layoutResolved = null;
    _layoutSize = Size.zero;
  }

  @override
  void dispose() {
    _tapRequestId += 1;
    _manualResumeTimer?.cancel();
    PaintingBinding.instance.systemFonts.removeListener(
      _handleSystemFontsChange,
    );
    _scrollController
      ..removeListener(_handleScrollAnimationTick)
      ..dispose();
    _invalidateLayout();
    _paintState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedPreset(context);
    return Semantics(
      key: const ValueKey<String>('now-playing-lyrics-list'),
      label: '同步歌词',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerSignal: _handlePointerSignal,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _handleTapUp,
            onVerticalDragStart: _handleVerticalDragStart,
            onVerticalDragUpdate: _handleVerticalDragUpdate,
            onVerticalDragEnd: _handleVerticalDragEnd,
            onVerticalDragCancel: _handleVerticalDragCancel,
            child: RepaintBoundary(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  if (!size.width.isFinite ||
                      !size.height.isFinite ||
                      size.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final layout = _ensureLayout(resolved, size);
                  return CustomPaint(
                    painter: FlMoeLyricCanvasPainter._(
                      layout: layout,
                      paintState: _paintState,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _LyricsPaintState extends ChangeNotifier {
  _LyricsPaintState(this._activeIndex);

  int _activeIndex;
  double _scrollY = 0;
  Map<int, Rect> visibleLineRects = const <int, Rect>{};

  int get activeIndex => _activeIndex;
  double get scrollY => _scrollY;

  void update({int? activeIndex, double? scrollY}) {
    final nextActiveIndex = activeIndex ?? _activeIndex;
    final nextScrollY = scrollY ?? _scrollY;
    if (nextActiveIndex == _activeIndex && nextScrollY == _scrollY) return;
    _activeIndex = nextActiveIndex;
    _scrollY = nextScrollY;
    notifyListeners();
  }

  void replace({required int activeIndex, required double scrollY}) {
    _activeIndex = activeIndex;
    _scrollY = scrollY;
    visibleLineRects = const <int, Rect>{};
  }
}

/// Publicly inspectable paint delegate used by widget tests and diagnostics.
/// Runtime animation values live in a repaint-only notifier, so scrolling does
/// not rebuild or lay out the surrounding now-playing page.
final class FlMoeLyricCanvasPainter extends CustomPainter {
  FlMoeLyricCanvasPainter._({
    required this.layout,
    required _LyricsPaintState paintState,
  }) : _paintState = paintState,
       super(repaint: paintState);

  final LyricLayout layout;
  final _LyricsPaintState _paintState;

  ResolvedPreset get style => layout.style;
  int get activeIndex => _paintState.activeIndex;
  double get scrollY => _paintState.scrollY;
  Map<int, Rect> get visibleLineRects =>
      Map<int, Rect>.unmodifiable(_paintState.visibleLineRects);

  @override
  void paint(Canvas canvas, Size size) {
    final activeIndex = _paintState.activeIndex;
    final rects = <int, Rect>{};
    final first = layout.lineAtOffset(_paintState.scrollY, activeIndex);
    for (
      var index = first;
      index < layout.firstIndex + layout.metrics.length;
      index += 1
    ) {
      final top = layout.lineTop(index, activeIndex) - _paintState.scrollY;
      if (top >= size.height) break;
      final height = layout.getLineHeight(index == activeIndex, index);
      if (top + height <= 0) continue;
      rects[index] = Rect.fromLTWH(
        layout.style.padding.left,
        top,
        layout.contentWidth,
        height,
      );
    }
    _paintState.visibleLineRects = rects;

    LyricPainter(
      layout: layout,
      playIndex: activeIndex,
      scrollY: _paintState.scrollY,
      activeHighlightWidth: double.infinity,
      switchState: LyricLineSwitchState(enterIndex: activeIndex),
      isSelecting: false,
      selectedIndex: null,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant FlMoeLyricCanvasPainter oldDelegate) =>
      !identical(layout, oldDelegate.layout) ||
      !identical(_paintState, oldDelegate._paintState);
}

final class _LyricsLoading extends StatelessWidget {
  const _LyricsLoading();

  @override
  Widget build(BuildContext context) => const FlMoeSkeletonScope(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 44),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FlMoeSkeletonLine(width: 240, height: 20),
          SizedBox(height: 26),
          FlMoeSkeletonLine(width: 310, height: 18),
          SizedBox(height: 26),
          FlMoeSkeletonLine(width: 270, height: 18),
          SizedBox(height: 26),
          FlMoeSkeletonLine(width: 330, height: 18),
          SizedBox(height: 26),
          FlMoeSkeletonLine(width: 220, height: 18),
        ],
      ),
    ),
  );
}

final class _LyricsMessage extends StatelessWidget {
  const _LyricsMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
