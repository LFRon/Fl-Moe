import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes every route from the 169-module reference API', () {
    final api = KugouApi(transport: _NoopTransport());
    addTearDown(api.close);

    final routes = api.routes.toSet();
    expect(api.routes, hasLength(169));
    expect(routes, hasLength(169));
    expect(
      routes,
      containsAll(const <String>{
        '/search',
        '/song/url',
        '/lyric',
        '/login/qr/create',
        '/register/dev',
        '/sidedt',
        '/verify/user/info',
        '/user/cloud',
        '/user/cloud/del',
        '/user/cloud/match',
        '/user/cloud/upload',
        '/user/grade/info',
      }),
    );
  });
}

final class _NoopTransport implements KugouHttpTransport {
  @override
  Future<KugouRawResponse> send(KugouHttpRequest request) async =>
      const KugouRawResponse(
        statusCode: 200,
        body: <String, Object?>{'status': 1},
      );

  @override
  void close() {}
}
