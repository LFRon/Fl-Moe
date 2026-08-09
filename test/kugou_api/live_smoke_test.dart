import 'dart:io';

import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['KUGOU_LIVE_TEST'] == '1';
  final authentication = _parseCookies(
    Platform.environment['KUGOU_LIVE_COOKIE'],
  );

  test(
    'public discovery endpoints respond through the real KuGou gateway',
    () async {
      final api = KugouApi();
      addTearDown(api.close);

      final hot = await api.call('/search/hot');
      expect(hot.httpStatus, 200);
      expect(hot.body, isA<Map<String, Object?>>());

      final ranks = await api.call('/rank/list');
      expect(ranks.httpStatus, 200);
      expect(ranks.body, isA<Map<String, Object?>>());
    },
    skip: live ? false : 'Set KUGOU_LIVE_TEST=1 to use the real network.',
  );

  test(
    'authenticated search responds through the real KuGou gateway',
    () async {
      final api = KugouApi(session: KugouSession(cookies: authentication));
      addTearDown(api.close);

      final search = await api.call(
        '/search',
        parameters: const <String, Object?>{'keywords': '初音未来', 'pagesize': 30},
      );
      expect(search.httpStatus, 200);
      expect(search.body, isA<Map<String, Object?>>());
    },
    skip: live && authentication.isNotEmpty
        ? false
        : 'Set KUGOU_LIVE_TEST=1 and KUGOU_LIVE_COOKIE for search.',
  );
}

Map<String, String> _parseCookies(String? value) {
  if (value == null || value.trim().isEmpty) return <String, String>{};
  final result = <String, String>{};
  for (final part in value.split(';')) {
    final separator = part.indexOf('=');
    if (separator <= 0) continue;
    result[part.substring(0, separator).trim()] = part
        .substring(separator + 1)
        .trim();
  }
  return result;
}
