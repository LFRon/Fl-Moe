import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/core/lyric_model.dart' as lyric_model;
import 'package:flutter_lyric/core/lyric_style.dart';
import 'package:flutter_lyric/render/lyric_layout.dart';
import 'package:flutter_lyric/render/lyric_painter.dart';
import 'package:flutter_lyric/widgets/mixins/lyric_line_switch_mixin.dart';

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
/// The package's stock gesture layer currently treats a desktop pointer-down
/// as the beginning of a drag, which can swallow an otherwise valid line tap.
/// Fl-Moe therefore owns the desktop interaction and animation state while
/// retaining flutter_lyric's cached TextPainters and single-canvas renderer.
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
  late lyric_model.LyricModel _model;
  Timer? _manualResumeTimer;
  LyricLayout? _layout;
  LyricStyle? _layoutStyle;
  ThemeData? _layoutTheme;
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
    _model = _buildModel(widget.lines);
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
      _model = _buildModel(widget.lines);
      _layout = null;
      _layoutStyle = null;
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

  lyric_model.LyricModel _buildModel(List<TimedLyricLine> lines) =>
      lyric_model.LyricModel(
        lines: lines
            .map(
              (line) => lyric_model.LyricLine(
                start: line.start,
                end: line.end,
                text: line.text,
                translation: line.translation.isEmpty ? null : line.translation,
              ),
            )
            .toList(growable: false),
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
    final style = _layoutStyle;
    if (style == null || widget.lines.isEmpty) return;
    final canvasPosition = details.localPosition.translate(
      -style.contentPadding.left,
      0,
    );
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
    final style = _layoutStyle;
    if (layout == null || style == null || widget.lines.isEmpty) return;
    final safeIndex = index.clamp(0, widget.lines.length - 1).toInt();
    final target = layout.lineOffsetY(
      safeIndex,
      safeIndex,
      layout.activeAnchorPosition,
      style.activeAlignment,
    );
    final safeTarget = _clampScrollY(layout, target, activeIndex: safeIndex);
    _animateScrollTo(
      safeTarget,
      duration: _scrollDurationFor((safeTarget - _paintState.scrollY).abs()),
      curve: style.scrollCurve,
    );
  }

  Duration _scrollDurationFor(double distance) {
    final style = _layoutStyle;
    if (style == null) return const Duration(milliseconds: 280);
    var duration = style.scrollDuration;
    for (final entry in style.scrollDurations.entries) {
      if (distance < entry.key) break;
      duration = entry.value;
    }
    return duration;
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
    final playIndex = (activeIndex ?? _paintState.activeIndex)
        .clamp(0, layout.metrics.length - 1)
        .toInt();
    final anchorPosition = layout.selectionAnchorPosition;
    final firstAnchorOffset = layout.anchorOffsetY(
      0,
      playIndex == 0,
      null,
      layout.style.selectionAlignment,
    );
    final contentHeight = layout.contentHeight(playIndex);
    final minimum =
        anchorPosition < layout.style.contentPadding.top ||
            contentHeight < anchorPosition
        ? -anchorPosition + firstAnchorOffset
        : -layout.style.contentPadding.top;
    final maximum = math.max(
      minimum,
      contentHeight - layout.style.contentPadding.top - anchorPosition,
    );
    return value.clamp(minimum, maximum).toDouble();
  }

  void _handleSystemFontsChange() {
    if (!mounted) return;
    setState(() {
      _layout = null;
      _layoutStyle = null;
    });
  }

  LyricStyle _style(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseStyle = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    return LyricStyle(
      textStyle: baseStyle,
      // Equal font metrics keep a line switch paint-only. Boldness and color
      // still identify the playing line without forcing text relayout.
      activeStyle: baseStyle.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w800,
      ),
      translationStyle: (theme.textTheme.bodySmall ?? const TextStyle())
          .copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.68),
            height: 1.2,
          ),
      translationActiveColor: scheme.primary.withValues(alpha: 0.78),
      lineTextAlign: TextAlign.left,
      contentAlignment: CrossAxisAlignment.start,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 44),
      lineGap: 25,
      translationLineGap: 3,
      selectionAnchorPosition: 0.5,
      activeAnchorPosition: 0.5,
      selectionAlignment: MainAxisAlignment.center,
      activeAlignment: MainAxisAlignment.center,
      selectedColor: scheme.primary,
      selectedTranslationColor: scheme.primary.withValues(alpha: 0.78),
      scrollDuration: const Duration(milliseconds: 280),
      scrollDurations: <double, Duration>{
        180: const Duration(milliseconds: 320),
        420: const Duration(milliseconds: 380),
        760: const Duration(milliseconds: 440),
      },
      scrollCurve: Curves.easeOutCubic,
      selectionAutoResumeDuration: const Duration(milliseconds: 240),
      activeAutoResumeDuration: _manualScrollIdle,
      selectionAutoResumeMode: SelectionAutoResumeMode.afterSelecting,
      activeHighlightColor: null,
      enableSwitchAnimation: false,
    );
  }

  LyricLayout _ensureLayout(ThemeData theme, LyricStyle style, Size size) {
    final cached = _layout;
    if (cached != null &&
        identical(_layoutTheme, theme) &&
        _layoutSize == size &&
        _layoutStyle?.compareTo(style) == RenderComparison.identical) {
      return cached;
    }
    _stopScrollAnimation();
    final computed = LyricLayout.compute(_model, style, size);
    _layout = computed;
    _layoutStyle = style;
    _layoutTheme = theme;
    _layoutSize = size;
    final activeIndex = _safeActualIndex;
    final target = computed.lineOffsetY(
      activeIndex,
      activeIndex,
      computed.activeAnchorPosition,
      style.activeAlignment,
    );
    _paintState.replace(
      activeIndex: activeIndex,
      scrollY: _clampScrollY(computed, target, activeIndex: activeIndex),
    );
    _manualScrolling = false;
    _manualTargetScrollY = null;
    return computed;
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
    _paintState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _style(context);
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
              child: Padding(
                padding: style.contentPadding.copyWith(top: 0, bottom: 0),
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
                    final layout = _ensureLayout(theme, style, size);
                    return CustomPaint(
                      painter: FlMoeLyricCanvasPainter._(
                        layout: layout,
                        style: layout.style,
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
    required this.style,
    required _LyricsPaintState paintState,
  }) : _paintState = paintState,
       _switchState = LyricLineSwitchState(
         exitAnimationValue: 1,
         enterAnimationValue: 1,
         exitIndex: -1,
         enterIndex: paintState.activeIndex,
       ),
       super(repaint: paintState);

  final LyricLayout layout;
  final LyricStyle style;
  final _LyricsPaintState _paintState;
  final LyricLineSwitchState _switchState;

  int get activeIndex => _paintState.activeIndex;
  double get scrollY => _paintState.scrollY;
  Map<int, Rect> get visibleLineRects =>
      Map<int, Rect>.unmodifiable(_paintState.visibleLineRects);

  @override
  void paint(Canvas canvas, Size size) {
    _switchState.enterIndex = _paintState.activeIndex;
    LyricPainter(
      layout: layout,
      playIndex: _paintState.activeIndex,
      scrollY: _paintState.scrollY,
      activeHighlightWidth: double.infinity,
      switchState: _switchState,
      isSelecting: false,
      style: style,
      onAnchorIndexChange: (_) {},
      onShowLineRectsChange: (rects) {
        _paintState.visibleLineRects = rects;
      },
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant FlMoeLyricCanvasPainter oldDelegate) =>
      !identical(layout, oldDelegate.layout) ||
      !identical(style, oldDelegate.style) ||
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
