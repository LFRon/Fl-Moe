import 'dart:convert';
import 'dart:math';

import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/kugou_api/src/request_executor.dart';
import 'package:fl_moe/kugou_api/src/ssa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generates AES behavior data and a 2048-bit RSA-OAEP key envelope', () {
    final generator = KugouSsaGenerator(
      crypto: KugouCrypto(const KugouApiConfig()),
      random: Random(42),
      clock: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    final result = generator.generate(
      mid: '123',
      userId: '42',
      dfid: 'dfid',
      webGlHash: '99',
    );

    expect(base64Decode(result.sid), hasLength(256));
    final encryptedBehavior = base64Decode(result.edt);
    expect(encryptedBehavior, isNotEmpty);
    expect(encryptedBehavior.length % 16, 0);
  });

  test('adds SSA fields to a response carrying the ssa-code header', () async {
    final transport = _SsaTransport();
    final session = KugouSession(
      cookies: const <String, String>{
        'KUGOU_API_MID': '123',
        'KUGOU_API_GUID': '0123456789abcdef0123456789abcdef',
        'KUGOU_API_DEV': 'ABCDEFGHIJ',
        'KUGOU_API_MAC': '02:00:00:00:00:00',
        'KUGOU_API_WEBGL': '99',
        'dfid': 'dfid',
        'userid': '42',
        'token': 'token',
      },
    );
    final executor = KugouRequestExecutor(
      config: const KugouApiConfig(),
      session: session,
      transport: transport,
      clock: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    final response = await executor.execute(KugouRequest(path: '/ssa'));
    final body = response.body as Map<String, Object?>;

    expect(body['ssaCode'], 'challenge');
    expect(base64Decode(body['sid']! as String), hasLength(256));
    expect(base64Decode(body['edt']! as String), isNotEmpty);
    expect(response.headers['ssa-code'], 'challenge');
    expect(transport.request.headers.containsKey('Cookie'), isFalse);
  });
}

final class _SsaTransport implements KugouHttpTransport {
  late KugouHttpRequest request;

  @override
  Future<KugouRawResponse> send(KugouHttpRequest request) async {
    this.request = request;
    return KugouRawResponse(
      statusCode: 200,
      body: <String, Object?>{'status': 1},
      headers: const <String, List<String>>{
        'SSA-CODE': <String>['challenge'],
      },
    );
  }

  @override
  void close() {}
}
