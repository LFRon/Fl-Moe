import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../crypto.dart';
import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createCloudEndpointHandlers() =>
    <String, KugouEndpointHandler>{
      '/user/cloud': _userCloud,
      '/user/cloud/del': _userCloudDelete,
      '/user/cloud/match': _userCloudMatch,
      '/user/cloud/upload': _userCloudUpload,
    };

Future<KugouResponse<Object?>> _userCloud(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final encrypted = context.crypto.playlistAesEncrypt(<String, Object?>{
    'page': intParameter(input, 'page', 1),
    'pagesize': intParameter(input, 'pagesize', 30),
    'getkmr': 1,
  });
  return _sendCloudRequest(
    context,
    input,
    path: '/v1/get_list',
    encrypted: encrypted,
  );
}

Future<KugouResponse<Object?>> _userCloudDelete(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final fileIds = _splitList(
    input['fileids'] ?? input['fileid'] ?? input['kv_ids'] ?? input['kv_id'],
  );
  if (fileIds.isEmpty) {
    throw ArgumentError('请传入 fileid 或 kv_id');
  }
  final albumAudioIds = _splitList(
    input['album_audio_ids'] ?? input['album_audio_id'],
  );
  final fallbackAlbumAudioId = input['mixid'] ?? input['mix_id'] ?? 0;
  final encrypted = context.crypto.playlistAesEncrypt(<String, Object?>{
    'data': <Object?>[
      for (var index = 0; index < fileIds.length; index++)
        <String, Object?>{
          'kv_id': _numberOrString(fileIds[index]),
          'album_audio_id': _numberOrZero(
            _atOrFirst(albumAudioIds, index) ?? fallbackAlbumAudioId,
          ),
        },
    ],
  });
  return _sendCloudRequest(
    context,
    input,
    path: '/v1/del_files',
    encrypted: encrypted,
  );
}

Future<KugouResponse<Object?>> _sendCloudRequest(
  KugouEndpointContext context,
  Map<String, Object?> input, {
  required String path,
  required KugouAesResult encrypted,
}) async {
  final userId = _userId(context, input);
  final token = _token(context, input);
  final appId = input['appid'] ?? context.config.appId;
  final clientVersion = input['clientver'] ?? context.config.clientVersion;
  final clientTime = context.nowSeconds;
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://mcloudservice.kugou.com'),
      path: path,
      method: 'POST',
      parameters: <String, Object?>{
        'clienttime': clientTime,
        'mid': _mid(context, input),
        'key': context.signatures.parametersKey(
          clientTime.toString(),
          appId,
          clientVersion,
        ),
        'clientver': clientVersion,
        'appid': appId,
        'p': context.crypto.rsaPkcs1Encrypt(<String, Object?>{
          'aes': encrypted.key,
          'uid': userId,
          'token': token,
        }).toUpperCase(),
      },
      data: base64Decode(encrypted.ciphertext),
      cookies: _suppliedCookies(input),
      clearDefaultParameters: true,
      skipSignature: true,
      responseType: KugouResponseType.bytes,
    ),
  );
  return _replaceBody(
    response,
    _decryptCloudResponse(context, response.body, encrypted.key),
  );
}

Future<KugouResponse<Object?>> _userCloudMatch(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final hashes = _splitList(input['hash'] ?? input['filename']);
  if (hashes.isEmpty) {
    final bytes = _optionalBytes(input['data']);
    if (bytes != null && bytes.isNotEmpty) {
      hashes.add(md5.convert(bytes).toString().toLowerCase());
    }
  }
  if (hashes.isEmpty) {
    throw ArgumentError('请传入 hash，或通过 data 传入文件二进制数据');
  }

  final albumAudioIds = _splitList(
    input['album_audio_ids'] ??
        input['album_audio_id'] ??
        input['mixid'] ??
        input['mix_id'],
  );
  final appId = input['appid'] ?? context.config.appId;
  final clientVersion = input['clientver'] ?? context.config.clientVersion;
  final clientTime = context.nowSeconds;
  final data = <Object?>[
    for (var index = 0; index < hashes.length; index++)
      <String, Object?>{
        'hash': hashes[index].toLowerCase(),
        if (_positiveNumber(_atOrFirst(albumAudioIds, index)) != null)
          'album_audio_id': _positiveNumber(
            _atOrFirst(albumAudioIds, index),
          ).toString(),
      },
  ];
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('http://kmr.service.kugou.com'),
      path: '/v2/album_audio/audio',
      method: 'POST',
      data: <String, Object?>{
        'appid': appId,
        'clienttime': clientTime,
        'clientver': clientVersion,
        'data': data,
        'dfid': endpointCookie(context, input, 'dfid') ?? input['dfid'] ?? '-',
        'key': context.signatures.parametersKey(
          clientTime.toString(),
          appId,
          clientVersion,
        ),
        'mid': _mid(context, input),
        'show_privilege': 0,
        'show_author_alias': 0,
        'show_rel_album_audio_info': 0,
        'show_remarks': 0,
      },
      headers: const <String, Object?>{
        'x-router': 'kmr.service.kugou.com',
        'Content-Type': 'application/json',
      },
      cookies: _suppliedCookies(input),
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );

  final body = Map<String, Object?>.from(stringObjectMap(response.body));
  final rawData = body['data'];
  if (body['status'] == 1 && rawData is List<Object?>) {
    final matches = <Object?>[
      for (final item in rawData) ?_normalizeMatch(_firstCandidate(item)),
    ];
    body
      ..['match_list'] = matches
      ..['match'] = matches.isEmpty ? null : matches.first;
    return _replaceBody(response, body);
  }
  return response;
}

Future<KugouResponse<Object?>> _userCloudUpload(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final fileData = _requiredBytes(input['data']);
  if (fileData.isEmpty) {
    throw ArgumentError('请通过 data 传入文件二进制数据');
  }

  final userId = _userId(context, input);
  final token = _token(context, input);
  final mid = _mid(context, input);
  final dfid = endpointCookie(context, input, 'dfid') ?? input['dfid'] ?? '-';
  final uuid =
      endpointCookie(context, input, 'KUGOU_API_GUID') ?? input['uuid'] ?? '-';
  final appId = input['appid'] ?? context.config.appId;
  final clientVersion = input['clientver'] ?? context.config.clientVersion;
  final filename = stringParameter(
    input,
    'filename',
    md5.convert(fileData).toString(),
  ).toLowerCase();
  final extendName = stringParameter(
    input,
    'extendname',
    'mp3',
  ).replaceFirst(RegExp(r'^\.'), '');
  const bucket = 'musicclound';

  Map<String, Object?>? matchInfo;
  final alreadyMatched =
      jsTruthy(input['hash_std']) &&
      jsTruthy(input['audio_id']) &&
      jsTruthy(input['album_audio_id'] ?? input['mixid'] ?? input['mix_id']);
  if (boolParameter(input, 'auto_match', true) && !alreadyMatched) {
    final matchResponse = await _userCloudMatch(context, <String, Object?>{
      ...input,
      'data': null,
      'hash': filename,
      'appid': appId,
      'clientver': clientVersion,
    });
    final matchBody = stringObjectMap(matchResponse.body);
    if (matchBody['status'] == 1) matchInfo = _extractMatch(matchBody);
  }

  final hashStandard = jsString(
    input['hash_std'] ?? matchInfo?['hash_std'] ?? filename,
  ).toLowerCase();
  final audioId = _numberOrZero(input['audio_id'] ?? matchInfo?['audio_id']);
  final albumAudioId = _numberOrZero(
    input['album_audio_id'] ??
        input['mixid'] ??
        input['mix_id'] ??
        matchInfo?['album_audio_id'],
  );
  final authorName = jsString(
    input['author_name'] ?? matchInfo?['author_name'] ?? '',
  );
  final trackName = jsString(
    input['track_name'] ??
        input['songname'] ??
        matchInfo?['audio_name'] ??
        filename,
  );
  final displayName = jsString(
    input['name'] ??
        '${authorName.isEmpty ? '' : '$authorName - '}$trackName.$extendName',
  );

  Map<String, Object?> signBss(Map<String, Object?> parameters) {
    parameters['signature'] = context.signatures.android(parameters);
    return parameters;
  }

  final authParameters = signBss(<String, Object?>{
    'bucket': bucket,
    'filename': filename,
    'method': 'POST',
    'loginType': token.isNotEmpty && userId != '0' ? 1 : 0,
    'buVerifyCode': md5Hex(
      '$appId$bucket'
      '8ae10344e9738dcb',
    ),
    'extranet': 1,
    'userid': userId,
    'token': token,
    'version': clientVersion,
    'dfid': dfid,
    'mid': mid,
    'uuid': uuid,
    'appid': appId,
    'clientver': clientVersion,
    'clienttime': context.nowSeconds,
  });
  final authResponse = await _bssRequest(
    context,
    path: '/bsstrackercdngz/v1/upload/auth',
    parameters: authParameters,
  );
  final authBody = stringObjectMap(authResponse.body);
  final authData = stringObjectMap(authBody['data']);
  final authorization = jsString(authData['authorization']);
  if (authorization.isEmpty) {
    throw StateError('获取上传授权失败: ${jsJsonEncode(authBody)}');
  }

  final initParameters = signBss(<String, Object?>{
    'bucket': bucket,
    'filename': filename,
    'ssl': 1,
    'extendname': extendName,
    'version': clientVersion,
    'userid': userId,
    'token': token,
    'authorization': authorization,
    'dfid': dfid,
    'mid': mid,
    'uuid': uuid,
    'appid': appId,
    'clientver': clientVersion,
    'clienttime': context.nowSeconds,
  });
  final initResponse = await _bssRequest(
    context,
    baseUri: Uri.parse('http://bssulbig.kugou.com'),
    path: '/v2/multipart/initiate/music',
    method: 'POST',
    parameters: initParameters,
    authorization: authorization,
  );
  final initBody = stringObjectMap(initResponse.body);
  final initData = stringObjectMap(initBody['data']);
  final externalHost = jsString(initData['external_host']);
  final uploadId = jsString(initData['upload_id']);
  var bssFileHash = jsString(initData['x-bss-filename']);
  if (bssFileHash.isEmpty) bssFileHash = filename;

  if (uploadId.isNotEmpty) {
    if (externalHost.isEmpty) {
      throw StateError('初始化上传失败: ${jsJsonEncode(initBody)}');
    }
    const partSize = 1024 * 1024;
    final partCount = max(1, (fileData.length / partSize).ceil());
    final uploadBase = _withProtocol(externalHost);
    for (var index = 0; index < partCount; index++) {
      final end = min(fileData.length, (index + 1) * partSize);
      final part = Uint8List.sublistView(fileData, index * partSize, end);
      final uploadParameters = signBss(<String, Object?>{
        'bucket': bucket,
        'authorization': authorization,
        'filename': filename,
        'partnumber': index + 1,
        'upload_id': uploadId,
        'body_empty': 1,
        'version': clientVersion,
        'userid': userId,
        'token': token,
        'dfid': dfid,
        'mid': mid,
        'uuid': uuid,
        'appid': appId,
        'clientver': clientVersion,
        'clienttime': context.nowSeconds,
      });
      final uploadResponse = await _bssRequest(
        context,
        baseUri: uploadBase,
        path: '/v3/multipart/upload',
        method: 'POST',
        parameters: uploadParameters,
        authorization: authorization,
        body: part,
        contentType: 'application/octet-stream',
      );
      if (stringObjectMap(uploadResponse.body)['status'] != 1) {
        throw StateError('分片上传失败: ${jsJsonEncode(uploadResponse.body)}');
      }
    }

    final completeParameters = signBss(<String, Object?>{
      'bucket': bucket,
      'authorization': authorization,
      'filename': filename,
      'partnumber': partCount,
      'upload_id': uploadId,
      'md5': filename,
      'version': clientVersion,
      'userid': userId,
      'token': token,
      'if_id3': 1,
      'dfid': dfid,
      'mid': mid,
      'uuid': uuid,
      'appid': appId,
      'clientver': clientVersion,
      'clienttime': context.nowSeconds,
    });
    final completeResponse = await _bssRequest(
      context,
      baseUri: uploadBase,
      path: '/v3/multipart/complete',
      method: 'POST',
      parameters: completeParameters,
      authorization: authorization,
    );
    final completeBody = stringObjectMap(completeResponse.body);
    if (completeBody['status'] != 1) {
      throw StateError('完成上传失败: ${jsJsonEncode(completeBody)}');
    }
    final completeData = stringObjectMap(completeBody['data']);
    final completedHash = jsString(completeData['x-bss-filename']);
    if (completedHash.isNotEmpty) bssFileHash = completedHash;
  }

  final encrypted = context.crypto.playlistAesEncrypt(<String, Object?>{
    'data': <Object?>[
      <String, Object?>{
        'name': displayName,
        'ext': extendName,
        'author_name': authorName,
        'hash': bssFileHash,
        'hash_std': hashStandard,
        'audio_id': audioId,
        'bitrate': intParameter(input, 'bitrate', 4),
        'album_audio_id': albumAudioId,
        'size': fileData.length,
        'timelen': intParameter(input, 'timelen'),
      },
    ],
    'list_ver': intParameter(input, 'list_ver'),
  });
  final cloudResponse = await _sendCloudRequest(
    context,
    <String, Object?>{
      ...input,
      'userid': userId,
      'token': token,
      'appid': appId,
      'clientver': clientVersion,
    },
    path: '/v1/add_files',
    encrypted: encrypted,
  );
  final cloudBody = stringObjectMap(cloudResponse.body);
  cloudBody['uploadInfo'] = <String, Object?>{
    'authorization': authorization,
    'external_host': externalHost,
    'upload_id': uploadId,
    'hash': bssFileHash,
    'local_hash': filename,
    'hash_std': hashStandard,
    'audio_id': audioId,
    'album_audio_id': albumAudioId,
    'matched': matchInfo != null,
    'filesize': fileData.length,
  };
  return _replaceBody(cloudResponse, cloudBody);
}

Future<KugouResponse<Object?>> _bssRequest(
  KugouEndpointContext context, {
  Uri? baseUri,
  required String path,
  String method = 'GET',
  required Map<String, Object?> parameters,
  String? authorization,
  Object? body,
  String? contentType,
}) => context.request(
  KugouRequest(
    baseUri: baseUri ?? Uri.parse('https://gateway.kugou.com'),
    path: path,
    method: method,
    parameters: parameters,
    data: body,
    headers: <String, Object?>{
      'User-Agent': 'Android15-1070-${parameters['clientver']}-201-0-wifi',
      'KG-RC': '1',
      'KG-Rec': '1',
      'KG-THash': _randomHex(7),
      'Authorization': ?authorization,
      'Content-Type': ?contentType,
    },
    clearDefaultParameters: true,
    clearDefaultHeaders: true,
    skipSignature: true,
  ),
);

Map<String, Object?>? _normalizeMatch(Object? candidate) {
  final map = stringObjectMap(candidate);
  if (map.isEmpty) return null;
  final audioInfo = stringObjectMap(map['audio_info']);
  final albumAudioId = _numberOrZero(map['album_audio_id']);
  final audioId = _numberOrZero(audioInfo['audio_id'] ?? map['audio_id']);
  final hash = jsString(audioInfo['hash'] ?? map['hash']);
  if (albumAudioId == 0 && audioId == 0 && hash.isEmpty) return null;
  return <String, Object?>{
    'album_audio_id': albumAudioId,
    'audio_id': audioId,
    'hash_std': hash,
    'hash': hash,
    'author_name': map['author_name'] ?? '',
    'audio_name':
        map['ori_audio_name'] ?? map['audio_name'] ?? map['songname'] ?? '',
    'suffix_audio_name': map['suffix_audio_name'] ?? '',
    'album_info': map['album_info'],
    'raw': map,
  };
}

Object? _firstCandidate(Object? item) {
  if (item is List<Object?>) return item.isEmpty ? null : item.first;
  return item;
}

Map<String, Object?>? _extractMatch(Map<String, Object?> body) {
  final direct = stringObjectMap(body['match']);
  if (direct.isNotEmpty) return direct;
  final list = body['match_list'];
  if (list is List<Object?> && list.isNotEmpty) {
    final first = stringObjectMap(list.first);
    if (first.isNotEmpty) return first;
  }
  final data = body['data'];
  if (data is List<Object?> && data.isNotEmpty) {
    return _normalizeMatch(_firstCandidate(data.first));
  }
  return null;
}

Object? _decryptCloudResponse(
  KugouEndpointContext context,
  Object? body,
  String key,
) {
  final bytes = _optionalBytes(body);
  if (bytes == null) return body;
  try {
    return context.crypto.playlistAesDecrypt(base64Encode(bytes), key);
  } on Object {
    final text = utf8.decode(bytes, allowMalformed: true);
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }
}

List<String> _splitList(Object? value) {
  final result = <String>[];
  void add(Object? item) {
    if (item == null) return;
    if (item is Iterable<Object?> && item is! String) {
      for (final nested in item) {
        add(nested);
      }
      return;
    }
    final text = item.toString().trim();
    if (text.isEmpty) return;
    if (text.startsWith('[') && text.endsWith(']')) {
      try {
        add(jsonDecode(text));
        return;
      } on FormatException {
        // Fall through to comma splitting.
      }
    }
    result.addAll(
      text
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty),
    );
  }

  add(value);
  return result;
}

Uint8List _requiredBytes(Object? value) {
  final bytes = _optionalBytes(value);
  if (bytes == null) {
    throw ArgumentError.value(value, 'data', 'Expected Uint8List or List<int>');
  }
  return bytes;
}

Uint8List? _optionalBytes(Object? value) {
  if (value is Uint8List) return value;
  if (value is List<int>) return Uint8List.fromList(value);
  if (value is Iterable<Object?>) {
    final bytes = <int>[];
    for (final item in value) {
      if (item is! int || item < 0 || item > 255) return null;
      bytes.add(item);
    }
    return Uint8List.fromList(bytes);
  }
  return null;
}

String _userId(KugouEndpointContext context, Map<String, Object?> input) =>
    jsString(input['userid'] ?? endpointCookie(context, input, 'userid') ?? 0);

String _token(KugouEndpointContext context, Map<String, Object?> input) =>
    jsString(input['token'] ?? endpointCookie(context, input, 'token') ?? '');

String _mid(KugouEndpointContext context, Map<String, Object?> input) =>
    jsString(
      input['mid'] ?? endpointCookie(context, input, 'KUGOU_API_MID') ?? '',
    );

Map<String, String> _suppliedCookies(Map<String, Object?> input) =>
    stringStringMap(input['cookie']);

Object _numberOrString(String value) => num.tryParse(value) ?? value;

int _numberOrZero(Object? value) =>
    jsNumber(value).isFinite ? jsNumber(value).toInt() : 0;

num? _positiveNumber(Object? value) {
  final number = jsNumber(value);
  return number.isFinite && number > 0 ? number : null;
}

String? _atOrFirst(List<String> values, int index) {
  if (values.isEmpty) return null;
  return index < values.length ? values[index] : values.first;
}

Uri _withProtocol(String host) {
  final value = RegExp(r'^https?://', caseSensitive: false).hasMatch(host)
      ? host
      : 'http://$host';
  return Uri.parse(value);
}

String _randomHex(int length) {
  final random = Random.secure();
  final maximum = 1 << (length * 4);
  return random.nextInt(maximum).toRadixString(16).padLeft(length, '0');
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
