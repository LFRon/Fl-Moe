import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'cloud upload executes auth, multipart, completion, and add-files',
    () async {
      final transport = _QueueTransport(<KugouRawResponse>[
        const KugouRawResponse(
          statusCode: 200,
          body: <String, Object?>{
            'status': 1,
            'data': <String, Object?>{'authorization': 'upload-auth'},
          },
        ),
        const KugouRawResponse(
          statusCode: 200,
          body: <String, Object?>{
            'status': 1,
            'data': <String, Object?>{
              'external_host': 'upload.example.test',
              'upload_id': 'upload-1',
              'x-bss-filename': 'initial-hash',
            },
          },
        ),
        const KugouRawResponse(
          statusCode: 200,
          body: <String, Object?>{'status': 1},
        ),
        const KugouRawResponse(
          statusCode: 200,
          body: <String, Object?>{
            'status': 1,
            'data': <String, Object?>{'x-bss-filename': 'completed-hash'},
          },
        ),
        KugouRawResponse(
          statusCode: 200,
          body: Uint8List.fromList(utf8.encode('{"status":1,"data":{}}')),
        ),
      ]);
      final api = KugouApi(
        session: _authenticatedSession(),
        transport: transport,
      );
      addTearDown(api.close);

      final response = await api.call(
        '/user/cloud/upload',
        parameters: <String, Object?>{
          'data': Uint8List.fromList(<int>[1, 2, 3, 4]),
          'auto_match': false,
          'hash_std': 'standard-hash',
          'audio_id': 9,
          'album_audio_id': 10,
          'name': 'A song.mp3',
        },
      );

      expect(transport.requests, hasLength(5));
      expect(transport.requests[0].uri.path, '/bsstrackercdngz/v1/upload/auth');
      expect(transport.requests[1].uri.path, '/v2/multipart/initiate/music');
      expect(transport.requests[2].uri.path, '/v3/multipart/upload');
      expect(transport.requests[2].body, Uint8List.fromList(<int>[1, 2, 3, 4]));
      expect(
        transport.requests[2].headers['Content-Type'],
        'application/octet-stream',
      );
      expect(transport.requests[3].uri.path, '/v3/multipart/complete');
      expect(transport.requests[4].uri.path, '/v1/add_files');
      expect(transport.requests[4].body, isA<Uint8List>());
      expect(
        (transport.requests[0].parameters['signature']! as String),
        hasLength(32),
      );
      final body = response.body as Map<String, Object?>;
      final uploadInfo = body['uploadInfo']! as Map<String, Object?>;
      expect(uploadInfo['hash'], 'completed-hash');
      expect(uploadInfo['filesize'], 4);
    },
  );

  test('standard grade request uses the encrypted v4 protocol', () async {
    final transport = _QueueTransport(<KugouRawResponse>[
      const KugouRawResponse(
        statusCode: 200,
        body: <String, Object?>{'status': 1},
      ),
    ]);
    final api = KugouApi(
      session: _authenticatedSession(),
      transport: transport,
    );
    addTearDown(api.close);

    await api.call('/user/grade/info');

    final request = transport.requests.single;
    expect(
      request.uri.toString(),
      'https://userinfoservice.kugou.com/v4/get_grade_info',
    );
    expect(request.method, 'POST');
    expect(request.parameters['signature'], isA<String>());
    expect(request.parameters['signature']! as String, hasLength(32));
    final body = jsonDecode(request.body! as String) as Map<String, Object?>;
    expect(body['userid'], '42');
    expect(body['pk']! as String, hasLength(256));
    expect(body['params'], isA<String>());
    expect((body['params']! as String).length % 32, 0);
  });

  test('lite grade request uses the v2 body and raw RSA envelope', () async {
    final transport = _QueueTransport(<KugouRawResponse>[
      const KugouRawResponse(
        statusCode: 200,
        body: <String, Object?>{'status': 1},
      ),
    ]);
    final api = KugouApi(
      config: const KugouApiConfig(variant: KugouClientVariant.lite),
      session: _authenticatedSession(variant: KugouClientVariant.lite),
      transport: transport,
    );
    addTearDown(api.close);

    await api.call(
      '/user/grade/info',
      parameters: const <String, Object?>{'d_sec': 100, 'diff_sec': 10},
    );

    final request = transport.requests.single;
    expect(
      request.uri.toString(),
      'http://userinfo.user.kugou.com/v2/get_grade_info',
    );
    final body = request.body! as Map<String, Object?>;
    expect(body['appid'], '3116');
    expect(body['clientver'], '11440');
    expect(body['p']! as String, hasLength(256));
    expect(body['key']! as String, hasLength(32));
    expect(body['d_sec'], 100);
    expect(body['diff_sec'], 10);
  });
}

KugouSession _authenticatedSession({
  KugouClientVariant variant = KugouClientVariant.standard,
}) => KugouSession(
  variant: variant,
  cookies: const <String, String>{
    'KUGOU_API_GUID': '0123456789abcdef0123456789abcdef',
    'KUGOU_API_MID': '123456789',
    'KUGOU_API_DEV': 'ABCDEFGHIJ',
    'KUGOU_API_MAC': '02:00:00:00:00:00',
    'KUGOU_API_WEBGL': '99',
    'dfid': 'dfid-value',
    'token': 'token-value',
    'userid': '42',
  },
);

final class _QueueTransport implements KugouHttpTransport {
  _QueueTransport(List<KugouRawResponse> responses)
    : _responses = List<KugouRawResponse>.from(responses);

  final List<KugouRawResponse> _responses;
  final List<KugouHttpRequest> requests = <KugouHttpRequest>[];

  @override
  Future<KugouRawResponse> send(KugouHttpRequest request) async {
    requests.add(request);
    if (_responses.isEmpty) throw StateError('No queued response');
    return _responses.removeAt(0);
  }

  @override
  void close() {}
}
