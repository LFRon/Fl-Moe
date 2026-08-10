import 'package:fl_moe/app/app_theme.dart';
import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/features/music/music_catalog_controller.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/features/navigation/app_navigation_controller.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/ui/widgets/collection_grid.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets(
    'collection quick play starts the first song without navigating',
    (tester) async {
      Get.testMode = true;
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Get.reset();
      });

      final backend = _CollectionPlaybackBackend();
      final navigation = AppNavigationController()..goTo(AppSection.discover);
      final detail = MusicCollectionDetailController(backend);
      final player = PlaybackController(
        backend,
        NoopAudioEngine(),
        MemoryKeyValueStore(),
      );
      Get.put<AppNavigationController>(navigation);
      Get.put<MusicCollectionDetailController>(detail);
      Get.put<PlaybackController>(player);

      const collection = MusicCollection(
        id: 'playlist-1',
        title: '测试歌单',
        kind: MusicCollectionKind.playlist,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
          home: const Scaffold(
            body: CollectionGrid(collections: <MusicCollection>[collection]),
          ),
        ),
      );

      final card = find.byKey(const ValueKey<String>('playlist:playlist-1'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(card));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byTooltip('播放《测试歌单》'));
      await tester.pumpAndSettle();

      expect(navigation.section, AppSection.discover);
      expect(navigation.selectedCollection, isNull);
      expect(detail.collection, isNull);
      expect(player.currentTrack?.hash, 'FIRST');
      expect(player.queue.map((track) => track.hash), <String>[
        'FIRST',
        'SECOND',
      ]);
      expect(backend.routes, <String>['/playlist/track/all', '/song/url']);
    },
  );
}

final class _CollectionPlaybackBackend implements MusicBackend {
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
      '/playlist/track/all' => const KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'data': <String, Object?>{
            'songlist': <Object?>[
              <String, Object?>{
                'audio_id': 1,
                'hash': 'FIRST',
                'audio_name': '第一首歌',
                'author_name': '测试歌手',
              },
              <String, Object?>{
                'audio_id': 2,
                'hash': 'SECOND',
                'audio_name': '第二首歌',
                'author_name': '测试歌手',
              },
            ],
          },
        },
      ),
      '/song/url' => const KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'url': <Object?>['https://audio.example/first.mp3'],
        },
      ),
      _ => throw StateError('Unexpected route: $route'),
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
