import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    'typed song URL request adds key and intentionally skips signature',
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
      expect(request.parameters, isNot(contains('signature')));
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
