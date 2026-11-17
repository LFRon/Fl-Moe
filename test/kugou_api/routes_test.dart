import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes every route from the current reference API', () {
    final api = KugouApi(transport: _NoopTransport());
    addTearDown(api.close);

    final routes = api.routes.toSet();
    expect(api.routes, hasLength(234));
    expect(routes, hasLength(234));
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
        '/ai/recommend/song',
        '/blacklist',
        '/blacklist/list',
        '/comment/music/send',
        '/comment/floor/send',
        '/listen/together/music',
        '/login/qq',
        '/login/qq/qr/create',
        '/login/qr/authorize',
        '/playlist/pic/upload',
        '/playlist/update',
        '/song/barrage/send',
        '/song/url/auth/merge',
        '/team/my',
        '/user/listen/report',
        '/user/preference/update',
        '/user/update/avatar',
        '/user/visitors',
        '/video/barrage/send',
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
