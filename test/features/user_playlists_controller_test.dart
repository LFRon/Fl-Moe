import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/features/music/user_playlists_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loads every page and classifies created, collected and album entries',
    () async {
      final backend = _UserPlaylistsBackend();
      final controller = UserPlaylistsController(backend);

      expect(controller.loaded, isFalse);
      expect(backend.calls, isEmpty);

      await controller.load();

      expect(backend.calls.map((call) => call.page), <int>[1, 2]);
      expect(backend.calls.map((call) => call.pageSize), everyElement(500));
      expect(
        controller.createdPlaylists.map((playlist) => playlist.title),
        <String>['我喜欢', '日常'],
      );
      expect(
        controller.collectedPlaylists.map((playlist) => playlist.title),
        <String>['收藏的歌单'],
      );
      expect(
        controller.allPlaylists.map((playlist) => playlist.title),
        <String>['我喜欢', '日常', '收藏的歌单'],
      );
      expect(controller.totalCount, 3);
      expect(controller.error, isNull);
      expect(controller.createdPlaylists.first.collection.accountListId, '1');
    },
  );

  test('does not request account playlists while signed out', () async {
    final backend = _UserPlaylistsBackend(loggedIn: false);
    final controller = UserPlaylistsController(backend);

    await controller.load();

    expect(backend.calls, isEmpty);
    expect(controller.allPlaylists, isEmpty);
    expect(controller.loaded, isFalse);
  });
}

typedef _PlaylistCall = ({int page, int pageSize});

final class _UserPlaylistsBackend implements MusicBackend {
  _UserPlaylistsBackend({this.loggedIn = true});

  final bool loggedIn;
  final List<_PlaylistCall> calls = <_PlaylistCall>[];

  @override
  KugouClientVariant get clientVariant => KugouClientVariant.lite;

  @override
  BackendSessionState get sessionState => BackendSessionState(
    isLoggedIn: loggedIn,
    userId: loggedIn ? '123456' : '0',
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
    final page = parameters['page'] as int;
    final pageSize = parameters['pagesize'] as int;
    calls.add((page: page, pageSize: pageSize));
    return KugouResponse<KugouJsonObject>(
      status: 1,
      httpStatus: 200,
      body: <String, Object?>{
        'data': <String, Object?>{
          'total': 4,
          'info': page == 1
              ? <Object?>[
                  <String, Object?>{
                    'name': '日常',
                    'listid': 2,
                    'list_create_gid': 'daily',
                    'list_create_userid': 123456,
                    'count': 12,
                    'sort': 2,
                  },
                  <String, Object?>{
                    'name': '收藏的专辑',
                    'listid': 4,
                    'global_collection_id': 'album',
                    'list_create_userid': 999,
                    'authors': <Object?>[],
                    'sort': 1,
                  },
                ]
              : <Object?>[
                  <String, Object?>{
                    'name': '收藏的歌单',
                    'listid': 3,
                    'global_collection_id': 'collected',
                    'list_create_userid': 999,
                    'count': 8,
                    'sort': 3,
                  },
                  <String, Object?>{
                    'name': '我喜欢',
                    'listid': 1,
                    'list_create_gid': 'favorite',
                    'list_create_userid': 123456,
                    'count': 20,
                    'sort': 99,
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
