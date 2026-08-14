import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects a session created for another KuGou client variant', () {
    expect(
      () => KugouApi(
        config: const KugouApiConfig(variant: KugouClientVariant.lite),
        session: KugouSession(variant: KugouClientVariant.standard),
      ),
      throwsArgumentError,
    );
  });

  test('QR API returns the payload URL without rendering an image', () async {
    final transport = _TypedTransport();
    final api = KugouApi(transport: transport);
    addTearDown(api.close);

    final content = await api.loginQrContent('qr-key');

    expect(content.scheme, 'https');
    expect(content.host, 'h5.kugou.com');
    expect(content.queryParameters['qrcode'], 'qr-key');
    expect(transport.requests, isEmpty);
  });

  test(
    'typed song URL request adds both its key and Android signature',
    () async {
      final transport = _TypedTransport();
      final api = KugouApi(transport: transport);
      addTearDown(api.close);

      final response = await api.resolveSongUrl(
        const KugouSongUrlQuery(
          hash: 'ABCDEF',
          quality: KugouPlaybackQuality.piano,
        ),
      );

      expect(response.body['status'], 1);
      final request = transport.requests.single;
      expect(request.uri.path, '/v5/url');
      expect(request.parameters['hash'], 'abcdef');
      expect(request.parameters['quality'], 'magic_piano');
      expect(request.parameters['key']! as String, hasLength(32));
      expect(request.parameters['signature']! as String, hasLength(32));
    },
  );

  test('typed favorite requests use account playlist endpoints', () async {
    final transport = _TypedTransport();
    final api = KugouApi(transport: transport);
    addTearDown(api.close);

    await api.userPlaylists(
      const KugouUserPlaylistsQuery(page: 2, pageSize: 80),
    );
    await api.userPlaylistTracks(
      const KugouUserPlaylistTracksQuery(listId: '77', page: 3, pageSize: 60),
    );

    expect(transport.requests.map((request) => request.uri.path), <String>[
      '/v7/get_all_list',
      '/v4/get_list_all_file',
    ]);
    expect(
      const KugouUserPlaylistsQuery(page: 2, pageSize: 80).toParameters(),
      <String, Object?>{'page': 2, 'pagesize': 80},
    );
    expect(
      const KugouUserPlaylistTracksQuery(
        listId: '77',
        page: 3,
        pageSize: 60,
      ).toParameters(),
      <String, Object?>{'listid': '77', 'page': 3, 'pagesize': 60},
    );
  });

  test(
    'lyrics use the working desktop search contract and decode KRC',
    () async {
      final transport = _TypedTransport()
        ..body = <String, Object?>{
          'status': 200,
          'candidates': <Object?>[
            <String, Object?>{'id': 'lyric-id', 'accesskey': 'lyric-key'},
          ],
        };
      final api = KugouApi(transport: transport);
      addTearDown(api.close);

      final search = await api.searchLyrics(
        const KugouLyricSearchQuery(
          hash: 'TRACK-HASH',
          albumAudioId: 123,
          duration: Duration(milliseconds: 215000),
          keywords: '测试歌手 - 测试歌曲',
        ),
      );

      expect(search.body['candidates'], isA<List<Object?>>());
      expect(search.body['candidates']! as List<Object?>, hasLength(1));
      final searchRequest = transport.requests.single;
      expect(searchRequest.uri.host, 'lyrics.kugou.com');
      expect(searchRequest.uri.path, '/search');
      expect(searchRequest.parameters, <String, Object?>{
        'ver': 1,
        'man': 'yes',
        'client': 'pc',
        'keyword': '测试歌手 - 测试歌曲',
        'duration': 215000,
        'hash': 'TRACK-HASH',
      });

      transport.body = <String, Object?>{
        'status': 200,
        'contenttype': 0,
        'content':
            'a3JjMTjb6rkSg74J3tO7G/5iXFmUdFH/I4ADhoKTSvIhOxfbI52S3mMyo2te4A==',
      };
      final lyrics = await api.lyrics(
        const KugouLyricsQuery(id: 'lyric-id', accessKey: 'lyric-key'),
      );

      expect(lyrics.body['decodeContent'], '[id:kg]\n[00:01.00]你好，世界');
      expect(transport.requests.last.uri.path, '/download');
    },
  );

  test('typed JSON boundary rejects a non-object response', () async {
    final transport = _TypedTransport()..body = 'not-json';
    final api = KugouApi(transport: transport);
    addTearDown(api.close);

    await expectLater(
      api.callJson('/rank/list'),
      throwsA(isA<KugouUnexpectedBodyException>()),
    );
  });
}

final class _TypedTransport implements KugouHttpTransport {
  Object? body = <String, Object?>{'status': 1};
  final List<KugouHttpRequest> requests = <KugouHttpRequest>[];

  @override
  Future<KugouRawResponse> send(KugouHttpRequest request) async {
    requests.add(request);
    return KugouRawResponse(statusCode: 200, body: body);
  }

  @override
  void close() {}
}
