import 'package:fl_moe/app/app_theme.dart';
import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/features/music/music_catalog_controller.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/features/navigation/app_navigation_controller.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/ui/pages/collection_detail_page/collection_detail_page.dart';
import 'package:fl_moe/ui/widgets/song_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('large playlist builds only its visible song rows', (
    tester,
  ) async {
    Get.testMode = true;
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });

    final backend = _LargePlaylistBackend();
    final detail = MusicCollectionDetailController(backend);
    final navigation = AppNavigationController();
    final player = PlaybackController(
      backend,
      NoopAudioEngine(),
      MemoryKeyValueStore(),
    );
    addTearDown(player.onClose);
    Get.put<MusicCollectionDetailController>(detail);
    Get.put<AppNavigationController>(navigation);
    Get.put<PlaybackController>(player);

    const collection = MusicCollection(
      id: 'large-playlist',
      title: 'Large playlist',
      kind: MusicCollectionKind.playlist,
    );
    navigation.openCollection(collection);
    await detail.load(collection);

    await tester.pumpWidget(
      MaterialApp(
        theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
        home: const Scaffold(body: CollectionDetailPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Large playlist'), findsOneWidget);
    expect(find.text('100 首'), findsOneWidget);
    final visibleRows = find.byType(SongListItem).evaluate().length;
    expect(
      visibleRows,
      lessThan(40),
      reason: 'a 100-track playlist must not build every row at once',
    );
    expect(visibleRows, greaterThan(0));
  });
}

final class _LargePlaylistBackend implements MusicBackend {
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
    if (route != '/playlist/track/all') {
      throw StateError('Unexpected route: $route');
    }
    return KugouResponse<KugouJsonObject>(
      status: 200,
      httpStatus: 200,
      body: <String, Object?>{
        'data': <String, Object?>{
          'total': 100,
          'songs': <Object?>[
            for (var index = 0; index < 100; index += 1)
              <String, Object?>{
                'hash': 'HASH-$index',
                'audio_name': 'Track $index',
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
