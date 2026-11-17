import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'endpoint.dart';
import 'js_compat.dart';
import 'models.dart';
import 'utilities.dart';

/// Port of the upstream `createCloudRequest` used by cloudlist.service.
Future<KugouResponse<Object?>> createCloudRequest(
  KugouEndpointContext context, {
  required String path,
  required Object? data,
  Map<String, Object?> cookies = const <String, Object?>{},
}) async {
  final mergedCookies = <String, String>{
    ...context.session.cookies,
    ...stringStringMap(cookies),
  };
  final isLite = context.config.isLite;
  final appId = isLite ? 3116 : 1005;
  final clientVer = isLite ? 11440 : 20489;
  final appKey = isLite
      ? 'LnT6xpN3khm36zse0QzvmgTZ3waWdRSA'
      : 'OIlwieks28dk2k092lksi2UIkp';
  final mid = jsString(
    jsOr(mergedCookies['KUGOU_API_MID'], jsOr(mergedCookies['mid'], '')),
  );
  final dfid = jsString(jsOr(mergedCookies['dfid'], '-'));
  final userid = jsOr(mergedCookies['userid'], 0);
  final token = jsString(jsOr(mergedCookies['token'], ''));
  final clienttime = context.nowSeconds;
  const alphabet =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final secureRandom = Random.secure();
  final random = List<String>.generate(
    6,
    (_) => alphabet[secureRandom.nextInt(alphabet.length)],
    growable: false,
  ).join();
  final digest = md5Hex(random);
  final aesKey = digest.substring(0, 16);
  final aesIv = digest.substring(16, 32);
  final key = md5Hex('$appId$appKey$clientVer$clienttime').toLowerCase();
  final portrait = context.crypto.rsaPkcs1Encrypt(<String, Object?>{
    'aes': random,
    'uid': userid,
    'token': token,
  }).toUpperCase();
  final parameters = <String, Object?>{
    'appid': appId,
    'clientver': clientVer,
    'mid': mid,
    'clienttime': clienttime,
    'key': key,
    'dfid': dfid,
    'p': portrait,
  };
  final rawData = data is String
      ? data
      : data is Map<Object?, Object?> || data is Iterable<Object?>
      ? jsJsonEncode(data)
      : jsString(data);
  final encrypted = context.crypto.aesCbcEncryptBytes(
    Uint8List.fromList(utf8.encode(rawData)),
    key: Uint8List.fromList(utf8.encode(aesKey)),
    iv: Uint8List.fromList(utf8.encode(aesIv)),
  );
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://gateway.kugou.com'),
      path: path,
      method: 'POST',
      parameters: parameters,
      data: encrypted,
      headers: <String, Object?>{
        'Content-Type': 'application/json;charset=utf-8',
        'x-router': 'cloudlist.service.kugou.com',
        'dfid': dfid,
        'clienttime': '$clienttime',
        'mid': mid,
        'kg-rc': '1',
        'kg-thash': '5d816a0',
        'kg-rec': 1,
        'kg-rf': 'B9EDA08A64250DEFFBCADDEE00F8F25F',
      },
      clearDefaultParameters: true,
      clearDefaultHeaders: true,
      skipSignature: true,
      responseType: KugouResponseType.bytes,
    ),
  );
  final bytes = response.body is Uint8List
      ? response.body! as Uint8List
      : _asBytes(response.body);
  Object? decoded;
  if (bytes != null) {
    try {
      final plain = context.crypto.aesCbcDecryptBytes(
        bytes,
        key: Uint8List.fromList(utf8.encode(aesKey)),
        iv: Uint8List.fromList(utf8.encode(aesIv)),
      );
      final text = utf8.decode(plain, allowMalformed: true);
      decoded = _tryJson(text);
    } on Object {
      decoded = null;
    }
    decoded ??= _tryJson(utf8.decode(bytes, allowMalformed: true));
    decoded ??= <String, Object?>{
      'status': 0,
      'msg': utf8.decode(bytes, allowMalformed: true),
    };
  } else {
    decoded = response.body;
  }
  final body = stringObjectMap(decoded);
  final failed =
      body['status'] == 0 ||
      (body['error_code'] != null && jsNumber(body['error_code']) != 0);
  final normalized = KugouResponse<Object?>(
    status: failed ? 502 : 200,
    httpStatus: response.httpStatus,
    body: body.isEmpty ? decoded : body,
    cookies: response.cookies,
    headers: response.headers,
  );
  if (failed && context.config.throwOnApiError) {
    throw KugouApiException(normalized);
  }
  return normalized;
}

Uint8List? _asBytes(Object? value) {
  if (value is Uint8List) return value;
  if (value is List<int>) return Uint8List.fromList(value);
  return null;
}

Object? _tryJson(String value) {
  try {
    return jsonDecode(value);
  } on FormatException {
    return null;
  }
}
