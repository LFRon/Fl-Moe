import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privilege lite exposes normalized quality_vip data', () async {
    final transport = _RecordingTransport(
      body: <String, Object?>{
        'status': 1,
        'data': <Object?>[
          <String, Object?>{
            'hash': 'ABCDEF',
            'relate_goods': <Object?>[
              <String, Object?>{
                'hash': 'VIP128',
                'quality': '128',
                'level': 1,
                'privilege': 10,
                'status': 1,
                'info': <String, Object?>{'filesize': 2048, 'extname': 'mp3'},
              },
            ],
          },
        ],
      },
    );
    final api = KugouApi(
      config: const KugouApiConfig(variant: KugouClientVariant.lite),
      session: KugouSession(variant: KugouClientVariant.lite),
      transport: transport,
    );
    addTearDown(api.close);

    final response = await api.call(
      '/privilege/lite',
      parameters: const <String, Object?>{'hash': 'abcdef'},
    );
    final body = response.body! as Map<String, Object?>;
    final qualityVip = body['quality_vip']! as List<Object?>;
    final first = qualityVip.single! as Map<String, Object?>;
    expect(first['hash'], 'abcdef');
    expect(first['free_listen'], isTrue);
    expect(
      (first['qualities']! as List<Object?>).first,
      containsPair('obtainable', true),
    );
  });

  test('blacklist posts relation data with KG-TID', () async {
    final transport = _RecordingTransport(
      body: const <String, Object?>{'status': 1},
    );
    final api = KugouApi(transport: transport);
    addTearDown(api.close);

    await api.call(
      '/blacklist',
      parameters: const <String, Object?>{
        'hash': 'ABCDEF',
        'name': 'Singer - Song',
        'mixsongid': 9,
      },
    );

    final request = transport.requests.single;
    expect(
      request.uri.toString(),
      'https://relationuser.kugou.com/v1/edit_list_items',
    );
    expect(request.method, 'POST');
    expect(request.headers['KG-TID'], '473');
    final data = request.body! as Map<String, Object?>;
    expect(data['label'], 'song');
    expect(data['action'], 'add');
    expect(data['p'], isA<String>());
  });

  test('playlist update uses the cloudlist gateway contract', () async {
    final transport = _RecordingTransport(
      body: Uint8List.fromList(utf8.encode('{"status":1,"data":{}}')),
    );
    final api = KugouApi(transport: transport);
    addTearDown(api.close);

    await api.call(
      '/playlist/update',
      parameters: const <String, Object?>{
        'listid': 77,
        'name': 'New name',
        'total_ver': 3,
      },
    );

    final request = transport.requests.single;
    expect(request.uri.toString(), 'https://gateway.kugou.com/v1/modify_list');
    expect(request.headers['x-router'], 'cloudlist.service.kugou.com');
    expect(request.parameters['p'], isA<String>());
    expect(request.body, isA<Uint8List>());
  });

  test('team request carries a web signature and gateway host', () async {
    final transport = _RecordingTransport(
      body: const <String, Object?>{'status': 1},
    );
    final api = KugouApi(transport: transport);
    addTearDown(api.close);

    await api.call('/team/period/info');

    final request = transport.requests.single;
    expect(
      request.uri.toString(),
      'https://gateway.kugou.com/youth/v1/ut/get_period_info',
    );
    expect(request.headers['Host'], 'gateway.kugou.com');
    expect(request.parameters['signature'], isA<String>());
    expect(request.parameters['signature']! as String, hasLength(32));
  });

  test('listen together operations select the upstream endpoint', () async {
    final transport = _RecordingTransport(
      body: const <String, Object?>{'status': 1},
    );
    final api = KugouApi(transport: transport);
    addTearDown(api.close);

    await api.call(
      '/listen/together/music',
      parameters: const <String, Object?>{
        'operation': 'detail',
        'roomid': '123',
      },
    );

    final request = transport.requests.single;
    expect(
      request.uri.toString(),
      'https://gateway.kugou.com/youth/v1/genting/get_musicroom_info',
    );
    expect(request.parameters['roomid'], '123');
    expect(request.parameters['biz'], '1009');
  });

  test('QQ login posts the open platform body', () async {
    final transport = _RecordingTransport(
      body: const <String, Object?>{
        'status': 1,
        'data': <String, Object?>{'token': 'token', 'userid': 42},
      },
    );
    final api = KugouApi(transport: transport);
    addTearDown(api.close);

    await api.call(
      '/login/qq',
      parameters: const <String, Object?>{
        'openid': 'openid',
        'access_token': 'access',
      },
    );

    final request = transport.requests.single;
    expect(
      request.uri.toString(),
      'https://gateway.kugou.com/v6/login_by_openplat',
    );
    expect(request.headers['x-router'], 'login.user.kugou.com');
    final body = request.body! as Map<String, Object?>;
    expect(body['partnerid'], 1);
    expect(body['third_appid'], '205141');
    expect(body['openid'], 'openid');
  });

  test('album dynamic cover uses the CDN query and identity headers', () async {
    final transport = _RecordingTransport(
      body: const <String, Object?>{'status': 1},
    );
    final api = KugouApi(transport: transport);
    addTearDown(api.close);

    await api.call(
      '/album/dycover',
      parameters: const <String, Object?>{
        'album_audio_id': '123,456',
        'album_id': '7,8',
      },
    );

    final request = transport.requests.single;
    expect(request.uri.host, 'kmrcdn.service.kugou.com');
    expect(request.uri.path, '/v2/album/audio');
    expect(request.uri.query, contains('data='));
    expect(request.parameters['signature'], isA<String>());
    expect(request.headers['dfid'], '-');
    expect(request.headers['mid'], 'undefined');
    expect(request.headers.containsKey('User-Agent'), isFalse);
  });
}

final class _RecordingTransport implements KugouHttpTransport {
  _RecordingTransport({required this.body});

  final Object? body;
  final List<KugouHttpRequest> requests = <KugouHttpRequest>[];

  @override
  Future<KugouRawResponse> send(KugouHttpRequest request) async {
    requests.add(request);
    return KugouRawResponse(statusCode: 200, body: body);
  }

  @override
  void close() {}
}
