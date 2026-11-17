import 'dart:async';
import 'dart:convert';

import 'package:fl_moe/app/app_theme.dart';
import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/features/auth/authentication_controller.dart';
import 'package:fl_moe/features/music/favorite_tracks_controller.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/features/music/user_playlists_controller.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/ui/pages/library_page/library_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets(
    'library embeds other playlists and favorite entry opens liked tracks',
    (tester) async {
      Get.testMode = true;
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Get.reset();
      });

      final backend = _LibraryFavoritesBackend();
      Get.put<AuthenticationController>(AuthenticationController(backend));
      Get.put<FavoriteTracksController>(FavoriteTracksController(backend));
      Get.put<UserPlaylistsController>(UserPlaylistsController(backend));
      Get.put<PlaybackController>(
        PlaybackController(backend, NoopAudioEngine(), MemoryKeyValueStore()),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
          home: const Scaffold(body: LibraryPage()),
        ),
      );
      await tester.pumpAndSettle();

      final favoriteCard = find.byKey(
        const ValueKey<String>('favorite-library-card'),
      );
      expect(favoriteCard, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('user-playlists-section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('user-playlist-list-77')),
        findsNothing,
      );
      expect(find.text('旅行歌单'), findsOneWidget);
      expect(find.text('收藏歌单'), findsOneWidget);
      expect(find.text('全部 2'), findsOneWidget);
      expect(find.text('我创建的 1'), findsOneWidget);
      expect(find.text('我收藏的 1'), findsOneWidget);
      expect(backend.routes, <String>['/user/playlist']);
      expect(
        tester.getCenter(find.text('我的收藏')).dy,
        lessThan(tester.getCenter(find.text('本地音乐')).dy),
      );
      expect(
        tester.getCenter(find.text('我的收藏')).dy,
        lessThan(tester.getCenter(find.text('我的云盘')).dy),
      );
      expect(
        tester.getCenter(find.text('旅行歌单')).dy,
        lessThan(tester.getCenter(find.text('本地音乐')).dy),
      );
      final image = tester.widget<Image>(
        find.descendant(of: favoriteCard, matching: find.byType(Image)),
      );
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/favorites.png',
      );

      await tester.tap(find.text('我创建的 1'));
      await tester.pumpAndSettle();
      expect(find.text('旅行歌单'), findsOneWidget);
      expect(find.text('收藏歌单'), findsNothing);

      await tester.tap(find.text('我收藏的 1'));
      await tester.pumpAndSettle();
      expect(find.text('旅行歌单'), findsNothing);
      expect(find.text('收藏歌单'), findsOneWidget);

      await tester.tap(favoriteCard);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('favorite-tracks-view')),
        findsOneWidget,
      );
      expect(find.text('我喜欢'), findsOneWidget);
      expect(find.text('第一首收藏'), findsOneWidget);
      expect(find.text('第二首收藏'), findsOneWidget);
      expect(
        tester.getCenter(find.text('第一首收藏')).dy,
        lessThan(tester.getCenter(find.text('第二首收藏')).dy),
      );
      expect(backend.routes, <String>[
        '/user/playlist',
        '/user/playlist',
        '/playlist/track/all',
      ]);
    },
  );

  testWidgets(
    'playlist network region shows skeleton without hiding local entries',
    (tester) async {
      Get.testMode = true;
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Get.reset();
      });

      final backend = _PendingLibraryPlaylistsBackend();
      Get.put<AuthenticationController>(AuthenticationController(backend));
      Get.put<FavoriteTracksController>(FavoriteTracksController(backend));
      Get.put<UserPlaylistsController>(UserPlaylistsController(backend));
      Get.put<PlaybackController>(
        PlaybackController(backend, NoopAudioEngine(), MemoryKeyValueStore()),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
          home: const Scaffold(body: LibraryPage()),
        ),
      );
      await tester.pump();

      expect(backend.routes, <String>['/user/playlist']);
      expect(
        find.byKey(const ValueKey<String>('library-playlists-skeleton')),
        findsOneWidget,
      );
      expect(find.text('我的收藏'), findsOneWidget);
      expect(find.text('本地音乐'), findsOneWidget);
      expect(find.text('我的云盘'), findsOneWidget);

      backend.completePlaylists();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('library-playlists-skeleton')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'recent history has one confirmed clear action before its count',
    (tester) async {
      Get.testMode = true;
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Get.reset();
      });

      const first = MusicTrack(
        id: 'recent-1',
        hash: 'RECENT-1',
        title: '最近歌曲一',
        artist: '测试歌手',
      );
      const second = MusicTrack(
        id: 'recent-2',
        hash: 'RECENT-2',
        title: '最近歌曲二',
        artist: '测试歌手',
      );
      final store = MemoryKeyValueStore(<String, Object?>{
        'recent_tracks': jsonEncode(<Object?>[first.toJson(), second.toJson()]),
      });
      const backend = _SignedOutLibraryBackend();
      Get.put<AuthenticationController>(AuthenticationController(backend));
      Get.put<FavoriteTracksController>(FavoriteTracksController(backend));
      Get.put<UserPlaylistsController>(UserPlaylistsController(backend));
      Get.put<PlaybackController>(
        PlaybackController(backend, NoopAudioEngine(), store),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
          home: const Scaffold(body: LibraryPage()),
        ),
      );

      final clearButton = find.byKey(
        const ValueKey<String>('clear-recent-tracks'),
      );
      final count = find.byKey(const ValueKey<String>('recent-tracks-count'));
      expect(clearButton, findsOneWidget);
      expect(
        tester.getCenter(clearButton).dx,
        lessThan(tester.getCenter(count).dx),
      );
      expect(find.text('2 首'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('delete-recent-RECENT-1')),
        findsNothing,
      );

      await tester.tap(clearButton);
      await tester.pumpAndSettle();
      expect(find.text('清空最近播放？'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('cancel-list-clear')));
      await tester.pumpAndSettle();
      expect(find.text('最近歌曲一'), findsOneWidget);
      expect(find.text('最近歌曲二'), findsOneWidget);
      expect(store.read('recent_tracks'), isNotNull);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('confirm-list-clear')),
      );
      await tester.pumpAndSettle();
      expect(find.text('还没有播放记录'), findsOneWidget);
      expect(store.read('recent_tracks'), isNull);
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
                'list_create_userid': 123456,
                'count': 2,
              },
              <String, Object?>{
                'name': '旅行歌单',
                'listid': 78,
                'list_create_gid': 'travel-collection',
                'list_create_userid': 123456,
                'count': 18,
              },
              <String, Object?>{
                'name': '收藏歌单',
                'listid': 79,
                'list_create_gid': 'collected-collection',
                'list_create_userid': 999,
                'count': 24,
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

final class _PendingLibraryPlaylistsBackend implements MusicBackend {
  final List<String> routes = <String>[];
  final Completer<KugouResponse<KugouJsonObject>> _playlists =
      Completer<KugouResponse<KugouJsonObject>>();

  void completePlaylists() {
    _playlists.complete(
      const KugouResponse<KugouJsonObject>(
        status: 1,
        httpStatus: 200,
        body: <String, Object?>{
          'data': <String, Object?>{'info': <Object?>[]},
        },
      ),
    );
  }

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
  }) {
    if (route != '/user/playlist') {
      throw StateError('Unexpected route: $route');
    }
    routes.add(route);
    return _playlists.future;
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

final class _SignedOutLibraryBackend implements MusicBackend {
  const _SignedOutLibraryBackend();

  @override
  KugouClientVariant get clientVariant => KugouClientVariant.lite;

  @override
  BackendSessionState get sessionState => const BackendSessionState(
    isLoggedIn: false,
    userId: '0',
    hasRegisteredDevice: false,
  );

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) => throw StateError('Unexpected route: $route');

  @override
  Future<void> clearAuthentication() async {}

  @override
  Future<void> close() async {}

  @override
  Future<bool> ensureDeviceRegistered() async => false;

  @override
  Future<void> flushSession() async {}

  @override
  Future<void> setClientVariant(KugouClientVariant variant) async {}
}
