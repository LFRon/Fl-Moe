import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../config.dart';
import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';
import '../signatures.dart';
import '../utilities.dart';

const String _liteT1Key = '5e4ef500e9597fe004bd09a46d8add98';
const String _liteT1Iv = '04bd09a46d8add98';
const String _liteT2Key = 'fd14b35e3f81af3817a20ae7adae7020';
const String _liteT2Iv = '17a20ae7adae7020';
const String _qqApkSigMd5 = 'fe4a24d80fcf253a00676a808f62c2c6';

Map<String, KugouEndpointHandler> createLoginExtraHandlers() =>
    <String, KugouEndpointHandler>{
      '/login/qq': _loginQq,
      '/login/qq/qr/check': _loginQqQrCheck,
      '/login/qq/qr/create': _loginQqQrCreate,
      '/login/qr/authorize': _loginQrAuthorize,
    };

String _liteT1(KugouEndpointContext context, String value) =>
    context.crypto.aesEncrypt(value, key: _liteT1Key, iv: _liteT1Iv).ciphertext;

String _liteT2(
  KugouEndpointContext context,
  Map<String, Object?> input,
  int timestamp,
) => context.crypto
    .aesEncrypt(
      '${endpointCookie(context, input, 'KUGOU_API_GUID')}|'
      '0f607264fc6318a92b9e13c65db7cd3c|'
      '${endpointCookie(context, input, 'KUGOU_API_MAC')}|'
      '${endpointCookie(context, input, 'KUGOU_API_DEV')}|$timestamp',
      key: _liteT2Key,
      iv: _liteT2Iv,
    )
    .ciphertext;

Future<KugouResponse<Object?>> _loginQq(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final openid = jsString(input['openid']);
  final accessToken = jsString(input['access_token']);
  if (openid.isEmpty || accessToken.isEmpty) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        body: const <String, Object?>{
          'status': 0,
          'msg': '缺少 openid 或 access_token',
        },
      ),
    );
  }
  return _qqOpenPlatformLogin(
    context,
    input,
    openid: openid,
    accessToken: accessToken,
    clientId: context.config.isLite
        ? KugouApiConfig.qqLiteAppId
        : KugouApiConfig.qqAppId,
    partnerId: 1,
  );
}

Future<KugouResponse<Object?>> _qqOpenPlatformLogin(
  KugouEndpointContext context,
  Map<String, Object?> input, {
  required String openid,
  required String accessToken,
  required String clientId,
  required int partnerId,
}) async {
  final normalized = <String, Object?>{
    ...input,
    'cookie': _cookieMap(input['cookie']),
  };
  final now = context.nowMilliseconds;
  final encrypted = context.crypto.aesEncrypt(<String, Object?>{
    'access_token': accessToken,
  });
  final t2 = _liteT2(context, normalized, now);
  final t1 = _liteT1(context, '|$now');
  final data = <String, Object?>{
    'dev': endpointCookie(context, normalized, 'KUGOU_API_DEV'),
    'force_login': 1,
    'partnerid': partnerId,
    'clienttime_ms': now,
    't1': context.config.isLite ? t1 : 0,
    't2': context.config.isLite ? t2 : 0,
    't3': 'MCwwLDAsMCwwLDAsMCwwLDA=',
    'third_appid': clientId,
    'openid': openid,
    'params': encrypted.ciphertext,
    'pk': context.crypto.rsaRawEncrypt(<String, Object?>{
      'clienttime_ms': now,
      'key': encrypted.key,
    }).toUpperCase(),
  };
  final response = await context.request(
    KugouRequest(
      path: '/v6/login_by_openplat',
      method: 'POST',
      data: data,
      cookies: _cookieMap(normalized['cookie']),
      headers: const <String, Object?>{'x-router': 'login.user.kugou.com'},
    ),
  );
  return _finishTokenCookies(context, response, encrypted.key);
}

KugouResponse<Object?> _finishTokenCookies(
  KugouEndpointContext context,
  KugouResponse<Object?> response,
  String temporaryKey,
) {
  final body = Map<String, Object?>.from(stringObjectMap(response.body));
  if (body['status'] != 1) return response;
  final data = stringObjectMap(body['data']);
  final secure = data['secu_params'];
  final cookies = <String>[];
  if (secure is String && secure.isNotEmpty) {
    final decrypted = context.crypto.aesDecrypt(secure, temporaryKey);
    if (decrypted is Map<Object?, Object?>) {
      final tokenData = stringObjectMap(decrypted);
      data.addAll(tokenData);
      for (final entry in tokenData.entries) {
        cookies.add('${entry.key}=${jsString(entry.value)}');
      }
    } else {
      data['token'] = decrypted;
      cookies.add('token=${jsString(decrypted)}');
    }
  }
  cookies.addAll(<String>[
    't1=${jsString(data['t1'] ?? '')}',
    'userid=${jsString(jsOr(data['userid'], 0))}',
    'vip_type=${jsString(jsOr(data['vip_type'], 0))}',
    'vip_token=${jsString(jsOr(data['vip_token'], ''))}',
  ]);
  context.session.updateCookies(cookies);
  body['data'] = data;
  return KugouResponse<Object?>(
    status: response.status,
    httpStatus: response.httpStatus,
    body: body,
    cookies: <String>[...response.cookies, ...cookies],
    headers: response.headers,
  );
}

Future<KugouResponse<Object?>> _loginQrAuthorize(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final qrcode = jsString(input['qrcode']);
  if (qrcode.isEmpty || RegExp(r'^[\w-]+$').hasMatch(qrcode) == false) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        status: 400,
        httpStatus: 400,
        body: const <String, Object?>{
          'status': 0,
          'error_code': 400,
          'msg': '缺少有效的 qrcode 参数',
        },
      ),
    );
  }
  final cookie = <String, String>{
    ...context.session.cookies,
    ...stringStringMap(input['cookie']),
  };
  if (!jsTruthy(cookie['token']) || !jsTruthy(cookie['userid'])) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        status: 400,
        httpStatus: 400,
        body: const <String, Object?>{
          'status': 0,
          'error_code': 400,
          'msg': 'cookie 中缺少已登录账号的 token 或 userid',
        },
      ),
    );
  }
  final requestAppid = jsOr(input['appid'], context.config.appId);
  final data = jsJsonEncode(<String, Object?>{
    'plat': jsNumber(input['plat']) == 2 ? 2 : 1,
    'userid': cookie['userid'],
    'token': cookie['token'],
    'qrcode': qrcode,
    'type': 1,
  });
  Future<KugouResponse<Object?>> call(String path) => context.request(
    KugouRequest(
      baseUri: Uri.parse('https://login-user.kugou.com'),
      path: path,
      method: 'POST',
      parameters: <String, Object?>{
        'appid': requestAppid,
        'srcappid': KugouApiConfig.sourceAppId,
        'clientver': context.config.clientVersion,
      },
      data: data,
      headers: const <String, Object?>{'Content-Type': 'application/json'},
      cookies: cookie,
      signatureType: KugouSignatureType.web,
    ),
  );
  final scan = await call('/v2/scan');
  final scanBody = stringObjectMap(scan.body);
  final scanData = stringObjectMap(scanBody['data']);
  if (scanBody['status'] != 1 ||
      jsString(scanData['userid']) != jsString(cookie['userid'])) {
    return KugouResponse<Object?>(
      status: scan.status,
      httpStatus: scan.httpStatus,
      body: <String, Object?>{
        ...scanBody,
        'data': <String, Object?>{
          ...scanData,
          'qrcode': qrcode,
          'appid': requestAppid,
          'authorized': false,
        },
      },
      cookies: scan.cookies,
      headers: scan.headers,
    );
  }
  final authorized = await call('/v2/authorize');
  final authBody = stringObjectMap(authorized.body);
  final authData = stringObjectMap(authBody['data']);
  return KugouResponse<Object?>(
    status: authorized.status,
    httpStatus: authorized.httpStatus,
    body: <String, Object?>{
      ...authBody,
      'data': <String, Object?>{
        ...authData,
        'qrcode': qrcode,
        'appid': requestAppid,
        'authorized':
            authBody['status'] == 1 &&
            jsString(authData['userid']) == jsString(cookie['userid']),
      },
    },
    cookies: authorized.cookies,
    headers: authorized.headers,
  );
}

Future<KugouResponse<Object?>> _loginQqQrCreate(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final clientId = context.config.isLite
      ? KugouApiConfig.qqLiteAppId
      : KugouApiConfig.qqAppId;
  final time = context.nowSeconds;
  final sign = md5Hex('${_qqApkSigMd5}_$time');
  final authParams = <String, String>{
    'cancel_display': '1',
    'sdkp': 'a',
    'display': 'mobile',
    'format': 'json',
    'sign': sign,
    'sdkv': '3.5.11.lite',
    'response_type': 'token',
    'status_os': '11',
    'client_id': clientId,
    'switch': '1',
    'status_version': '30',
    'show_download_ui': 'true',
    'pf': 'openmobile_android',
    'scope': 'all',
    'compat_v': '1',
    'status_machine': 'MEIZU+18+Pro',
    'style': 'qr',
    'time': '$time',
    'redirect_uri': 'auth://tauth.qq.com/',
  };
  final authQuery = Uri(queryParameters: authParams).query;
  final auth = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://openmobile.qq.com'),
      path: '/oauth2.0/m_authorize?$authQuery',
      method: 'GET',
      headers: const <String, Object?>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Referer': 'https://xui.ptlogin2.qq.com/',
      },
      clearDefaultParameters: true,
      clearDefaultHeaders: true,
      skipSignature: true,
    ),
  );
  final authText = jsString(auth.body);
  final srcMatch = RegExp(r'src = "([^"]+)"').firstMatch(authText);
  if (srcMatch == null) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        body: <String, Object?>{
          'status': 0,
          'msg': 'm_authorize 响应异常，未找到 xlogin 地址',
          'data': authText.length > 300 ? authText.substring(0, 300) : authText,
        },
      ),
    );
  }
  final xloginUrl = srcMatch
      .group(1)!
      .replaceAllMapped(
        RegExp(r'\\x([0-9A-Fa-f]{2})'),
        (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
      );
  final xloginQuery = xloginUrl.contains('?') ? xloginUrl.split('?')[1] : '';
  final ptOpenLoginData = Uri.encodeComponent(xloginQuery);
  final cookieJar = <String, String>{};
  final xlogin = await context.request(
    _rawUrlRequest(
      xloginUrl,
      headers: const <String, Object?>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Referer': 'https://xui.ptlogin2.qq.com/',
      },
    ),
  );
  _mergeCookies(cookieJar, xlogin.cookies);
  final ptLoginSig = cookieJar['pt_login_sig'] ?? '';
  final t = Random.secure().nextDouble();
  final qr = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://xui.ptlogin2.qq.com'),
      path:
          '/ssl/ptqrshow?s=8&e=0&appid=716027609&type=0&t=$t&daid=381&pt_3rd_aid=$clientId',
      method: 'GET',
      headers: <String, Object?>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Referer': xloginUrl,
        'Cookie': _cookieString(cookieJar),
      },
      clearDefaultParameters: true,
      clearDefaultHeaders: true,
      skipSignature: true,
      responseType: KugouResponseType.bytes,
    ),
  );
  _mergeCookies(cookieJar, qr.cookies);
  final qrsig = cookieJar['qrsig'] ?? '';
  if (qrsig.isEmpty) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        body: const <String, Object?>{'status': 0, 'msg': '未获取到 qrsig'},
      ),
    );
  }
  final bytes = qr.body is Uint8List
      ? qr.body! as Uint8List
      : qr.body is List<int>
      ? Uint8List.fromList(qr.body! as List<int>)
      : Uint8List(0);
  return Future<KugouResponse<Object?>>.value(
    KugouResponse<Object?>(
      status: 200,
      httpStatus: 200,
      body: <String, Object?>{
        'qrcode': base64Encode(bytes),
        'qrsig': qrsig,
        'ptqrtoken': _hash33(qrsig),
        'pt_login_sig': ptLoginSig,
        'pt_openlogin_data': ptOpenLoginData,
        'xlogin_url': xloginUrl,
        'cookie': _cookieString(cookieJar),
      },
    ),
  );
}

Future<KugouResponse<Object?>> _loginQqQrCheck(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final qrsig = jsString(input['qrsig']);
  final ptqrtoken = jsString(input['ptqrtoken']);
  final ptLoginSig = jsString(input['pt_login_sig']);
  final ptOpenLoginData = jsString(input['pt_openlogin_data']);
  final xloginUrl = jsString(input['xlogin_url']);
  var cookie = jsString(input['cookie']);
  if (ptLoginSig.isNotEmpty && !cookie.contains('pt_login_sig')) {
    cookie = '${cookie.isEmpty ? '' : '$cookie; '}pt_login_sig=$ptLoginSig';
  }
  final missing = <String>[];
  if (qrsig.isEmpty) missing.add('qrsig');
  if (ptqrtoken.isEmpty) missing.add('ptqrtoken');
  if (ptLoginSig.isEmpty) missing.add('pt_login_sig');
  if (ptOpenLoginData.isEmpty) missing.add('pt_openlogin_data');
  if (xloginUrl.isEmpty) missing.add('xlogin_url');
  if (!cookie.contains('qrsig=')) missing.add('cookie');
  if (missing.isNotEmpty) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        body: <String, Object?>{
          'status': 0,
          'msg':
              '缺少 ${missing.join('、')}（请先调用 /login/qq/qr/create，并将返回字段原样传入 check 接口）',
        },
      ),
    );
  }
  final clientId = context.config.isLite
      ? KugouApiConfig.qqLiteAppId
      : KugouApiConfig.qqAppId;
  final u1 = Uri.encodeComponent('http://connect.qq.com');
  final pollUrl =
      'https://xui.ptlogin2.qq.com/ssl/ptqrlogin?u1=$u1&from_ui=1&type=1'
      '&ptlang=2052&ptqrtoken=$ptqrtoken&daid=381&aid=716027609'
      '&pt_3rd_aid=$clientId&pt_openlogin_data=$ptOpenLoginData'
      '&device=2&ptopt=1&pt_uistyle=35&jsver=v1.36.0'
      '&login_sig=${Uri.encodeComponent(ptLoginSig)}&r=${Random.secure().nextDouble()}';
  final poll = await context.request(
    _rawUrlRequest(
      pollUrl,
      headers: <String, Object?>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Referer': xloginUrl.isEmpty
            ? 'https://xui.ptlogin2.qq.com/'
            : xloginUrl,
        'Cookie': cookie,
      },
    ),
  );
  final cookieJar = <String, String>{};
  _mergeCookies(cookieJar, poll.cookies);
  cookie = _mergeCookieString(cookie, cookieJar);
  final body = jsString(poll.body);
  final match = RegExp(r'ptuiCB\((.+)\)').firstMatch(body);
  if (match == null) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        body: <String, Object?>{
          'status': 0,
          'msg': 'ptqrlogin 响应解析失败',
          'data': body.length > 200 ? body.substring(0, 200) : body,
        },
      ),
    );
  }
  final parts = RegExp(r"'([^']*)'")
      .allMatches(match.group(1)!)
      .map((match) => match.group(1) ?? '')
      .toList(growable: false);
  final code = parts.isNotEmpty ? parts[0] : '';
  final url = parts.length > 2 ? parts[2] : '';
  final msg = parts.length > 4 ? parts[4] : '';
  if (code == '66') {
    return Future<KugouResponse<Object?>>.value(
      KugouResponse<Object?>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'status': 'wait',
          'qrsig': qrsig,
          'ptqrtoken': ptqrtoken,
          'msg': '等待扫码',
        },
      ),
    );
  }
  if (code == '65') {
    return Future<KugouResponse<Object?>>.value(
      KugouResponse<Object?>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'status': 'expired',
          'qrsig': qrsig,
          'ptqrtoken': ptqrtoken,
          'msg': '二维码已失效，请重新生成',
        },
      ),
    );
  }
  if (code != '0') {
    return Future<KugouResponse<Object?>>.value(
      KugouResponse<Object?>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'status': code,
          'qrsig': qrsig,
          'ptqrtoken': ptqrtoken,
          'msg': msg,
        },
      ),
    );
  }
  var openid = RegExp(r'openid=([^&#]+)').firstMatch(url)?.group(1) ?? '';
  var accessToken =
      RegExp(r'access_token=([^&#]+)').firstMatch(url)?.group(1) ?? '';
  if (openid.isEmpty || accessToken.isEmpty) {
    var sigUrl = url.startsWith('http') ? url : 'https://$url';
    var sigCookie = cookie;
    for (var hop = 0; hop < 10; hop += 1) {
      final sig = await context.request(
        _rawUrlRequest(
          sigUrl,
          headers: <String, Object?>{
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            'Referer': xloginUrl.isEmpty
                ? 'https://xui.ptlogin2.qq.com/'
                : xloginUrl,
            'Cookie': sigCookie,
          },
        ),
      );
      _mergeCookies(cookieJar, sig.cookies);
      sigCookie = _mergeCookieString(sigCookie, cookieJar);
      final location = sig.headers['location'] ?? '';
      openid =
          RegExp(r'openid=([^&#]+)').firstMatch(sigUrl)?.group(1) ?? openid;
      accessToken =
          RegExp(r'access_token=([^&#]+)').firstMatch(sigUrl)?.group(1) ??
          accessToken;
      if (openid.isNotEmpty && accessToken.isNotEmpty) break;
      if (location.isEmpty) {
        final text = jsString(sig.body);
        openid =
            RegExp(
              r'''openid["']?[:=]["']?([^&"'\s]+)''',
            ).firstMatch(text)?.group(1) ??
            openid;
        accessToken =
            RegExp(
              r'''access_token["']?[:=]["']?([^&"'\s]+)''',
            ).firstMatch(text)?.group(1) ??
            accessToken;
        break;
      }
      sigUrl = Uri.parse(sigUrl).resolve(location).toString();
    }
  }
  if (openid.isEmpty || accessToken.isEmpty) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        body: <String, Object?>{
          'status': 0,
          'msg': '登录成功但未获取到 openid/access_token',
          'url': url,
        },
      ),
    );
  }
  return _qqOpenPlatformLogin(
    context,
    <String, Object?>{...input, 'cookie': _cookieString(cookieJar)},
    openid: openid,
    accessToken: accessToken,
    clientId: clientId,
    partnerId: 1,
  );
}

KugouRequest _rawUrlRequest(
  String url, {
  required Map<String, Object?> headers,
}) {
  final uri = Uri.parse(url);
  return KugouRequest(
    baseUri: Uri.parse('${uri.scheme}://${uri.authority}'),
    path: '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}',
    method: 'GET',
    headers: headers,
    clearDefaultParameters: true,
    clearDefaultHeaders: true,
    skipSignature: true,
    responseType: KugouResponseType.text,
  );
}

Map<String, String> _cookieMap(Object? value) {
  if (value is String) {
    final result = <String, String>{};
    for (final part in value.split(';')) {
      final index = part.indexOf('=');
      if (index <= 0) continue;
      result[part.substring(0, index).trim()] = part
          .substring(index + 1)
          .trim();
    }
    return result;
  }
  return stringStringMap(value);
}

void _mergeCookies(Map<String, String> jar, Iterable<String> cookies) {
  for (final raw in cookies) {
    final pair = raw.split(';').first;
    final index = pair.indexOf('=');
    if (index <= 0) continue;
    jar[pair.substring(0, index)] = pair.substring(index + 1);
  }
}

String _cookieString(Map<String, String> jar) =>
    jar.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');

String _mergeCookieString(String current, Map<String, String> jar) {
  final values = <String, String>{};
  for (final part in current.split(';')) {
    final index = part.indexOf('=');
    if (index > 0) {
      values[part.substring(0, index).trim()] = part
          .substring(index + 1)
          .trim();
    }
  }
  values.addAll(jar);
  return values.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join('; ');
}

int _hash33(String input) {
  var e = 0;
  for (final code in input.codeUnits) {
    e = (e + ((e << 5) & 0xffffffff) + code) & 0xffffffff;
  }
  return 2147483647 & e;
}
