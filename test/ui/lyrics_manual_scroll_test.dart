import 'dart:async';

import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/lyrics_controller.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/ui/pages/now_playing_page/widgets/lyrics_panel.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('manual lyric scrolling wins until one second of inactivity', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(720, 420));
    final backend = _LyricsScrollBackend();
    final engine = _ControllableAudioEngine();
    final player = PlaybackController(backend, engine, MemoryKeyValueStore());
    final lyrics = LyricsController(backend);
    addTearDown(() async {
      player.onClose();
      Get.reset();
      await tester.binding.setSurfaceSize(null);
    });
    Get.put<PlaybackController>(player);
    Get.put<LyricsController>(lyrics);

    const track = MusicTrack(
      id: '1',
      hash: 'LYRICS-HASH',
      title: '滚动测试',
      artist: '测试歌手',
      duration: Duration(seconds: 40),
    );
    await player.playTrack(track);
    await lyrics.loadFor(track);
    engine.emitPosition(const Duration(seconds: 12));

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: GetBuilder<PlaybackController>(
            builder: (playback) => GetBuilder<LyricsController>(
              builder: (lyricsController) =>
                  LyricsPanel(lyrics: lyricsController, player: playback),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final list = find.byKey(const ValueKey<String>('now-playing-lyrics-list'));
    expect(list, findsOneWidget);
    expect(_activeLyricIndex(tester, list), 12);
    final initialScrollY = _lyricPainter(tester, list).scrollY;
    expect(
      find.descendant(of: list, matching: find.byType(Scrollable)),
      findsNothing,
      reason: 'the canvas lyric renderer must not recreate a scrollable list',
    );
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(list, warnIfMissed: true),
        kind: PointerDeviceKind.mouse,
        scrollDelta: const Offset(0, -400),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final manualScrollY = _lyricPainter(tester, list).scrollY;
    expect(manualScrollY, lessThan(initialScrollY));
    expect(
      _activeLyricIndex(tester, list),
      12,
      reason: 'manual scrolling must not pretend another line is playing',
    );

    engine.emitPosition(const Duration(seconds: 25));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(_activeLyricIndex(tester, list), 25);
    expect(
      _lyricPainter(tester, list).scrollY,
      closeTo(manualScrollY, 0.01),
      reason: 'the viewport must stay under manual control during its grace',
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 120));
    final resumedScrollY = _lyricPainter(tester, list).scrollY;
    expect(
      resumedScrollY,
      isNot(closeTo(manualScrollY, 0.01)),
      reason: 'auto-follow must begin after one idle second',
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(_activeLyricIndex(tester, list), 25);
  });

  testWidgets('clicking a lyric immediately overrides manual-scroll grace', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(720, 420));
    final backend = _LyricsScrollBackend();
    final seekGate = Completer<void>();
    final engine = _ControllableAudioEngine(seekGate: seekGate);
    final player = PlaybackController(backend, engine, MemoryKeyValueStore());
    final lyrics = LyricsController(backend);
    addTearDown(() async {
      player.onClose();
      Get.reset();
      await tester.binding.setSurfaceSize(null);
    });
    Get.put<PlaybackController>(player);
    Get.put<LyricsController>(lyrics);

    const track = MusicTrack(
      id: '1',
      hash: 'LYRICS-HASH',
      title: '滚动测试',
      artist: '测试歌手',
      duration: Duration(seconds: 40),
    );
    await player.playTrack(track);
    await lyrics.loadFor(track);
    engine.emitPosition(const Duration(seconds: 12));

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: GetBuilder<PlaybackController>(
            builder: (playback) => GetBuilder<LyricsController>(
              builder: (lyricsController) =>
                  LyricsPanel(lyrics: lyricsController, player: playback),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final list = find.byKey(const ValueKey<String>('now-playing-lyrics-list'));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(list, warnIfMissed: true),
        kind: PointerDeviceKind.mouse,
        scrollDelta: const Offset(0, -400),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final scrollBeforeTap = _lyricPainter(tester, list).scrollY;
    final layoutBeforeTap = _lyricPainter(tester, list).layout;

    final viewTopLeft = tester.getTopLeft(list);
    final viewSize = tester.getSize(list);
    final targetEntry = _lyricPainter(tester, list).visibleLineRects.entries
        .firstWhere(
          (entry) =>
              entry.key != _activeLyricIndex(tester, list) &&
              entry.value.center.dy > 1 &&
              entry.value.center.dy < viewSize.height - 1,
        );
    await tester.tapAt(
      viewTopLeft + Offset(viewSize.width / 2, targetEntry.value.center.dy),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(engine.seekTargets, hasLength(1));
    final target = engine.seekTargets.single;
    expect(target, Duration(seconds: targetEntry.key));
    expect(player.position, target);
    await tester.pump(const Duration(milliseconds: 180));
    expect(
      _lyricPainter(tester, list).layout,
      same(layoutBeforeTap),
      reason: 'a lyric click must reuse cached text layout',
    );

    expect(
      _activeLyricIndex(tester, list),
      target.inSeconds,
      reason:
          'an explicit lyric click must switch immediately instead '
          'of waiting for manual-scroll timeout or native seek completion',
    );
    expect(
      _lyricPainter(tester, list).scrollY,
      isNot(scrollBeforeTap),
      reason: 'canvas scrolling must keep advancing while seek is pending',
    );

    seekGate.complete();
    await tester.pump();
  });
}

int _activeLyricIndex(WidgetTester tester, Finder lyricView) =>
    _lyricPainter(tester, lyricView).activeIndex;

FlMoeLyricCanvasPainter _lyricPainter(WidgetTester tester, Finder lyricView) =>
    tester
        .widgetList<CustomPaint>(
          find.descendant(of: lyricView, matching: find.byType(CustomPaint)),
        )
        .map((widget) => widget.painter)
        .whereType<FlMoeLyricCanvasPainter>()
        .single;

final class _ControllableAudioEngine implements AudioEngine {
  _ControllableAudioEngine({this.seekGate});

  final Completer<void>? seekGate;
  final StreamController<bool> _playing = StreamController<bool>.broadcast();
  final StreamController<bool> _buffering = StreamController<bool>.broadcast();
  final StreamController<bool> _completed = StreamController<bool>.broadcast();
  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _duration =
      StreamController<Duration>.broadcast();
  final StreamController<double> _volume = StreamController<double>.broadcast();
  final StreamController<String> _errors = StreamController<String>.broadcast();
  final List<Duration> seekTargets = <Duration>[];

  void emitPosition(Duration value) => _position.add(value);

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<bool> get buffering => _buffering.stream;

  @override
  Stream<bool> get completed => _completed.stream;

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<Duration> get duration => _duration.stream;

  @override
  Stream<double> get volume => _volume.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  Future<void> open(Uri uri) async {}

  @override
  Future<void> playOrPause() async {}

  @override
  Future<void> replay() async {}

  @override
  Future<void> seek(Duration position) async {
    seekTargets.add(position);
    final gate = seekGate;
    if (gate != null) await gate.future;
    emitPosition(position);
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await Future.wait<void>(<Future<void>>[
      _playing.close(),
      _buffering.close(),
      _completed.close(),
      _position.close(),
      _duration.close(),
      _volume.close(),
      _errors.close(),
    ]);
  }
}

final class _LyricsScrollBackend implements MusicBackend {
  @override
  KugouClientVariant get clientVariant => KugouClientVariant.lite;

  @override
  BackendSessionState get sessionState => const BackendSessionState(
    isLoggedIn: false,
    userId: '0',
    hasRegisteredDevice: true,
  );

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) async => switch (route) {
    '/song/url' => const KugouResponse<KugouJsonObject>(
      status: 1,
      httpStatus: 200,
      body: <String, Object?>{
        'url': <Object?>['https://audio.example/lyrics.mp3'],
      },
    ),
    '/search/lyric' => const KugouResponse<KugouJsonObject>(
      status: 1,
      httpStatus: 200,
      body: <String, Object?>{
        'candidates': <Object?>[
          <String, Object?>{'id': 'lyrics-id', 'accesskey': 'lyrics-key'},
        ],
      },
    ),
    '/lyric' => KugouResponse<KugouJsonObject>(
      status: 1,
      httpStatus: 200,
      body: <String, Object?>{'decodeContent': _timedLyrics()},
    ),
    _ => throw StateError('Unexpected route: $route'),
  };

  @override
  Future<void> clearAuthentication() async {}

  @override
  Future<void> close() async {}

  @override
  Future<bool> ensureDeviceRegistered() async => true;

  @override
  Future<void> flushSession() async {}

  @override
  Future<void> setClientVariant(KugouClientVariant variant) async {}
}

String _timedLyrics() => <String>[
  for (var second = 0; second < 40; second += 1)
    '[${second * 1000},1000]<0,1000,0>第 $second 行歌词',
].join('\n');
