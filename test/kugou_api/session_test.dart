import 'dart:math';

import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session creates stable device identity and is serializable', () {
    final session = KugouSession(random: Random(7));

    expect(session.guid, hasLength(32));
    expect(session.mid, matches(RegExp(r'^\d+$')));
    expect(session.deviceId, hasLength(10));
    expect(session.macAddress, '02:00:00:00:00:00');
    expect(session.hasRegisteredDevice, isFalse);

    final restored = KugouSession.fromJson(session.toJson());
    expect(restored.cookies, session.cookies);
  });

  test('recognizes only a usable persisted dfid as device registration', () {
    final registered = KugouSession(
      cookies: const <String, String>{'dfid': 'registered-device'},
    );
    final placeholder = KugouSession(
      cookies: const <String, String>{'dfid': '-'},
    );

    expect(registered.dfid, 'registered-device');
    expect(registered.hasRegisteredDevice, isTrue);
    expect(placeholder.hasRegisteredDevice, isFalse);
  });

  test('Set-Cookie values are normalized and update authentication', () {
    final session = KugouSession(random: Random(1));
    session.updateCookies(const <String>[
      'token=abc==; Domain=.kugou.com; Path=/; HttpOnly',
      'userid=42; Path=/',
    ]);

    expect(session.token, 'abc==');
    expect(session.userId, '42');
    expect(session.isLoggedIn, isTrue);
    session.clearAuthentication();
    expect(session.isLoggedIn, isFalse);
  });

  test('keeps authentication isolated by client variant', () {
    final standard = KugouSession(
      variant: KugouClientVariant.standard,
      cookies: const <String, String>{
        'token': 'standard-token',
        'userid': '42',
        'vip_type': '1',
      },
    );

    final lite = KugouSession.fromJson(
      standard.toJson(),
      variant: KugouClientVariant.lite,
    );
    expect(lite.isLoggedIn, isFalse);
    expect(lite.token, isEmpty);
    expect(lite.userId, '0');

    lite.updateCookies(const <String>[
      'token=lite-token; Path=/',
      'userid=84; Path=/',
    ]);
    final saved = lite.toJson();

    final restoredStandard = KugouSession.fromJson(
      saved,
      variant: KugouClientVariant.standard,
    );
    expect(restoredStandard.isLoggedIn, isTrue);
    expect(restoredStandard.token, 'standard-token');
    expect(restoredStandard.userId, '42');

    final restoredLite = KugouSession.fromJson(
      saved,
      variant: KugouClientVariant.lite,
    );
    expect(restoredLite.isLoggedIn, isTrue);
    expect(restoredLite.token, 'lite-token');
    expect(restoredLite.userId, '84');
  });

  test('unscoped legacy authentication can be discarded safely', () {
    final restored = KugouSession.fromJson(
      const <String, Object?>{
        'cookies': <String, String>{
          'token': 'unknown-platform-token',
          'userid': '42',
          'dfid': 'registered-device',
        },
      },
      variant: KugouClientVariant.lite,
      trustLegacyAuthentication: false,
    );

    expect(restored.isLoggedIn, isFalse);
    expect(restored.token, isEmpty);
    expect(restored.userId, '0');
    expect(restored.dfid, 'registered-device');
    expect(restored.hasRegisteredDevice, isTrue);
  });

  test('sign out clears authentication saved for every variant', () {
    final standard = KugouSession(
      cookies: const <String, String>{
        'token': 'standard-token',
        'userid': '42',
      },
    );
    final lite = KugouSession.fromJson(
      standard.toJson(),
      variant: KugouClientVariant.lite,
    )..updateCookies(const <String>['token=lite-token', 'userid=84']);

    lite.clearAuthentication();
    final saved = lite.toJson();

    expect(lite.isLoggedIn, isFalse);
    expect(
      KugouSession.fromJson(
        saved,
        variant: KugouClientVariant.standard,
      ).isLoggedIn,
      isFalse,
    );
  });
}
