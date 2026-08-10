import 'package:fl_moe/app/app_theme.dart';
import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/features/auth/authentication_controller.dart';
import 'package:fl_moe/features/music/favorite_tracks_controller.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/ui/pages/library_page/library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets(
    'favorite entry is above local cards and loads only when opened',
    (tester) async {
      Get.testMode = true;
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Get.reset();
      });

      final backend = _LibraryFavoritesBackend();
      Get.put<AuthenticationController>(AuthenticationController(backend));
      Get.put<FavoriteTracksController>(FavoriteTracksController(backend));
      Get.put<PlaybackController>(
        PlaybackController(backend, NoopAudioEngine(), MemoryKeyValueStore()),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
          home: const Scaffold(body: LibraryPage()),
        ),
      );

      final favoriteCard = find.byKey(
        const ValueKey<String>('favorite-library-card'),
      );
      expect(favoriteCard, findsOneWidget);
      expect(backend.routes, isEmpty);
      expect(
        tester.getCenter(find.text('我的收藏')).dy,
        lessThan(tester.getCenter(find.text('本地音乐')).dy),
      );
      expect(
        tester.getCenter(find.text('我的收藏')).dy,
        lessThan(tester.getCenter(find.text('我的云盘')).dy),
      );
      final image = tester.widget<Image>(
        find.descendant(of: favoriteCard, matching: find.byType(Image)),
      );
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/favorites.png',
      );

      await tester.tap(favoriteCard);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('favorite-tracks-view')),
        findsOneWidget,
      );
      expect(find.text('第一首收藏'), findsOneWidget);
      expect(find.text('第二首收藏'), findsOneWidget);
      expect(
        tester.getCenter(find.text('第一首收藏')).dy,
        lessThan(tester.getCenter(find.text('第二首收藏')).dy),
      );
      expect(backend.routes, <String>['/user/playlist', '/playlist/track/all']);
    },
  );
}

final class _LibraryFavoritesBackend implements MusicBackend {
  final List<String> routes = <String>[];

  @override
  KugouClientVariant get clientVariant => KugouClientVariant.lite;

  @override
  BackendSessionState get sessionState => const BackendSessionState(
    isLoggedIn: true,
    userId: '123456',
    hasRegisteredDevice: true,
  );

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) async {
    routes.add(route);
    return switch (route) {
      '/user/playlist' => const KugouResponse<KugouJsonObject>(
        status: 1,
        httpStatus: 200,
        body: <String, Object?>{
          'data': <String, Object?>{
            'info': <Object?>[
              <String, Object?>{
                'name': '我喜欢',
                'listid': 77,
                'list_create_gid': 'favorite-collection',
                'count': 2,
              },
            ],
          },
        },
      ),
      '/playlist/track/all' => const KugouResponse<KugouJsonObject>(
        status: 1,
        httpStatus: 200,
        body: <String, Object?>{
          'data': <String, Object?>{
            'total': 2,
            'songs': <Object?>[
              <String, Object?>{
                'hash': 'FAVORITE-1',
                'audio_name': '第一首收藏',
                'author_name': '测试歌手',
                'duration': 180,
              },
              <String, Object?>{
                'hash': 'FAVORITE-2',
                'audio_name': '第二首收藏',
                'author_name': '测试歌手',
                'duration': 210,
              },
            ],
          },
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
