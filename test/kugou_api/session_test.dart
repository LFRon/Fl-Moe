import 'dart:math';

import 'package:fl_moe/kugou_api/src/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session creates stable device identity and is serializable', () {
    final session = KugouSession(random: Random(7));

    expect(session.guid, hasLength(32));
    expect(session.mid, matches(RegExp(r'^\d+$')));
    expect(session.deviceId, hasLength(10));
    expect(session.macAddress, '02:00:00:00:00:00');

    final restored = KugouSession.fromJson(session.toJson());
    expect(restored.cookies, session.cookies);
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
}
