import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/features/music/music_catalog_controller.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'private user playlist falls back to its account-scoped list id',
    () async {
      final backend = _PrivatePlaylistBackend();
      final controller = MusicCollectionDetailController(backend);

      final tracks = await controller.fetchTracks(
        const MusicCollection(
          id: 'public-id',
          accountListId: 'account-list-id',
          title: '私密歌单',
          kind: MusicCollectionKind.playlist,
        ),
      );

      expect(backend.routes, <String>[
        '/playlist/track/all',
        '/playlist/track/all/new',
      ]);
      expect(backend.lastPrivateListId, 'account-list-id');
      expect(tracks.single.title, '私密歌曲');
    },
  );
}

final class _PrivatePlaylistBackend implements MusicBackend {
  final List<String> routes = <String>[];
  String lastPrivateListId = '';

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
    if (route == '/playlist/track/all') {
      return const KugouResponse<KugouJsonObject>(
        status: 1,
        httpStatus: 200,
        body: <String, Object?>{
          'data': <String, Object?>{'songs': <Object?>[]},
        },
      );
    }
    if (route == '/playlist/track/all/new') {
      lastPrivateListId = parameters['listid'] as String;
      return const KugouResponse<KugouJsonObject>(
        status: 1,
        httpStatus: 200,
        body: <String, Object?>{
          'data': <String, Object?>{
            'songs': <Object?>[
              <String, Object?>{
                'hash': 'PRIVATE-HASH',
                'audio_name': '私密歌曲',
                'author_name': '测试歌手',
              },
            ],
          },
        },
      );
    }
    throw StateError('Unexpected route: $route');
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
