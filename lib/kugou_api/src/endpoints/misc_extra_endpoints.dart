import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createMiscExtraHandlers() =>
    <String, KugouEndpointHandler>{
      '/album/dycover': _albumDycover,
      '/mv/collect': _mvCollect,
      '/mv/collect/del': _mvCollectDel,
      '/song/url/auth/merge': _songUrlAuthMerge,
    };

Future<KugouResponse<Object?>> _albumDycover(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final audioIds = jsString(jsOr(input['album_audio_id'], '')).split(',');
  final albumIds = jsString(jsOr(input['album_id'], '')).split(',');
  final data = <Object?>[
    for (var index = 0; index < audioIds.length; index++)
      <String, Object?>{
        'album_audio_id': jsNumber(audioIds[index]).toInt(),
        if (_indexValue(albumIds, index) > 0)
          'album_id': _indexValue(albumIds, index),
      },
  ];
  final parameters = <String, Object?>{
    'appid': 1005,
    'clientver': 20489,
    'data': data,
    'isCdn': 1,
    'query': jsOr(input['query'], 'audioPlay'),
  };
  final keys = parameters.keys.toList()..sort();
  final query = keys
      .map((key) {
        final value = parameters[key];
        final source =
            value is Map<Object?, Object?> || value is Iterable<Object?>
            ? jsJsonEncode(value)
            : jsString(value);
        return '$key=${Uri.encodeComponent(source)}';
      })
      .join('&');
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://kmrcdn.service.kugou.com'),
      path: '/v2/album/audio?$query',
      method: 'GET',
      parameters: <String, Object?>{
        'signature': context.signatures.androidStandard(parameters),
      },
      headers: <String, Object?>{
        'dfid': '-',
        'mid': 'undefined',
        'clienttime': context.nowSeconds,
      },
      clearDefaultParameters: true,
      clearDefaultHeaders: true,
      skipSignature: true,
    ),
  );
}

int _indexValue(List<String> values, int index) =>
    index < values.length ? jsNumber(values[index]).toInt() : 0;

Future<KugouResponse<Object?>> _mvCollect(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => _mvCollectRequest(context, input, '/v1/collect', 'Care');

Future<KugouResponse<Object?>> _mvCollectDel(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => _mvCollectRequest(context, input, '/v1/cancel_collect', 'UnCare');

Future<KugouResponse<Object?>> _mvCollectRequest(
  KugouEndpointContext context,
  Map<String, Object?> input,
  String path,
  String action,
) async {
  final userid = jsOr(
    input['userid'],
    jsOr(endpointCookie(context, input, 'userid'), 0),
  );
  final token = jsOr(
    input['token'],
    jsOr(endpointCookie(context, input, 'token'), ''),
  );
  final mid = jsOr(
    endpointCookie(context, input, 'mid'),
    jsOr(endpointCookie(context, input, 'KUGOU_API_MID'), 0),
  );
  final dfid = jsOr(
    input['dfid'],
    jsOr(endpointCookie(context, input, 'dfid'), '-'),
  );
  final clienttime = context.nowSeconds;
  final encrypted = context.crypto.playlistAesEncrypt(<String, Object?>{
    'ctype': 2,
    'data': <Object?>[
      <String, Object?>{'obj_id': jsNumber(input['id']).toInt()},
    ],
  });
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://collectservice.kugou.com'),
      path: path,
      method: 'POST',
      parameters: <String, Object?>{
        'clienttime': clienttime,
        'mid': mid,
        'key': context.signatures.parametersKey('$clienttime'),
        'dfid': dfid,
        'clientver': context.config.clientVersion,
        'appid': context.config.appId,
        'p': context.crypto.rsaPkcs1Encrypt(<String, Object?>{
          'aes': encrypted.key,
          'uid': userid,
          'token': token,
        }).toUpperCase(),
      },
      data: Uint8List.fromList(base64Decode(encrypted.ciphertext)),
      headers: <String, Object?>{
        'User-Agent':
            'Android9-1070-${context.config.clientVersion}-18-0-MV/$action-wifi',
        'KG-THash': _randomHex(7),
        'Content-Type': 'application/json',
      },
      skipSignature: true,
      responseType: KugouResponseType.bytes,
    ),
  );
  final bytes = response.body is Uint8List
      ? response.body! as Uint8List
      : response.body is List<int>
      ? Uint8List.fromList(response.body! as List<int>)
      : Uint8List(0);
  final body = context.crypto.playlistAesDecrypt(
    base64Encode(bytes),
    encrypted.key,
  );
  return KugouResponse<Object?>(
    status: response.status,
    httpStatus: response.httpStatus,
    body: body,
    cookies: response.cookies,
    headers: response.headers,
  );
}

Future<KugouResponse<Object?>> _songUrlAuthMerge(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final hash = jsString(jsOr(input['hash'], '')).toLowerCase();
  final albumAudioId = jsNumber(jsOr(input['album_audio_id'], 0)).toInt();
  final authorization = jsString(
    jsOr(input['auth'], jsOr(endpointCookie(context, input, 'auth'), '')),
  );
  final cookies = <String, String>{
    'dfid': randomString(24),
    ...context.session.cookies,
  };
  final authResponse = await context.request(
    KugouRequest(
      baseUri: Uri.parse('http://gateway.kugou.com/'),
      path: '/v1/authorization',
      method: 'GET',
      parameters: <String, Object?>{
        'authorization': authorization,
        'module_id': 51,
        'album_audio_id': albumAudioId,
        'clientver': 11561,
        'hash': hash,
      },
      headers: const <String, Object?>{'x-router': 'trackercdngz.kugou.com'},
      cookies: cookies,
    ),
  );
  final authData = stringObjectMap(stringObjectMap(authResponse.body)['data']);
  final auth = authData['auth'];
  final openTime = authData['open_time'];
  if (!jsTruthy(auth) && !jsTruthy(openTime)) {
    return rejectEndpoint(
      context,
      body: const <String, Object?>{
        'error': '获取 auth 和 open_time 失败',
        'status': 0,
      },
    );
  }
  const magicQualities = <String>{
    'piano',
    'acappella',
    'subwoofer',
    'ancient',
    'dj',
    'surnay',
  };
  final requestedQuality = input['quality'];
  final quality = magicQualities.contains(requestedQuality)
      ? 'magic_$requestedQuality'
      : jsOr(requestedQuality, 128);
  final isLite = context.config.isLite;
  final pageId = isLite ? 967177915 : 151369488;
  final ppageId = isLite
      ? jsOr(input['ppage_id'], '356753938,823673182,967485191')
      : '463467626,350369493,788954147';
  return context.request(
    KugouRequest(
      path: '/tracker/v5/url',
      method: 'GET',
      parameters: <String, Object?>{
        'album_id': jsNumber(jsOr(input['album_id'], 0)).toInt(),
        'area_code': 1,
        'module': '',
        'hash': hash,
        'need_m': 0,
        'ssa_flag': 'is_fromtrack',
        'version': 11430,
        'open_time': jsOr(openTime, 0),
        'ptype': 0,
        'need_ogg': 1,
        'page_id': pageId,
        'auth': jsOr(auth, ''),
        'mtype': 0,
        'quality': quality,
        'album_audio_id': albumAudioId,
        'behavior': 'play',
        'pid': isLite ? 411 : 2,
        'module_id': 51,
        'cmd': 26,
        'ppage_id': ppageId,
        'clientver': 11561,
        'pidversion': 3001,
        'cdnBackup': 1,
      },
      encryptKey: true,
      cookies: cookies,
    ),
  );
}

String _randomHex(int length) {
  final random = Random.secure();
  final maximum = 1 << (length * 4);
  return random.nextInt(maximum).toRadixString(16).padLeft(length, '0');
}
