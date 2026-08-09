import 'dart:convert';
import 'dart:typed_data';

import '../endpoint.dart';
import '../models.dart';

Map<String, KugouEndpointHandler> createMiscEndpointHandlers() =>
    <String, KugouEndpointHandler>{
      '/ip/zone': _ipZone,
      '/playlist/del': _playlistDelete,
      '/register/dev': _registerDevice,
      '/top/ip': _topIp,
    };

Future<KugouResponse<Object?>> _ipZone(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final response = await context.request(
    KugouRequest(
      path: '/v1/zone/index',
      headers: const <String, Object?>{'x-router': 'yuekucategory.kugou.com'},
    ),
  );
  final body = stringObjectMap(response.body);
  final data = stringObjectMap(body['data']);
  final rawList = data['list'];
  if (body['status'] == 1 && rawList is List<Object?>) {
    final list = <Object?>[
      for (final item in rawList) _addIpIdFromSpecialLink(item),
    ];
    data['list'] = list;
    body['data'] = data;
    return _replaceBody(response, body);
  }
  return response;
}

Object? _addIpIdFromSpecialLink(Object? item) {
  final map = stringObjectMap(item);
  final specialLink = map['special_link'];
  if (specialLink is! String || specialLink.isEmpty) return item;
  final outer = _queryParameters(specialLink);
  final path = outer['path'];
  if (path == null) return map;
  final ipId = num.tryParse(_queryParameters(path)['ip_id'] ?? '');
  if (ipId != null) map['ip_id'] = ipId.toInt();
  return map;
}

Map<String, String> _queryParameters(String value) {
  try {
    final parsed = Uri.parse(value);
    if (parsed.queryParameters.isNotEmpty) return parsed.queryParameters;
    return Uri.splitQueryString(
      value.startsWith('?') ? value.substring(1) : value,
    );
  } on FormatException {
    return <String, String>{};
  }
}

Future<KugouResponse<Object?>> _topIp(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('http://musicadservice.kugou.com'),
      path: '/v1/daily_recommend',
      method: 'POST',
      parameters: <String, Object?>{'clientver': 12349, 'area_code': 1},
      data: <String, Object?>{'tags': <String, Object?>{}},
    ),
  );
  final body = stringObjectMap(response.body);
  final data = stringObjectMap(body['data']);
  final rawList = data['list'];
  if (body['status'] == 1 && rawList is List<Object?>) {
    data['list'] = <Object?>[
      for (final item in rawList) _addIpIdFromInnerUrl(item),
    ];
    body['data'] = data;
    return _replaceBody(response, body);
  }
  return response;
}

Object? _addIpIdFromInnerUrl(Object? item) {
  final map = stringObjectMap(item);
  final extra = stringObjectMap(map['extra']);
  final innerUrl = extra['inner_url'];
  if (innerUrl is String) {
    final index = innerUrl.lastIndexOf('ip_id');
    if (index >= 0) {
      final ipId = num.tryParse(innerUrl.substring(index + 6));
      if (ipId != null) extra['ip_id'] = ipId.toInt();
    }
  }
  map['extra'] = extra;
  return map;
}

Future<KugouResponse<Object?>> _playlistDelete(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userId =
      input['userid'] ?? endpointCookie(context, input, 'userid') ?? 0;
  final token = input['token'] ?? endpointCookie(context, input, 'token') ?? '';
  final now = context.nowSeconds;
  final encrypted = context.crypto.playlistAesEncrypt(<String, Object?>{
    'listid': jsNumber(input['listid']).toInt(),
    'total_ver': 0,
    'type': 1,
  });
  final response = await context.request(
    KugouRequest(
      path: '/v2/delete_list',
      method: 'POST',
      parameters: <String, Object?>{
        'clienttime': now,
        'key': context.signatures.parametersKey(now.toString()),
        'last_area': 'gztx',
        'clientver': context.config.clientVersion,
        'appid': context.config.appId,
        'last_time': now,
        'p': context.crypto.rsaPkcs1Encrypt(<String, Object?>{
          'aes': encrypted.key,
          'uid': userId,
          'token': token,
        }).toUpperCase(),
      },
      data: encrypted.ciphertext,
      responseType: KugouResponseType.bytes,
      headers: const <String, Object?>{
        'x-router': 'cloudlist.service.kugou.com',
      },
    ),
  );
  return _decryptPlaylistResponse(context, response, encrypted.key);
}

Future<KugouResponse<Object?>> _registerDevice(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userId =
      input['userid'] ?? endpointCookie(context, input, 'userid') ?? 0;
  final token = input['token'] ?? endpointCookie(context, input, 'token') ?? '';
  final guid = endpointCookie(context, input, 'KUGOU_API_GUID');
  final body = <String, Object?>{
    'availableRamSize': jsOr(input['availableRamSize'], 4983533568),
    'availableRomSize': jsOr(input['availableRomSize'], 48114719),
    'availableSDSize': jsOr(input['availableSDSize'], 48114717),
    'basebandVer': jsOr(input['basebandVer'], ''),
    'batteryLevel': jsOr(input['batteryLevel'], 100),
    'batteryStatus': jsOr(input['batteryStatus'], 3),
    'brand': jsOr(input['brand'], 'Redmi'),
    'buildSerial': jsOr(input['buildSerial'], 'unknown'),
    'device': jsOr(input['device'], 'marble'),
    'imei': jsOr(input['imei'], guid),
    'imsi': jsOr(input['imsi'], ''),
    'manufacturer': jsOr(input['manufacturer'], 'Xiaomi'),
    'uuid': jsOr(input['uuid'], guid),
    for (final name in const <String>[
      'accelerometer',
      'gravity',
      'gyroscope',
      'light',
      'magnetic',
      'orientation',
      'pressure',
      'step_counter',
      'temperature',
    ])
      name: jsOr(input[name], false),
    for (final name in const <String>[
      'accelerometerValue',
      'gravityValue',
      'gyroscopeValue',
      'lightValue',
      'magneticValue',
      'orientationValue',
      'pressureValue',
      'step_counterValue',
      'temperatureValue',
    ])
      name: jsOr(input[name], ''),
  };
  final encrypted = context.crypto.playlistAesEncrypt(body);
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://userservice.kugou.com'),
      path: '/risk/v2/r_register_dev',
      method: 'POST',
      parameters: <String, Object?>{
        'part': 1,
        'platid': 1,
        'p': context.crypto.rsaPkcs1Encrypt(<String, Object?>{
          'aes': encrypted.key,
          'uid': userId,
          'token': token,
        }),
      },
      data: encrypted.ciphertext,
      responseType: KugouResponseType.bytes,
    ),
  );
  final decrypted = _decryptPlaylistResponse(context, response, encrypted.key);
  final responseBody = stringObjectMap(decrypted.body);
  final responseData = stringObjectMap(responseBody['data']);
  final dfid = responseData['dfid'];
  if (responseBody['status'] == 1 && dfid != null) {
    final cookie = 'dfid=$dfid';
    context.session.updateCookies(<String>[cookie]);
    return KugouResponse<Object?>(
      status: decrypted.status,
      httpStatus: decrypted.httpStatus,
      body: decrypted.body,
      cookies: <String>[...decrypted.cookies, cookie],
      headers: decrypted.headers,
    );
  }
  return decrypted;
}

KugouResponse<Object?> _decryptPlaylistResponse(
  KugouEndpointContext context,
  KugouResponse<Object?> response,
  String key,
) {
  final bytes = response.body;
  if (bytes is! Uint8List) return response;
  final body = context.crypto.playlistAesDecrypt(base64Encode(bytes), key);
  return _replaceBody(response, body);
}

KugouResponse<Object?> _replaceBody(
  KugouResponse<Object?> response,
  Object? body,
) => KugouResponse<Object?>(
  status: response.status,
  httpStatus: response.httpStatus,
  body: body,
  cookies: response.cookies,
  headers: response.headers,
);
