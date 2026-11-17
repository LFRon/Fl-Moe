import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../crypto.dart';
import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';
import '../utilities.dart';
import 'grade_endpoints.dart';

const String _csccAppKey = 'LnT6xpN3khm36zse0QzvmgTZ3waWdRSA';
const String _csccVersion = '10597';

Map<String, KugouEndpointHandler> createUserListenReportHandlers() =>
    <String, KugouEndpointHandler>{'/user/listen/report': _userListenReport};

final Map<String, _CsccSession> _sessions = <String, _CsccSession>{};

final class _CsccSession {
  const _CsccSession({required this.pending, required this.expires});

  final Future<_CsccSessionData> pending;
  final int expires;
}

final class _CsccSessionData {
  const _CsccSessionData({
    required this.cookie,
    required this.clienttime,
    required this.serverstr,
    required this.field2,
  });

  final String cookie;
  final Object? clienttime;
  final String serverstr;
  final String field2;
}

final class _CsccFailure implements Exception {
  const _CsccFailure(this.body);

  final Map<String, Object?> body;
}

Future<KugouResponse<Object?>> _userListenReport(
  KugouEndpointContext context,
  Map<String, Object?> params,
) async {
  final cookie = stringObjectMap(params['cookie']);
  final uuid = jsString(
    jsOr(
      params['uuid'],
      jsOr(cookie['uuid'], jsOr(cookie['KUGOU_API_GUID'], '')),
    ),
  ).replaceAll('-', '');
  final mid = jsString(
    jsOr(params['mid'], jsOr(cookie['mid'], jsOr(cookie['KUGOU_API_MID'], ''))),
  );
  final userid = jsString(jsOr(params['userid'], jsOr(cookie['userid'], '')));
  final token = jsOr(params['token'], cookie['token']);
  final song = jsString(jsOr(params['mixsongid'], ''));
  final event = params['event'];
  final state = jsString(jsOr(params['state'], '完整播放'));
  final sync = params['d_sec'] != null || params['diff_sec'] != null;
  final deviceModel = jsString(
    jsOr(
      params['device_model'],
      jsOr(params['dev'], jsOr(cookie['KUGOU_API_DEV'], 'KuGouMusicApi')),
    ),
  );
  final systemVersion = jsString(jsOr(params['system_version'], '9'));
  final screenWidth = jsNumber(jsOr(params['screen_width'], 1920)).toInt();
  final screenHeight = jsNumber(jsOr(params['screen_height'], 1080)).toInt();
  final localIp = jsString(jsOr(params['local_ip'], '0.0.0.0'));
  if (!_validDevice(
    deviceModel,
    systemVersion,
    screenWidth,
    screenHeight,
    localIp,
  )) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'msg': '设备参数无效：需要有效机型、系统版本、正整数屏幕尺寸及 IPv4/IPv6 local_ip',
      },
    );
  }
  if (!_validUuid(uuid) ||
      mid.isEmpty ||
      !_integer(userid) ||
      int.parse(userid) <= 0 ||
      !jsTruthy(token)) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'msg': '需要 token、userid、mid 和 32 位字母数字 uuid（也可从 cookie 读取）',
      },
    );
  }
  if (!_integer(song) ||
      int.parse(song) <= 0 ||
      (event != 'start' && event != 'end')) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'msg': '需要有效 mixsongid 和 event=start|end',
      },
    );
  }
  final duration = jsNumber(params['duration']).toInt();
  if (event == 'end' && (!_integer('$duration') || state.isEmpty)) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'msg': '结束事件需要非负整数 duration（实际播放毫秒数）和有效 state',
      },
    );
  }
  if (sync &&
      (event != 'end' ||
          !_integer('${params['d_sec']}') ||
          !_integer('${params['diff_sec']}') ||
          jsNumber(params['diff_sec']).toInt() > (duration / 1000).ceil())) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'msg': '等级同步仅支持结束事件，需提供 d_sec、diff_sec（秒），增量不得超过本次播放时长',
      },
    );
  }

  Future<KugouResponse<Object?>> request(
    String path,
    String method,
    Map<String, Object?> query,
    Object? data,
    String kind,
  ) async {
    final response = await context.request(
      KugouRequest(
        baseUri: Uri.parse('http://d.kugou.com'),
        path: path,
        method: method,
        parameters: query,
        data: data,
        clearDefaultParameters: true,
        clearDefaultHeaders: true,
        skipSignature: true,
        headers: <String, Object?>{
          if (method == 'POST') 'Content-Type': 'application/octet-stream',
          if (path != '/v3/qrydid') ...<String, Object?>{
            'KG-Rec': '1',
            'User-Agent':
                'Android$systemVersion-1070-$_csccVersion-18-0-Cscc$kind-wifi',
          },
        },
      ),
    );
    final body = stringObjectMap(response.body);
    final failed =
        response.status != 200 ||
        body['status'] == 0 ||
        (body['errcode'] != null && jsString(body['errcode']) != '0') ||
        (body['error_code'] != null && jsString(body['error_code']) != '0');
    if (failed) {
      throw _CsccFailure(<String, Object?>{...body, 'stage': path});
    }
    return response;
  }

  final cacheKey = md5Hex(
    jsJsonEncode(<Object?>[
      uuid,
      mid,
      userid,
      token,
      deviceModel,
      systemVersion,
      screenWidth,
      screenHeight,
    ]),
  );
  final now = DateTime.now().millisecondsSinceEpoch;
  _sessions.removeWhere((_, entry) => entry.expires <= now);
  if (!_sessions.containsKey(cacheKey)) {
    if (_sessions.length >= 256) _sessions.remove(_sessions.keys.first);
    final pending = () async {
      var seconds = context.nowSeconds;
      final deviceData = jsJsonEncode(<String, Object?>{
        'machine': deviceModel,
        'mid': mid,
        'uuid': uuid,
        'wh': <Object?>[screenWidth, screenHeight],
      });
      final device = await request(
        '/v3/qrydid',
        'POST',
        <String, Object?>{
          'appid': 'and02',
          '_t': '$seconds',
          'sign': md5Hex(
            '_t$seconds'
            'appidand02pbKC7zn{4U*ydo2M1Rir$deviceData',
          ),
        },
        deviceData,
        'Gen',
      );
      final deviceid = jsString(
        stringObjectMap(stringObjectMap(device.body)['data'])['deviceid'],
      );
      if (deviceid.isEmpty) {
        throw const _CsccFailure(<String, Object?>{
          'status': 0,
          'msg': 'CSCC 未返回 deviceid',
        });
      }
      final field2 = randomHexBytes(16);
      final encrypted = context.crypto.rsaPkcs1Encrypt(
        '$uuid\t$field2\t${context.nowMilliseconds}\t$deviceid',
        publicKeyPem: liteKugouPublicKey,
      );
      final s = base64Encode(hexDecode(encrypted));
      seconds = context.nowSeconds;
      final gen = await request(
        '/v2/gen',
        'GET',
        <String, Object?>{
          's': s,
          'appid': '3116',
          '_t': '$seconds',
          'sign': md5Hex(
            '_t$seconds'
            'appid3116s$s$_csccAppKey',
          ),
        },
        null,
        'Gen',
      );
      final encoded = jsString(stringObjectMap(gen.body)['data']);
      final decrypted = context.crypto.aesCbcDecryptBytes(
        Uint8List.fromList(base64Decode(encoded)),
        key: Uint8List.fromList(utf8.encode(field2)),
        iv: Uint8List.fromList(utf8.encode(uuid.substring(0, 16))),
      );
      final Object? sessionJson;
      try {
        sessionJson = jsonDecode(utf8.decode(decrypted));
      } on Object {
        throw const _CsccFailure(<String, Object?>{
          'status': 0,
          'msg': 'CSCC 会话响应无效',
        });
      }
      final session = stringObjectMap(sessionJson);
      if (!jsTruthy(session['cookie']) ||
          session['clienttime'] == null ||
          !jsTruthy(session['serverstr'])) {
        throw const _CsccFailure(<String, Object?>{
          'status': 0,
          'msg': 'CSCC 会话响应无效',
        });
      }
      return _CsccSessionData(
        cookie: jsString(session['cookie']),
        clienttime: session['clienttime'],
        serverstr: jsString(session['serverstr']),
        field2: field2,
      );
    }();
    _sessions[cacheKey] = _CsccSession(
      pending: pending,
      expires: now + 30 * 60 * 1000,
    );
  }

  KugouResponse<Object?>? report;
  var playbackAccepted = false;
  try {
    final session = await _sessions[cacheKey]!.pending;
    final fields = event == 'start'
        ? <String>[
            'type_id=20431',
            'action=play',
            'fo3=3878,4320,4326,5747,5749,7229,7289,7863',
            'spt=0',
            'sty=手动',
            'mixsongid=$song',
            'source=46',
            'ivar1=1',
            'fo=/专辑播放页',
          ]
        : <String>[
            'type_id=4',
            'action=play',
            'fo3=3878,4320,4326,5747,5749,7229,7289,7863',
            'duration=$duration',
            'svar3=0',
            'svar2=0',
            'fo=我的音乐/主态/自建歌单/RU',
            'sty=手动',
            'state=$state',
            'mixsongid=$song',
            'source=46',
            'ivar3=0',
            'type=1',
            'fs=1.0',
            'ivar1=1',
          ];
    final nowMs = context.nowMilliseconds;
    fields.addAll(<String>[
      'mid=$mid',
      'uuid=$uuid',
      'ss1=1',
      'ss2=1',
      'sys=$systemVersion',
      'mod=$deviceModel',
      'channelid=18',
      'ip=$localIp',
      'net=1',
      'ver=$_csccVersion',
      'gitversion=7aa8a76',
      'time=$nowMs',
      'userid=$userid',
      'ss3=${md5Hex(generateGuid())}',
    ]);
    final eventBuffer = Uint8List.fromList(utf8.encode(fields.join('&')));
    final line1 = <String>[
      '4',
      '1',
      uuid,
      '0',
      '3116',
      _csccVersion,
      '18',
      systemVersion,
      deviceModel,
      uuid,
      mid,
      '0',
      '000000000000000000000000000000000000',
    ].join('\t');
    final line2 = <String>[
      '${eventBuffer.length}',
      '10048',
      '0',
      '${context.nowSeconds}',
      '1',
      userid,
      '0',
      '0',
    ].join('\t');
    final plain = Uint8List.fromList(<int>[
      ...utf8.encode('$line1\r\n$line2\r\n'),
      ...ZLibEncoder().encode(eventBuffer),
    ]);
    final key = md5Hex(
      '$uuid${session.clienttime}${session.field2}${session.serverstr}',
    );
    final encrypted = context.crypto.aesCbcEncryptBytes(
      Uint8List.fromList(ZLibEncoder().encode(plain)),
      key: Uint8List.fromList(utf8.encode(key)),
      iv: Uint8List.fromList(utf8.encode(uuid.substring(0, 16))),
    );
    final query = <String, Object?>{
      'cookie': session.cookie,
      'length': '${plain.length}',
      'appid': '3116',
      '_t': '${context.nowSeconds}',
    };
    final sorted = (query.keys.toList()..sort())
        .map((key) => '$key${query[key]}')
        .join();
    final sign = crypto.md5.convert(<int>[
      ...utf8.encode('$sorted$_csccAppKey'),
      ...encrypted,
    ]).toString();
    query['sign'] = sign;
    final response = await request(
      '/v2/post',
      'POST',
      query,
      encrypted,
      'Post',
    );
    report = response;
    playbackAccepted = true;
  } on _CsccFailure catch (error) {
    _sessions.remove(cacheKey);
    if (!sync) {
      return rejectEndpoint(context, body: error.body);
    }
  }

  if (!sync) {
    return report ??
        endpointFailure(
          body: const <String, Object?>{
            'status': 0,
            'msg': 'CSCC request failed',
          },
        );
  }
  KugouResponse<Object?>? grade;
  var gradeSynced = false;
  try {
    grade = await userGradeInfo(context, <String, Object?>{
      ...params,
      'uuid': uuid,
      'mid': mid,
      'userid': userid,
      'token': token,
    });
    final body = stringObjectMap(grade.body);
    gradeSynced =
        grade.status == 200 &&
        (body['status'] == null || jsNumber(body['status']) != 0) &&
        jsNumber(jsOr(body['error_code'], jsOr(body['errcode'], 0))) == 0;
  } on Object {
    grade = null;
  }
  final accepted = playbackAccepted || gradeSynced;
  final result = KugouResponse<Object?>(
    status: accepted ? 200 : 502,
    httpStatus: accepted ? 200 : 502,
    body: <String, Object?>{
      'status': accepted ? 1 : 0,
      'data': <String, Object?>{
        'report': report?.body,
        'grade': grade?.body,
        'playback_accepted': playbackAccepted,
        'grade_synced': gradeSynced,
      },
    },
    cookies: <String>[...?report?.cookies, ...?grade?.cookies],
    headers: <String, String>{...?report?.headers, ...?grade?.headers},
  );
  if (!accepted && context.config.throwOnApiError) {
    throw KugouApiException(result);
  }
  return result;
}

bool _validDevice(
  String model,
  String system,
  int width,
  int height,
  String ip,
) {
  if (model.isEmpty ||
      model.length > 128 ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(model) ||
      !RegExp(r'^\d+(?:\.\d+)*$').hasMatch(system) ||
      system.length > 16 ||
      width < 1 ||
      width > 65535 ||
      height < 1 ||
      height > 65535 ||
      ip.isEmpty) {
    return false;
  }
  return _isIp(ip);
}

bool _isIp(String value) {
  if (value.contains(':')) {
    return RegExp(r'^[0-9a-fA-F:]+$').hasMatch(value);
  }
  final parts = value.split('.');
  if (parts.length != 4) return false;
  return parts.every((part) {
    final value = int.tryParse(part);
    return value != null && value >= 0 && value <= 255;
  });
}

bool _validUuid(String value) => RegExp(r'^[a-zA-Z0-9]{32}$').hasMatch(value);

bool _integer(String value) =>
    RegExp(r'^(0|[1-9]\d*)$').hasMatch(value) && int.tryParse(value) != null;
