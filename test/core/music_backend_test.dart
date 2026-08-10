import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/kugou_api/src/endpoint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deferred gateway queues calls while its isolate starts', () async {
    final initial = KugouSession(
      variant: KugouClientVariant.lite,
      cookies: const <String, String>{'token': 'token', 'userid': '42'},
    );
    final backend = DeferredMusicBackend.start(
      initialSession: initial.toJson(),
      clientVariant: KugouClientVariant.lite,
    );
    addTearDown(backend.close);

    expect(backend.sessionState.isLoggedIn, isTrue);
    expect(backend.clientVariant, KugouClientVariant.lite);

    final qrContent = await backend.loginQrContent('queued-key');
    expect(qrContent.queryParameters['qrcode'], 'queued-key');
  });

  test(
    'background isolate owns API calls and synchronizes session state',
    () async {
      final initial = KugouSession(
        cookies: const <String, String>{'token': 'token', 'userid': '42'},
      );
      Map<String, Object?>? persisted;
      final backend = await IsolatedMusicBackend.start(
        initialSession: initial.toJson(),
        onSessionChanged: (session) async {
          persisted = session;
        },
      );
      addTearDown(backend.close);

      expect(backend.sessionState.isLoggedIn, isTrue);
      expect(backend.sessionState.userId, '42');
      expect(backend.clientVariant, KugouClientVariant.standard);

      final qrContent = await backend.loginQrContent('background-key');
      expect(qrContent.queryParameters['qrcode'], 'background-key');

      final concurrent = await Future.wait<Uri>(
        List<Future<Uri>>.generate(
          12,
          (index) => backend.loginQrContent('key-$index'),
        ),
      );
      expect(
        concurrent.map((uri) => uri.queryParameters['qrcode']),
        List<String>.generate(12, (index) => 'key-$index'),
      );

      await backend.setClientVariant(KugouClientVariant.lite);
      expect(backend.clientVariant, KugouClientVariant.lite);
      expect(backend.sessionState.isLoggedIn, isFalse);
      await backend.flushSession();
      final cookies = persisted?['cookies'];
      expect(cookies, isA<Map<Object?, Object?>>());
      expect((cookies! as Map<Object?, Object?>)['KUGOU_API_PLATFORM'], 'lite');
      expect(persisted?['active_variant'], 'lite');

      await backend.setClientVariant(KugouClientVariant.standard);
      expect(backend.clientVariant, KugouClientVariant.standard);
      expect(backend.sessionState.isLoggedIn, isTrue);
      expect(backend.sessionState.userId, '42');

      await backend.clearAuthentication();
      expect(backend.sessionState.isLoggedIn, isFalse);
      expect(backend.sessionState.userId, '0');
      expect(persisted, isNotNull);
    },
  );

  test('device registration is coalesced and persists its dfid', () async {
    var requests = 0;
    Map<String, Object?>? persisted;
    final api = KugouApi(
      additionalEndpoints: <String, KugouEndpointHandler>{
        '/register/dev': (context, parameters) async {
          requests += 1;
          await Future<void>.delayed(Duration.zero);
          context.session.setCookie('dfid', 'registered-device');
          return const KugouResponse<Object?>(
            status: 200,
            httpStatus: 200,
            body: <String, Object?>{
              'status': 1,
              'data': <String, Object?>{'dfid': 'registered-device'},
            },
            cookies: <String>['dfid=registered-device'],
          );
        },
      },
    );
    final backend = LocalMusicBackend(
      api,
      onSessionChanged: (session) async {
        persisted = session;
      },
    );
    addTearDown(backend.close);

    final results = await Future.wait<bool>(<Future<bool>>[
      backend.ensureDeviceRegistered(),
      backend.ensureDeviceRegistered(),
      backend.ensureDeviceRegistered(),
    ]);
    await backend.flushSession();

    expect(results, everyElement(isTrue));
    expect(requests, 1);
    expect(backend.sessionState.hasRegisteredDevice, isTrue);
    final cookies = persisted?['cookies'];
    expect(cookies, isA<Map<Object?, Object?>>());
    expect((cookies! as Map<Object?, Object?>)['dfid'], 'registered-device');
  });
}
