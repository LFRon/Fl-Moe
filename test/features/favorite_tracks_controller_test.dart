import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/features/music/favorite_tracks_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('favorite tracks follow the original global collection order', () async {
    final backend = _FavoriteBackend();
    final controller = FavoriteTracksController(backend);

    expect(backend.calls, isEmpty);
    expect(controller.loaded, isFalse);

    await controller.load();

    expect(backend.routes, <String>['/user/playlist', '/playlist/track/all']);
    expect(controller.tracks.map((track) => track.hash), <String>[
      'HASH-1',
      'HASH-2',
    ]);
    expect(controller.totalCount, 3);
    expect(controller.hasMore, isTrue);
    expect(backend.calls[1].parameters, <String, Object?>{
      'id': 'collection-like',
      'page': 1,
      'pagesize': 100,
    });

    await controller.loadMore();

    expect(controller.tracks.map((track) => track.hash), <String>[
      'HASH-1',
      'HASH-2',
      'HASH-3',
    ]);
    expect(controller.hasMore, isFalse);
    expect(backend.calls.last.parameters['page'], 2);
  });

  test(
    'favorite tracks do not request account APIs while signed out',
    () async {
      final backend = _FavoriteBackend(loggedIn: false);
      final controller = FavoriteTracksController(backend);

      await controller.load();

      expect(backend.calls, isEmpty);
      expect(controller.tracks, isEmpty);
      expect(controller.loaded, isFalse);
    },
  );

  test(
    'global collection id is used when a user playlist has no listid',
    () async {
      final backend = _FavoriteBackend(useCollectionIdOnly: true);
      final controller = FavoriteTracksController(backend);

      await controller.load();

      expect(backend.routes, <String>['/user/playlist', '/playlist/track/all']);
      expect(backend.calls.last.parameters['id'], 'collection-like');
    },
  );

  test('private list backs up a rejected global-collection request', () async {
    final backend = _FavoriteBackend(failGlobalTracks: true);
    final controller = FavoriteTracksController(backend);

    await controller.load();

    expect(backend.routes, <String>[
      '/user/playlist',
      '/playlist/track/all',
      '/playlist/track/all/new',
    ]);
    expect(controller.tracks.map((track) => track.hash), <String>[
      'HASH-2',
      'HASH-1',
    ]);
    expect(controller.error, isNull);
  });

  test(
    'reversed private fallback starts at the last page and only appends',
    () async {
      final backend = _PrivatePagedFavoriteBackend();
      final controller = FavoriteTracksController(backend);

      await controller.load();

      expect(backend.requestedTrackPages, <int>[1, 3]);
      expect(controller.tracks.first.hash, 'HASH-205');
      expect(controller.tracks.last.hash, 'HASH-201');
      expect(controller.tracks, hasLength(5));
      expect(controller.hasMore, isTrue);

      await controller.loadMore();

      expect(backend.requestedTrackPages, <int>[1, 3, 2]);
      expect(controller.tracks.first.hash, 'HASH-205');
      expect(controller.tracks[5].hash, 'HASH-200');
      expect(controller.tracks.last.hash, 'HASH-101');
      expect(controller.tracks, hasLength(105));

      await controller.loadMore();

      expect(
        backend.requestedTrackPages,
        <int>[1, 3, 2],
        reason: 'the page-one probe is reused instead of downloaded again',
      );
      expect(controller.tracks.first.hash, 'HASH-205');
      expect(controller.tracks.last.hash, 'HASH-001');
      expect(controller.tracks, hasLength(205));
      expect(controller.hasMore, isFalse);
    },
  );
}

typedef _BackendCall = ({String route, KugouJsonObject parameters});

final class _FavoriteBackend implements MusicBackend {
  _FavoriteBackend({
    this.loggedIn = true,
    this.useCollectionIdOnly = false,
    this.failGlobalTracks = false,
  });

  final bool loggedIn;
  final bool useCollectionIdOnly;
  final bool failGlobalTracks;
  final List<_BackendCall> calls = <_BackendCall>[];

  List<String> get routes => calls.map((call) => call.route).toList();

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
    calls.add((route: route, parameters: parameters));
    if (route == '/playlist/track/all' && failGlobalTracks) {
      throw const KugouTransportException('global collection unavailable');
    }
    return switch (route) {
      '/user/playlist' => KugouResponse<KugouJsonObject>(
        status: 1,
        httpStatus: 200,
        body: <String, Object?>{
          'data': <String, Object?>{
            'info': <Object?>[
              <String, Object?>{'name': '日常歌单', 'listid': 10, 'count': 1},
              <String, Object?>{
                'name': '我喜欢',
                'listid': useCollectionIdOnly ? '' : 77,
                'list_create_gid': 'collection-like',
                'count': useCollectionIdOnly || failGlobalTracks ? 2 : 3,
              },
            ],
          },
        },
      ),
      '/playlist/track/all/new' ||
      '/playlist/track/all' => _trackResponse(parameters['page'] as int? ?? 1),
      _ => throw StateError('Unexpected route: $route'),
    };
  }

  KugouResponse<KugouJsonObject> _trackResponse(int page) =>
      KugouResponse<KugouJsonObject>(
        status: 1,
        httpStatus: 200,
        body: <String, Object?>{
          'data': <String, Object?>{
            'total': useCollectionIdOnly || failGlobalTracks ? 2 : 3,
            'songs': page == 1
                ? <Object?>[_song('HASH-1', '第一首收藏'), _song('HASH-2', '第二首收藏')]
                : <Object?>[_song('hash-2', '重复歌曲'), _song('HASH-3', '第三首收藏')],
          },
        },
      );

  static KugouJsonObject _song(String hash, String title) => <String, Object?>{
    'hash': hash,
    'audio_name': title,
    'author_name': '测试歌手',
    'duration': 180,
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

final class _PrivatePagedFavoriteBackend implements MusicBackend {
  final List<int> requestedTrackPages = <int>[];

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
    if (route == '/user/playlist') {
      return const KugouResponse<KugouJsonObject>(
        status: 1,
        httpStatus: 200,
        body: <String, Object?>{
          'data': <String, Object?>{
            'info': <Object?>[
              <String, Object?>{
                'name': '我喜欢',
                'listid': 77,
                'list_create_gid': '',
                'count': 205,
              },
            ],
          },
        },
      );
    }
    if (route != '/playlist/track/all/new') {
      throw StateError('Unexpected route: $route');
    }

    final page = parameters['page'] as int;
    requestedTrackPages.add(page);
    final start = (page - 1) * 100 + 1;
    final end = page * 100 < 205 ? page * 100 : 205;
    return KugouResponse<KugouJsonObject>(
      status: 1,
      httpStatus: 200,
      body: <String, Object?>{
        'data': <String, Object?>{
          'total': 205,
          'songs': <Object?>[
            for (var number = start; number <= end; number += 1)
              <String, Object?>{
                'hash': 'HASH-${number.toString().padLeft(3, '0')}',
                'audio_name': '收藏歌曲 $number',
                'author_name': '测试歌手',
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
