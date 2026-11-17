import 'dart:async';
import 'dart:convert';

import 'package:fl_moe/app/app_theme.dart';
import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/features/auth/authentication_controller.dart';
import 'package:fl_moe/features/music/favorite_tracks_controller.dart';
import 'package:fl_moe/features/music/music_catalog_controller.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/features/music/user_playlists_controller.dart';
import 'package:fl_moe/features/navigation/app_navigation_controller.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/ui/pages/library_page/library_page.dart';
import 'package:fl_moe/ui/pages/library_page/widgets/library_card.dart';
import 'package:fl_moe/ui/pages/library_page/widgets/user_playlist_card.dart';
import 'package:fl_moe/ui/pages/search_page/search_page.dart';
import 'package:fl_moe/ui/player_bar.dart';
import 'package:fl_moe/ui/widgets/collection_grid.dart';
import 'package:fl_moe/ui/widgets/network_artwork.dart';
import 'package:fl_moe/ui/widgets/song_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'library lazily builds recent rows and ignores playback position ticks',
    (tester) async {
      Get.testMode = true;
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Get.reset();
      });

      final recent = <Object?>[
        for (var index = 0; index < 50; index += 1)
          const MusicTrack(
            id: 'recent',
            hash: 'HASH',
            title: 'Recent track',
            artist: 'Artist',
          ).toJson(),
      ];
      final store = MemoryKeyValueStore(<String, Object?>{
        'recent_tracks': jsonEncode(recent),
      });
      const backend = _PerfBackend();
      final engine = _TestAudioEngine();
      final player = PlaybackController(backend, engine, store);
      addTearDown(player.onClose);
      Get.put<AuthenticationController>(AuthenticationController(backend));
      Get.put<FavoriteTracksController>(FavoriteTracksController(backend));
      Get.put<UserPlaylistsController>(UserPlaylistsController(backend));
      Get.put<PlaybackController>(player);

      await tester.pumpWidget(
        MaterialApp(
          theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
          home: const Scaffold(body: LibraryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50 首'), findsOneWidget);
      final visibleRows = find.byType(SongListItem).evaluate().length;
      expect(
        visibleRows,
        greaterThan(0),
        reason: 'the first recent rows must remain visible',
      );
      expect(
        visibleRows,
        lessThan(40),
        reason: 'a 50-track history must not build every row at once',
      );

      final favoriteCard = tester.widget<LibraryCard>(
        find.byKey(const ValueKey<String>('favorite-library-card')),
      );
      engine.emitPosition(const Duration(seconds: 1));
      await tester.pump();
      expect(
        tester.widget<LibraryCard>(
          find.byKey(const ValueKey<String>('favorite-library-card')),
        ),
        same(favoriteCard),
        reason: 'position ticks must not rebuild the library overview',
      );
    },
  );

  testWidgets('playlist grid builds only visible cards', (tester) async {
    Get.testMode = true;
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });

    const backend = _PlaylistPerfBackend();
    final player = PlaybackController(
      backend,
      _TestAudioEngine(),
      MemoryKeyValueStore(),
    );
    addTearDown(player.onClose);
    Get.put<AuthenticationController>(AuthenticationController(backend));
    Get.put<FavoriteTracksController>(FavoriteTracksController(backend));
    Get.put<UserPlaylistsController>(UserPlaylistsController(backend));
    Get.put<PlaybackController>(player);

    await tester.pumpWidget(
      MaterialApp(
        theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
        home: const Scaffold(body: LibraryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('共 120 个其他歌单'), findsOneWidget);
    final visibleCards = find.byType(UserPlaylistCard).evaluate().length;
    expect(visibleCards, greaterThan(0));
    expect(
      visibleCards,
      lessThan(120),
      reason: 'a 120-playlist account must not build every card at once',
    );
  });

  testWidgets('sliver collection grids build only visible cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final collections = <MusicCollection>[
      for (var index = 0; index < 200; index += 1)
        MusicCollection(
          id: 'collection-$index',
          title: 'Collection $index',
          kind: MusicCollectionKind.playlist,
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.all(28),
                sliver: SliverCollectionGrid(collections: collections),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final visibleCards = find.byType(NetworkArtwork).evaluate().length;
    expect(visibleCards, greaterThan(0));
    expect(
      visibleCards,
      lessThan(200),
      reason: 'a 200-card grid must only build the cards near the viewport',
    );
  });

  testWidgets('search results are built lazily', (tester) async {
    Get.testMode = true;
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });

    const backend = _PerfBackend();
    final player = PlaybackController(
      backend,
      _TestAudioEngine(),
      MemoryKeyValueStore(),
    );
    addTearDown(player.onClose);
    final search = MusicSearchController(backend);
    final catalog = MusicCatalogController(backend);
    final navigation = AppNavigationController();
    Get.put<PlaybackController>(player);
    Get.put<MusicSearchController>(search);
    Get.put<MusicCatalogController>(catalog);
    Get.put<AppNavigationController>(navigation);

    await search.search('perf');
    await tester.pumpWidget(
      MaterialApp(
        theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
        home: const Scaffold(body: SearchPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('40 首'), findsOneWidget);
    final visibleRows = find.byType(SongListItem).evaluate().length;
    expect(visibleRows, greaterThan(0));
    expect(
      visibleRows,
      lessThan(40),
      reason: 'a 40-result search must not build every row at once',
    );
  });

  testWidgets('volume changes do not rebuild the transport controls', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(1200, 600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      Get.reset();
    });
    final player = PlaybackController(
      const _PerfBackend(),
      _TestAudioEngine(),
      MemoryKeyValueStore(),
    );
    addTearDown(player.onClose);
    Get.put<PlaybackController>(player);
    Get.put<AppNavigationController>(AppNavigationController());

    await tester.pumpWidget(
      MaterialApp(
        theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
        home: const Scaffold(body: PlayerBar()),
      ),
    );

    final previousFinder = find.widgetWithIcon(
      IconButton,
      Icons.skip_previous_rounded,
    );
    final previousButton = tester.widget<IconButton>(previousFinder);
    await player.setVolume(42);
    await tester.pump();

    expect(
      tester
          .widget<Slider>(
            find.byKey(const ValueKey<String>('player-volume-slider')),
          )
          .value,
      42,
    );
    expect(
      tester.widget<IconButton>(previousFinder),
      same(previousButton),
      reason: 'dragging volume must not rebuild the whole player bar',
    );
  });
}

final class _PerfBackend implements MusicBackend {
  const _PerfBackend();

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
    if (route != '/search') {
      throw StateError('Unexpected route: $route');
    }
    return KugouResponse<KugouJsonObject>(
      status: 200,
      httpStatus: 200,
      body: <String, Object?>{
        'data': <String, Object?>{
          'lists': <Object?>[
            for (var index = 0; index < 40; index += 1)
              <String, Object?>{
                'hash': 'SEARCH-$index',
                'audio_name': 'Search track $index',
                'author_name': 'Artist',
                'duration': 180,
              },
          ],
        },
      },
    );
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

final class _PlaylistPerfBackend implements MusicBackend {
  const _PlaylistPerfBackend();

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
    if (route != '/user/playlist') {
      throw StateError('Unexpected route: $route');
    }
    return KugouResponse<KugouJsonObject>(
      status: 200,
      httpStatus: 200,
      body: <String, Object?>{
        'data': <String, Object?>{
          'total': 120,
          'info': <Object?>[
            for (var index = 0; index < 120; index += 1)
              <String, Object?>{
                'listid': '${1000 + index}',
                'list_create_userid': '123456',
                'name': 'Playlist ${index + 1}',
                'count': 10,
                'sort': index,
              },
          ],
        },
      },
    );
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

final class _TestAudioEngine implements AudioEngine {
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
  Future<void> setVolume(double volume) async => _volume.add(volume);

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
