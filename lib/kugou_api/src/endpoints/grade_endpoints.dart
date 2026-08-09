import 'dart:math';

import '../config.dart';
import '../crypto.dart';
import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createGradeEndpointHandlers() =>
    <String, KugouEndpointHandler>{'/user/grade/info': _userGradeInfo};

Future<KugouResponse<Object?>> _userGradeInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final defaultProtocol = context.config.isLite ? 'v2' : 'v4';
  final protocol = stringParameter(input, 'protocol', defaultProtocol);
  return protocol == 'v4' ? _gradeV4(context, input) : _gradeV2(context, input);
}

Future<KugouResponse<Object?>> _gradeV4(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  const appKey = 'OIlwieks28dk2k092lksi2UIkp';
  final appId = stringParameter(
    input,
    'appid',
    KugouApiConfig.standardAppId.toString(),
  );
  final effectiveAppKey = stringParameter(input, 'appkey', appKey);
  final clientVersion = stringParameter(
    input,
    'clientver',
    KugouApiConfig.standardClientVersion.toString(),
  );
  final userId = jsString(
    input['userid'] ?? endpointCookie(context, input, 'userid') ?? 0,
  );
  final token = jsString(
    input['token'] ?? endpointCookie(context, input, 'token') ?? '',
  );
  final mid = jsString(
    input['mid'] ??
        endpointCookie(context, input, 'mid') ??
        endpointCookie(context, input, 'KUGOU_API_MID') ??
        '',
  );
  final dfid = jsString(
    input['dfid'] ?? endpointCookie(context, input, 'dfid') ?? '-',
  );
  final uuid = stringParameter(input, 'uuid', '-');
  final milliseconds = context.nowMilliseconds;
  final clientTime = milliseconds ~/ 1000;
  final yearType = intParameter(input, 'y_type');
  final monthType = intParameter(input, 'm_type');
  final durationSeconds = intParameter(input, 'd_sec');
  final differenceSeconds = intParameter(input, 'diff_sec');
  final verification = md5Hex(
    '$durationSeconds$differenceSeconds$yearType$monthType',
  );

  final aesSeed = _randomHexBytes(8);
  final seedMd5 = md5Hex(aesSeed);
  final encryptedParameters = context.crypto
      .aesEncrypt(
        <String, Object?>{
          'userid': userId,
          'token': token,
          'md5': verification,
        },
        key: seedMd5.substring(0, 32),
        iv: seedMd5.substring(16, 32),
      )
      .ciphertext;
  final encryptedKey = context.crypto.rsaRawEncrypt(<String, Object?>{
    'clienttime_ms': milliseconds,
    'key': aesSeed,
  }, publicKeyPem: standardKugouPublicKey);
  final body = <String, Object?>{
    'plat': 1,
    'userid': userId,
    'clienttime_ms': milliseconds,
    'type': 0,
    'd_sec': durationSeconds,
    'diff_sec': differenceSeconds,
    'y_type': yearType,
    'm_type': monthType,
    'pk': encryptedKey,
    'params': encryptedParameters,
    'medal': 0,
  };
  final bodyString = jsJsonEncode(body);
  final query = <String, Object?>{
    'clienttime': clientTime,
    'mid': mid,
    'dfid': dfid,
    'uuid': uuid,
    'appid': appId,
    'clientver': clientVersion,
  };
  final sortedKeys = query.keys.toList()..sort();
  final signatureSource = sortedKeys
      .map((key) => '$key=${jsValueString(query[key])}')
      .join();
  query['signature'] = md5Hex(
    '$effectiveAppKey$signatureSource$bodyString$effectiveAppKey',
  );

  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://userinfoservice.kugou.com'),
      path: '/v4/get_grade_info',
      method: 'POST',
      parameters: query,
      data: bodyString,
      headers: <String, Object?>{
        'Content-Type': 'application/json; charset=UTF-8',
        'User-Agent':
            'Android15-1070-$clientVersion-201-0-'
            'get_user_grade_info-wifi',
        'KG-DEVID': mid,
        'KG-CLIENTTIMEMS': milliseconds.toString(),
      },
      cookies: stringStringMap(input['cookie']),
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );
}

Future<KugouResponse<Object?>> _gradeV2(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  const standardAppKey = 'OIlwieks28dk2k092lksi2UIkp';
  const liteAppKey = 'LnT6xpN3khm36zse0QzvmgTZ3waWdRSA';
  final defaultAppId = context.config.isLite
      ? KugouApiConfig.liteAppId
      : KugouApiConfig.standardAppId;
  final defaultClientVersion = context.config.isLite
      ? KugouApiConfig.liteClientVersion
      : KugouApiConfig.standardClientVersion;
  final appId = stringParameter(input, 'appid', defaultAppId.toString());
  final appKey = stringParameter(
    input,
    'appkey',
    context.config.isLite ? liteAppKey : standardAppKey,
  );
  final clientVersion = stringParameter(
    input,
    'clientver',
    defaultClientVersion.toString(),
  );
  final publicKey = stringParameter(
    input,
    'publicKey',
    context.config.isLite ? liteKugouPublicKey : standardKugouPublicKey,
  );
  final userId =
      int.tryParse(
        jsString(
          input['userid'] ?? endpointCookie(context, input, 'userid') ?? 0,
        ),
      ) ??
      0;
  final token = jsString(
    input['token'] ?? endpointCookie(context, input, 'token') ?? '',
  );
  final mid = jsString(
    input['mid'] ??
        endpointCookie(context, input, 'mid') ??
        endpointCookie(context, input, 'KUGOU_API_MID') ??
        '',
  );
  final uuid = stringParameter(input, 'uuid', '-');
  final dfid = jsString(
    input['dfid'] ?? endpointCookie(context, input, 'dfid') ?? '-',
  );
  final clientTime = context.nowSeconds;
  final body = <String, Object?>{
    'mid': mid,
    'type': input['type'] ?? 1,
    'uuid': uuid,
    'userid': userId,
  };
  final isReport = input['d_sec'] != null && input['diff_sec'] != null;
  if (isReport) {
    final durationSeconds = intParameter(input, 'd_sec');
    final differenceSeconds = intParameter(input, 'diff_sec');
    final yearType = intParameter(input, 'y_type');
    final monthType = intParameter(input, 'm_type');
    final verification = md5Hex(
      '$durationSeconds$differenceSeconds$yearType$monthType',
    );
    body
      ..['p'] = context.crypto.rsaRawEncrypt(<String, Object?>{
        'token': token,
        'md5': verification,
      }, publicKeyPem: publicKey).toUpperCase()
      ..['d_sec'] = durationSeconds
      ..['diff_sec'] = differenceSeconds
      ..['y_type'] = yearType
      ..['m_type'] = monthType;
  } else {
    final inner = jsJsonEncode(<String, Object?>{
      'clienttime': clientTime,
      'userid': userId,
    });
    body['p'] = context.crypto
        .rsaRawEncrypt(inner, publicKeyPem: publicKey)
        .toUpperCase();
  }
  body
    ..['appid'] = appId
    ..['clientver'] = clientVersion
    ..['clienttime'] = clientTime
    ..['key'] = md5Hex('$appId$appKey$clientVersion$clientTime');

  return context.request(
    KugouRequest(
      baseUri: Uri.parse('http://userinfo.user.kugou.com'),
      path: '/v2/get_grade_info',
      method: 'POST',
      parameters: <String, Object?>{'dfid': dfid},
      data: body,
      headers: <String, Object?>{
        'Content-Type': 'text/plain; charset=ISO-8859-1',
        'User-Agent':
            'Android15-1070-$clientVersion-201-0-'
            'get_user_grade_info-wifi',
        'KG-THash': _randomHex(7),
        'KG-Rec': '1',
        'KG-RC': '1',
      },
      cookies: stringStringMap(input['cookie']),
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );
}

String _randomHexBytes(int byteLength) {
  final random = Random.secure();
  return List<String>.generate(
    byteLength,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    growable: false,
  ).join();
}

String _randomHex(int length) {
  final random = Random.secure();
  final maximum = 1 << (length * 4);
  return random.nextInt(maximum).toRadixString(16).padLeft(length, '0');
}
