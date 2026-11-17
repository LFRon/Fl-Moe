import 'package:fl_moe/kugou_api/src/config.dart';
import 'package:fl_moe/kugou_api/src/models.dart';
import 'package:fl_moe/kugou_api/src/request_executor.dart';
import 'package:fl_moe/kugou_api/src/session.dart';
import 'package:fl_moe/kugou_api/src/transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeTransport transport;
  late KugouSession session;

  setUp(() {
    transport = _FakeTransport();
    session = KugouSession(
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
  });

  test(
    'injects identity, signs request, and stores response cookies',
    () async {
      transport.response = const KugouRawResponse(
        statusCode: 200,
        body: <String, Object?>{'status': 1, 'data': 'ok'},
        headers: <String, List<String>>{
          'set-cookie': <String>['vip_type=2; Path=/', 'vip_token=x==; Path=/'],
        },
      );
      final executor = KugouRequestExecutor(
        config: const KugouApiConfig(),
        session: session,
        transport: transport,
        clock: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final response = await executor.execute(
        KugouRequest(
          path: '/v1/test',
          parameters: <String, Object?>{'keyword': '初音未来'},
        ),
      );

      expect(response.isSuccess, isTrue);
      final sent = transport.requests.single;
      expect(sent.uri.toString(), 'https://gateway.kugou.com/v1/test');
      expect(sent.parameters['appid'], 1005);
      expect(sent.parameters['clientver'], 20489);
      expect(sent.parameters['clienttime'], 1700000000);
      expect(sent.parameters['mid'], '123456789');
      expect(sent.parameters['userid'], '42');
      expect(sent.parameters['signature'], isA<String>());
      expect(sent.headers['kg-rf'], 'B9EDA08A64250DEFFBCADDEE00F8F25F');
      expect(sent.headers.containsKey('Cookie'), isFalse);
      expect(session['vip_type'], '2');
      expect(session['vip_token'], 'x==');
    },
  );

  test('normalizes API status zero to an exception', () async {
    transport.response = const KugouRawResponse(
      statusCode: 200,
      body: <String, Object?>{'status': 0, 'error_code': 123},
    );
    final executor = KugouRequestExecutor(
      config: const KugouApiConfig(),
      session: session,
      transport: transport,
    );

    await expectLater(
      executor.execute(KugouRequest(path: '/failure')),
      throwsA(
        isA<KugouApiException>().having(
          (error) => error.response.status,
          'normalized status',
          502,
        ),
      ),
    );
  });

  test('normalizes non-successful HTTP status to an exception', () async {
    transport.response = const KugouRawResponse(
      statusCode: 503,
      body: <String, Object?>{'message': 'unavailable'},
    );
    final executor = KugouRequestExecutor(
      config: const KugouApiConfig(),
      session: session,
      transport: transport,
    );

    await expectLater(
      executor.execute(KugouRequest(path: '/failure')),
      throwsA(
        isA<KugouApiException>()
            .having((error) => error.response.status, 'normalized status', 502)
            .having((error) => error.response.httpStatus, 'HTTP status', 503),
      ),
    );
  });
}

final class _FakeTransport implements KugouHttpTransport {
  KugouRawResponse response = const KugouRawResponse(
    statusCode: 200,
    body: <String, Object?>{'status': 1},
  );
  final List<KugouHttpRequest> requests = <KugouHttpRequest>[];

  @override
  Future<KugouRawResponse> send(KugouHttpRequest request) async {
    requests.add(request);
    return response;
  }

  @override
  void close() {}
}
