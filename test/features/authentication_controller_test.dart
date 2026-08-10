import 'dart:convert';

import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/features/auth/authentication_controller.dart';
import 'package:fl_moe/features/auth/kugou_user_profile.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository drops a legacy token whose client variant is unknown', () {
    final store = MemoryKeyValueStore(<String, Object?>{
      'state': jsonEncode(<String, Object?>{
        'cookies': <String, String>{
          'token': 'legacy-token',
          'userid': '42',
          'dfid': 'registered-device',
        },
      }),
    });

    final session = KugouSessionRepository(
      store,
    ).load(variant: KugouClientVariant.lite);

    expect(session.isLoggedIn, isFalse);
    expect(session.hasRegisteredDevice, isTrue);
    expect(session.dfid, 'registered-device');
  });

  test(
    'QR login waits for device registration before requesting a key',
    () async {
      final backend = _AuthenticationBackend();
      final controller = AuthenticationController(backend);

      final challenge = await controller.createQrChallenge();

      expect(challenge.key, 'qr-key');
      expect(challenge.content.queryParameters['qrcode'], 'qr-key');
      expect(backend.events, <String>[
        'register',
        '/login/qr/key',
        '/login/qr/create',
      ]);
    },
  );

  test('QR login stops when device registration fails', () async {
    final backend = _AuthenticationBackend(registrationSucceeds: false);
    final controller = AuthenticationController(backend);

    await expectLater(
      controller.createQrChallenge(),
      throwsA(isA<StateError>()),
    );
    expect(backend.events, <String>['register']);
  });

  test('profile parser accepts nested KuGou avatar data', () {
    final profile = KugouUserProfile.fromApiData(const <String, Object?>{
      'info': <String, Object?>{
        'userid': 42,
        'nickname': '萌友',
        'pic': '//imge.example.test/{size}/avatar.jpg',
      },
    }, fallbackUserId: '0');

    expect(profile?.userId, '42');
    expect(profile?.nickname, '萌友');
    expect(profile?.avatarUrl, 'https://imge.example.test/240/avatar.jpg');
  });

  test(
    'profile refresh uses the backend and restores cached public data',
    () async {
      final store = MemoryKeyValueStore();
      final repository = KugouUserProfileRepository(store);
      final backend = _ProfileBackend();
      final controller = AuthenticationController(
        backend,
        profileRepository: repository,
      );

      expect(controller.avatarUrl, isEmpty);
      expect(await controller.refreshUserProfile(), isTrue);
      expect(backend.routes, <String>['/user/detail']);
      expect(controller.nickname, '酷狗用户');
      expect(controller.avatarUrl, 'https://img.example.test/avatar.jpg');

      final restored = AuthenticationController(
        _ProfileBackend(),
        profileRepository: repository,
      );
      expect(restored.nickname, '酷狗用户');
      expect(restored.avatarUrl, 'https://img.example.test/avatar.jpg');
      expect(
        repository.load(variant: KugouClientVariant.standard, userId: '42'),
        isNull,
      );
    },
  );
}

final class _AuthenticationBackend implements MusicBackend {
  _AuthenticationBackend({this.registrationSucceeds = true});

  final bool registrationSucceeds;
  final List<String> events = <String>[];
  bool _registered = false;

  @override
  KugouClientVariant get clientVariant => KugouClientVariant.lite;

  @override
  BackendSessionState get sessionState => BackendSessionState(
    isLoggedIn: false,
    userId: '0',
    hasRegisteredDevice: _registered,
  );

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) async {
    events.add(route);
    return switch (route) {
      '/login/qr/key' => const KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'status': 1,
          'data': <String, Object?>{'qrcode': 'qr-key'},
        },
      ),
      '/login/qr/create' => const KugouResponse<KugouJsonObject>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'code': 200,
          'data': <String, Object?>{
            'content':
                'https://h5.kugou.com/apps/loginQRCode/html/index.html?qrcode=qr-key',
          },
        },
      ),
      _ => throw ArgumentError.value(route, 'route'),
    };
  }

  @override
  Future<void> clearAuthentication() async {}

  @override
  Future<void> close() async {}

  @override
  Future<bool> ensureDeviceRegistered() async {
    events.add('register');
    _registered = registrationSucceeds;
    return registrationSucceeds;
  }

  @override
  Future<void> flushSession() async {}

  @override
  Future<void> setClientVariant(KugouClientVariant variant) async {}
}

final class _ProfileBackend implements MusicBackend {
  final List<String> routes = <String>[];

  @override
  KugouClientVariant get clientVariant => KugouClientVariant.lite;

  @override
  BackendSessionState get sessionState => const BackendSessionState(
    isLoggedIn: true,
    userId: '42',
    hasRegisteredDevice: true,
  );

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) async {
    routes.add(route);
    if (route != '/user/detail') {
      throw ArgumentError.value(route, 'route');
    }
    return const KugouResponse<KugouJsonObject>(
      status: 200,
      httpStatus: 200,
      body: <String, Object?>{
        'status': 1,
        'data': <String, Object?>{
          'userid': 42,
          'nickname': '酷狗用户',
          'pic': 'https://img.example.test/avatar.jpg',
        },
      },
    );
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
