import 'dart:async';

import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/core/window/desktop_window_service.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/features/navigation/app_navigation_controller.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/lyrics_controller.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/ui/pages/now_playing_page/now_playing_page.dart';
import 'package:fl_moe/ui/pages/now_playing_page/widgets/lyrics_panel.dart';
import 'package:fl_moe/ui/player_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets(
    'details and lyrics load only after the player summary is clicked',
    (tester) async {
      Get.testMode = true;
      await tester.binding.setSurfaceSize(const Size(1200, 760));
      final backend = _NowPlayingBackend();
      final engine = _NowPlayingAudioEngine();
      final player = PlaybackController(backend, engine, MemoryKeyValueStore());
      final navigation = AppNavigationController();
      final lyrics = LyricsController(backend);
      addTearDown(() async {
        player.onClose();
        Get.reset();
        await tester.binding.setSurfaceSize(null);
      });
      Get.put<PlaybackController>(player);
      Get.put<AppNavigationController>(navigation);
      Get.put<LyricsController>(lyrics);
      await player.playTrack(
        const MusicTrack(
          id: '1',
          hash: 'TRACK_HASH',
          title: '测试歌曲',
          artist: '测试歌手',
          coverUrl: '',
          duration: Duration(minutes: 3),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: GetBuilder<AppNavigationController>(
              builder: (value) => Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: PlayerBar(),
                  ),
                  if (value.nowPlayingVisible)
                    const Positioned.fill(
                      child: NowPlayingPage(window: NoopDesktopWindowService()),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('now-playing-page')),
        findsNothing,
      );
      expect(backend.routes, <String>['/song/url']);
      expect(
        find.byKey(const ValueKey<String>('current-playback-quality')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('open-now-playing-details')),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('now-playing-page')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('now-playing-page'))),
        const Size(1200, 760),
      );
      expect(
        find.byKey(const ValueKey<String>('now-playing-window-drag-region')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('now-playing-play-pause')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('now-playing-background-base')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('now-playing-background-blur')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('now-playing-background-tint')),
        findsOneWidget,
      );
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(backend.routes, <String>['/song/url', '/search/lyric', '/lyric']);

      final blur = find.byKey(
        const ValueKey<String>('now-playing-background-blur'),
      );
      final lyricList = find.byKey(
        const ValueKey<String>('now-playing-lyrics-list'),
      );
      final lyricPainter = tester
          .widgetList<CustomPaint>(
            find.descendant(of: lyricList, matching: find.byType(CustomPaint)),
          )
          .map((widget) => widget.painter)
          .whereType<FlMoeLyricCanvasPainter>()
          .single;
      expect(lyricPainter.layout.metrics.single.line.text, '测试歌词');
      expect(
        lyricPainter.style.contentPadding,
        const EdgeInsets.symmetric(horizontal: 18, vertical: 44),
      );
      expect(lyricPainter.style.lineTextAlign, TextAlign.left);
      expect(lyricPainter.style.contentAlignment, CrossAxisAlignment.start);
      expect(lyricPainter.style.lineGap, 25);
      expect(lyricPainter.style.translationLineGap, 3);
      expect(lyricPainter.style.activeAnchorPosition, 0.5);
      expect(lyricPainter.style.textStyle.fontWeight, FontWeight.w600);
      expect(lyricPainter.style.activeStyle.fontWeight, FontWeight.w800);
      expect(
        find.descendant(of: lyricList, matching: find.byType(Scrollable)),
        findsNothing,
      );
      final blurBeforePositionTick = tester.widget(blur);
      final lyricsBeforePositionTick = tester.widget(lyricList);
      engine.emitPosition(const Duration(milliseconds: 500));
      await tester.pump();
      expect(
        tester.widget(blur),
        same(blurBeforePositionTick),
        reason: 'position ticks must not rebuild the blurred page background',
      );
      expect(
        tester.widget(lyricList),
        same(lyricsBeforePositionTick),
        reason: 'sub-line ticks must not rebuild the complete lyrics list',
      );

      await tester.tap(find.byKey(const ValueKey<String>('close-now-playing')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('now-playing-page')),
        findsNothing,
      );
    },
  );
}

final class _NowPlayingAudioEngine implements AudioEngine {
  final StreamController<bool> _playing = StreamController<bool>.broadcast(
    sync: true,
  );
  final StreamController<bool> _buffering = StreamController<bool>.broadcast(
    sync: true,
  );
  final StreamController<bool> _completed = StreamController<bool>.broadcast(
    sync: true,
  );
  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast(sync: true);
  final StreamController<Duration> _duration =
      StreamController<Duration>.broadcast(sync: true);
  final StreamController<double> _volume = StreamController<double>.broadcast(
    sync: true,
  );
  final StreamController<String> _errors = StreamController<String>.broadcast(
    sync: true,
  );

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
  Future<void> seek(Duration position) async => emitPosition(position);

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

final class _NowPlayingBackend implements MusicBackend {
  final List<String> routes = <String>[];

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
  }) async {
    routes.add(route);
    return switch (route) {
      '/song/url' => const KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'status': 1,
          'url': <Object?>['https://audio.example/song.mp3'],
        },
      ),
      '/search/lyric' => const KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'status': 200,
          'candidates': <Object?>[
            <String, Object?>{'id': 'id', 'accesskey': 'key'},
          ],
        },
      ),
      '/lyric' => const KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'status': 200,
          'decodeContent': '[0,1000]<0,1000,0>测试歌词',
        },
      ),
      _ => throw UnsupportedError('Unexpected route: $route'),
    };
  }

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
