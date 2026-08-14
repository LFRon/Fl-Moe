import 'dart:async';
import 'dart:convert';

import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/features/player/lyrics_controller.dart';
import 'package:fl_moe/features/player/lyrics_models.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses KRC timing and translated lines without dynamic models', () {
    final language = base64Encode(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'content': <Object?>[
            <String, Object?>{
              'type': 1,
              'lyricContent': <Object?>[
                <Object?>['Hello'],
                <Object?>['World'],
              ],
            },
          ],
        }),
      ),
    );
    final lines = parseKugouLyrics(
      '[language:$language]\n'
      '[0,1200]<0,600,0>你<600,600,0>好\n'
      '[1500,900]<0,900,0>世界',
    );

    expect(lines, hasLength(2));
    expect(lines[0].text, '你好');
    expect(lines[0].translation, 'Hello');
    expect(lines[0].start, Duration.zero);
    expect(lines[0].end, const Duration(milliseconds: 1200));
    expect(activeLyricLineIndex(lines, const Duration(milliseconds: 1700)), 1);
  });

  test('falls back to ordinary LRC timestamps', () {
    final lines = parseKugouLyrics('[00:01.20]第一句\n[00:03.450]第二句');

    expect(lines, hasLength(2));
    expect(lines.first.start, const Duration(milliseconds: 1200));
    expect(lines.first.end, const Duration(milliseconds: 3450));
    expect(lines.last.text, '第二句');
  });

  test(
    'loads search metadata before decoded lyrics and caches by hash',
    () async {
      final backend = _LyricsBackend();
      final controller = LyricsController(backend);
      const track = MusicTrack(
        id: '1',
        hash: 'TRACK_HASH',
        title: '测试歌曲',
        artist: '测试歌手',
        albumAudioId: 99,
        duration: Duration(seconds: 180),
      );

      await controller.loadFor(track);
      await controller.loadFor(track);

      expect(controller.state, LyricsLoadState.ready);
      expect(controller.lines.single.text, '测试歌词');
      expect(backend.routes, <String>['/search/lyric', '/lyric']);
      expect(backend.searchParameters['hash'], 'TRACK_HASH');
      expect(backend.searchParameters['album_audio_id'], 99);
      expect(backend.searchParameters['duration'], 180000);
      expect(backend.searchParameters['keywords'], '测试歌手 - 测试歌曲');
      expect(backend.lyricParameters['id'], 'lyric-id');
      expect(backend.lyricParameters['accesskey'], 'lyric-key');
    },
  );

  test(
    'ignores a stale lyric search after the playing track changes',
    () async {
      final backend = _StaleLyricsBackend();
      final controller = LyricsController(backend);
      const first = MusicTrack(
        id: '1',
        hash: 'FIRST',
        title: '第一首',
        artist: '歌手',
      );
      const second = MusicTrack(
        id: '2',
        hash: 'SECOND',
        title: '第二首',
        artist: '歌手',
      );

      final staleLoad = controller.loadFor(first);
      await Future<void>.delayed(Duration.zero);
      await controller.loadFor(second);
      backend.completeFirstSearch();
      await staleLoad;

      expect(controller.trackHash, 'SECOND');
      expect(controller.state, LyricsLoadState.ready);
      expect(controller.lines.single.text, '第二首歌词');
    },
  );
}

final class _LyricsBackend implements MusicBackend {
  final List<String> routes = <String>[];
  KugouJsonObject searchParameters = const <String, Object?>{};
  KugouJsonObject lyricParameters = const <String, Object?>{};

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
    if (route == '/search/lyric') {
      searchParameters = parameters;
      return const KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'status': 200,
          'candidates': <Object?>[
            <String, Object?>{'id': 'lyric-id', 'accesskey': 'lyric-key'},
          ],
        },
      );
    }
    if (route == '/lyric') {
      lyricParameters = parameters;
      return const KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'status': 200,
          'decodeContent': '[0,1200]<0,1200,0>测试歌词',
        },
      );
    }
    throw UnsupportedError('Unexpected route: $route');
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

final class _StaleLyricsBackend implements MusicBackend {
  final Completer<KugouResponse<KugouJsonObject>> _firstSearch =
      Completer<KugouResponse<KugouJsonObject>>();

  void completeFirstSearch() {
    _firstSearch.complete(_searchResponse('first-id'));
  }

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
    if (route == '/search/lyric') {
      return parameters['hash'] == 'FIRST'
          ? _firstSearch.future
          : _searchResponse('second-id');
    }
    if (route == '/lyric') {
      final id = parameters['id'];
      return KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'decodeContent': id == 'second-id'
              ? '[0,1000]<0,1000,0>第二首歌词'
              : '[0,1000]<0,1000,0>第一首歌词',
        },
      );
    }
    throw UnsupportedError('Unexpected route: $route');
  }

  KugouResponse<KugouJsonObject> _searchResponse(String id) =>
      KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'candidates': <Object?>[
            <String, Object?>{'id': id, 'accesskey': '$id-key'},
          ],
        },
      );

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
