import 'dart:math';

import '../crypto.dart';
import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createGradeEndpointHandlers() =>
    <String, KugouEndpointHandler>{'/user/grade/info': userGradeInfo};

Future<KugouResponse<Object?>> userGradeInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  const appId = '3116';
  const appKey = 'LnT6xpN3khm36zse0QzvmgTZ3waWdRSA';
  const clientVer = '10597';
  final token = jsString(
    input['token'] ?? endpointCookie(context, input, 'token') ?? '',
  );
  final userId = jsNumber(
    input['userid'] ?? endpointCookie(context, input, 'userid') ?? 0,
  ).toInt();
  final mid = jsString(
    input['mid'] ??
        endpointCookie(context, input, 'mid') ??
        endpointCookie(context, input, 'KUGOU_API_MID') ??
        '',
  );
  final uuid = jsString(
    input['uuid'] ??
        endpointCookie(context, input, 'uuid') ??
        endpointCookie(context, input, 'KUGOU_API_GUID') ??
        '-',
  );
  final dfid = jsString(
    input['dfid'] ?? endpointCookie(context, input, 'dfid') ?? '-',
  );
  final type = jsOr(input['type'], 1);
  final clientTime = context.nowSeconds;
  final key = md5Hex('$appId$appKey$clientVer$clientTime');
  final isReport = input['d_sec'] != null && input['diff_sec'] != null;
  final data = <String, Object?>{
    'mid': mid,
    'type': type,
    'uuid': uuid,
    'userid': userId,
  };
  if (isReport) {
    final durationSeconds = intParameter(input, 'd_sec');
    final differenceSeconds = intParameter(input, 'diff_sec');
    final yearType = intParameter(input, 'y_type');
    final monthType = intParameter(input, 'm_type');
    final verification = md5Hex(
      '$durationSeconds$differenceSeconds$yearType$monthType',
    );
    data
      ..['p'] = context.crypto.rsaRawEncrypt(<String, Object?>{
        'token': token,
        'md5': verification,
      }, publicKeyPem: liteKugouPublicKey).toUpperCase()
      ..['d_sec'] = durationSeconds
      ..['diff_sec'] = differenceSeconds
      ..['y_type'] = yearType
      ..['m_type'] = monthType;
  } else {
    data['p'] = context.crypto
        .rsaRawEncrypt(
          jsJsonEncode(<String, Object?>{
            'clienttime': clientTime,
            'userid': userId,
          }),
          publicKeyPem: liteKugouPublicKey,
        )
        .toUpperCase();
  }
  data
    ..['appid'] = appId
    ..['clientver'] = clientVer
    ..['clienttime'] = clientTime
    ..['key'] = key;

  return context.request(
    KugouRequest(
      baseUri: Uri.parse('http://userinfo.user.kugou.com'),
      path: '/v2/get_grade_info',
      method: 'POST',
      parameters: <String, Object?>{'dfid': dfid},
      data: data,
      headers: <String, Object?>{
        'Content-Type': 'text/plain; charset=ISO-8859-1',
        'User-Agent':
            'Android15-1070-$clientVer-201-0-get_user_grade_info-wifi',
        'KG-THash': _randomHex(7),
        'KG-Rec': '1',
        'KG-RC': '1',
      },
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );
}

String _randomHex(int length) {
  final random = Random.secure();
  final maximum = 1 << (length * 4);
  return random.nextInt(maximum).toRadixString(16).padLeft(length, '0');
}
