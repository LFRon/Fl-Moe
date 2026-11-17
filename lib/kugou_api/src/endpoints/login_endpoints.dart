import '../config.dart';
import '../crypto.dart';
import '../endpoint.dart';
import '../models.dart';
import '../signatures.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createLoginEndpointHandlers() =>
    <String, KugouEndpointHandler>{
      '/login': _login,
      '/login/cellphone': _loginCellphone,
      '/login/device/kick': _loginDeviceKick,
      '/login/openplat': _loginOpenPlatform,
      '/login/qr/check': _loginQrCheck,
      '/login/qr/create': _loginQrCreate,
      '/login/token': _loginToken,
      '/login/wx/check': _loginWxCheck,
      '/login/wx/create': _loginWxCreate,
    };

Future<KugouResponse<Object?>> _login(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final now = context.nowMilliseconds;
  final encrypted = context.crypto.aesEncrypt(<String, Object?>{
    'pwd': jsOr(input['password'], ''),
    'code': jsOr(input['code'], ''),
    'clienttime_ms': now,
  });
  final response = await context.request(
    KugouRequest(
      path: '/v9/login_by_pwd',
      method: 'POST',
      data: <String, Object?>{
        'plat': 1,
        'support_multi': 1,
        'clienttime_ms': now,
        't1': _passwordLoginT1,
        't2': _passwordLoginT2,
        't3': 'MCwwLDAsMCwwLDAsMCwwLDA=',
        'dev': endpointCookie(context, input, 'KUGOU_API_DEV'),
        'username': input['username'],
        'params': encrypted.ciphertext,
        'pk': context.crypto.rsaRawEncrypt(<String, Object?>{
          'clienttime_ms': now,
          'key': encrypted.key,
        }).toUpperCase(),
      },
      headers: const <String, Object?>{'x-router': 'login.user.kugou.com'},
    ),
  );
  return _finishLogin(context, response, encrypted.key);
}

Future<KugouResponse<Object?>> _loginCellphone(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final now = context.nowMilliseconds;
  final encrypted = context.crypto.aesEncrypt(<String, Object?>{
    'mobile': jsOr(input['mobile'], ''),
    'code': jsOr(input['code'], ''),
  });
  final mobile = jsTruthy(input['mobile'])
      ? '${_substring(jsString(input['mobile']), 0, 2)}*****'
            '${_substring(jsString(input['mobile']), 10, 11)}'
      : null;
  final t2 = _liteT2(context, input, now);
  final t1 = _liteT1(context, '|$now');
  final data = <String, Object?>{
    'plat': 1,
    'support_multi': 1,
    't1': context.config.isLite ? t1 : 0,
    't2': context.config.isLite ? t2 : 0,
    'clienttime_ms': now,
    'mobile': mobile,
    'key': context.signatures.parametersKey(now),
    'pk': context.crypto.rsaRawEncrypt(<String, Object?>{
      'clienttime_ms': now,
      'key': encrypted.key,
    }).toUpperCase(),
    'params': encrypted.ciphertext,
    if (jsTruthy(input['userid'])) 'userid': input['userid'],
    if (context.config.isLite) ...<String, Object?>{
      'dfid': endpointCookie(context, input, 'dfid') ?? randomString(24),
      'dev': endpointCookie(context, input, 'KUGOU_API_DEV'),
      'gitversion': '5f0b7c4',
    } else
      't3': 'MCwwLDAsMCwwLDAsMCwwLDA=',
  };
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://loginserviceretry.kugou.com'),
      path: '/v7/login_by_verifycode',
      method: 'POST',
      data: data,
      headers: const <String, Object?>{
        'support-calm': '1',
        'User-Agent': 'Android16-1070-11440-130-0-LOGIN-wifi',
      },
    ),
  );
  return _finishLogin(context, response, encrypted.key, alwaysSetCookies: true);
}

Future<KugouResponse<Object?>> _loginToken(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  const standardKey = '90b8382a1bb4ccdcf063102053fd75b8';
  const standardIv = 'f063102053fd75b8';
  const liteKey = 'c24f74ca2820225badc01946dba4fdf7';
  const liteIv = 'adc01946dba4fdf7';
  final now = context.nowMilliseconds;
  final token = input['token'] ?? endpointCookie(context, input, 'token') ?? '';
  final userId =
      input['userid'] ?? endpointCookie(context, input, 'userid') ?? '0';
  final p3 = context.crypto.aesEncrypt(
    <String, Object?>{'clienttime': now ~/ 1000, 'token': token},
    key: context.config.isLite ? liteKey : standardKey,
    iv: context.config.isLite ? liteIv : standardIv,
  );
  final encryptedParameters = context.crypto.aesEncrypt(<String, Object?>{});
  final previousT1 = endpointCookie(context, input, 't1');
  final data = <String, Object?>{
    'dfid': endpointCookie(context, input, 'dfid') ?? '-',
    'p3': p3.ciphertext,
    'plat': 1,
    't1': context.config.isLite
        ? _liteT1(context, '${jsTruthy(previousT1) ? previousT1 : ''}|$now')
        : 0,
    't2': context.config.isLite ? _liteT2(context, input, now) : 0,
    't3': 'MCwwLDAsMCwwLDAsMCwwLDA=',
    'pk': context.crypto.rsaRawEncrypt(<String, Object?>{
      'clienttime_ms': now,
      'key': encryptedParameters.key,
    }),
    'params': encryptedParameters.ciphertext,
    'userid': userId,
    'clienttime_ms': now,
    if (context.config.isLite)
      'dev': endpointCookie(context, input, 'KUGOU_API_DEV'),
  };
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('http://login.user.kugou.com'),
      path: '/v5/login_by_token',
      method: 'POST',
      data: data,
    ),
  );
  return _finishLogin(
    context,
    response,
    encryptedParameters.key,
    alwaysSetCookies: true,
  );
}

Future<KugouResponse<Object?>> _loginDeviceKick(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final rawToken = jsString(
    input['token'] ?? endpointCookie(context, input, 'token') ?? '',
  );
  final encrypted = context.crypto
      .rsaRawEncrypt(
        'moc.uoguk.59::$rawToken',
        publicKeyPem: liteKugouPublicKey,
      )
      .toUpperCase();
  final parameters = <String, Object?>{
    'appid': context.config.appId,
    'clientver': context.config.clientVersion,
    'clienttime': context.nowMilliseconds,
    'mid':
        endpointCookie(context, input, 'KUGOU_API_MID') ?? input['mid'] ?? '',
    'uuid': input['uuid'] ?? endpointCookie(context, input, 'uuid') ?? '-',
    'dfid': input['dfid'] ?? endpointCookie(context, input, 'dfid') ?? '-',
    'plat': 1,
    'userid': jsNumber(
      input['userid'] ?? endpointCookie(context, input, 'userid') ?? '0',
    ).toInt(),
    'token': 'h5$encrypted',
    'srcappid': KugouApiConfig.sourceAppId,
    't_mid': input['t_mid'],
    't': input['t'],
    't_appid': input['t_appid'],
    't_clientver': input['t_clientver'],
  };
  parameters['signature'] = context.signatures.web(parameters);
  return context.request(
    KugouRequest(
      path: '/loginservice/v1/dev_logout',
      parameters: parameters,
      headers: const <String, Object?>{'Host': 'gateway.kugou.com'},
    ),
  );
}

Future<KugouResponse<Object?>> _loginQrCheck(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://login-user.kugou.com'),
      path: '/v2/get_userinfo_qrcode',
      parameters: <String, Object?>{
        'plat': 4,
        'appid': context.config.appId,
        'srcappid': KugouApiConfig.sourceAppId,
        'qrcode': input['key'],
        'dev': endpointCookie(context, input, 'KUGOU_API_DEV'),
      },
      signatureType: KugouSignatureType.web,
    ),
  );
  final body = _map(response.body);
  final data = _map(body['data']);
  if (jsNumber(data['status']) == 4) {
    return _appendCookies(context, response, <String>[
      'token=${jsString(data['token'])}',
      'userid=${jsString(data['userid'])}',
    ]);
  }
  return response;
}

Future<KugouResponse<Object?>> _loginQrCreate(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final url =
      'https://h5.kugou.com/apps/loginQRCode/html/index.html?qrcode='
      '${jsString(input['key'])}';
  return KugouResponse<Object?>(
    status: 200,
    httpStatus: 200,
    body: <String, Object?>{
      'code': 200,
      'data': <String, Object?>{
        'url': url,
        'content': url,
        // Kept only as a compatibility field. Rendering belongs to Flutter UI.
        'base64': '',
      },
    },
  );
}

Future<KugouResponse<Object?>> _loginOpenPlatform(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final tokenResponse = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://api.weixin.qq.com'),
      path: '/sns/oauth2/access_token',
      method: 'POST',
      parameters: <String, Object?>{
        'secret': context.config.isLite
            ? KugouApiConfig.wxLiteSecret
            : KugouApiConfig.wxSecret,
        'appid': context.config.isLite
            ? KugouApiConfig.wxLiteAppId
            : KugouApiConfig.wxAppId,
        'code': jsOr(input['code'], ''),
        'grant_type': 'authorization_code',
      },
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );
  final tokenBody = _map(tokenResponse.body);
  if (!jsTruthy(tokenBody['access_token']) || !jsTruthy(tokenBody['openid'])) {
    return _endpointFailure(context, tokenBody);
  }
  final now = context.nowMilliseconds;
  final encrypted = context.crypto.aesEncrypt(<String, Object?>{
    'access_token': tokenBody['access_token'],
  });
  final response = await context.request(
    KugouRequest(
      path: '/v6/login_by_openplat',
      method: 'POST',
      data: <String, Object?>{
        'dev': endpointCookie(context, input, 'KUGOU_API_DEV'),
        'force_login': 1,
        'partnerid': 36,
        'clienttime_ms': now,
        't1': context.config.isLite ? _liteT1(context, '|$now') : 0,
        't2': context.config.isLite ? _liteT2(context, input, now) : 0,
        't3': 'MCwwLDAsMCwwLDAsMCwwLDA=',
        'openid': tokenBody['openid'],
        'params': encrypted.ciphertext,
        'pk': context.crypto.rsaRawEncrypt(<String, Object?>{
          'clienttime_ms': now,
          'key': encrypted.key,
        }).toUpperCase(),
      },
      headers: const <String, Object?>{'x-router': 'login.user.kugou.com'},
    ),
  );
  return _finishLogin(context, response, encrypted.key, alwaysSetCookies: true);
}

Future<KugouResponse<Object?>> _loginWxCheck(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => context.request(
  KugouRequest(
    baseUri: Uri.parse('https://long.open.weixin.qq.com'),
    path: '/connect/l/qrconnect',
    parameters: <String, Object?>{'f': 'json', 'uuid': jsOr(input['uuid'], '')},
    clearDefaultParameters: true,
    skipSignature: true,
  ),
);

Future<KugouResponse<Object?>> _loginWxCreate(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final appId = context.config.isLite
      ? KugouApiConfig.wxLiteAppId
      : KugouApiConfig.wxAppId;
  final secret = context.config.isLite
      ? KugouApiConfig.wxLiteSecret
      : KugouApiConfig.wxSecret;
  final accessResponse = await _weChatRequest(
    context,
    '/cgi-bin/token',
    <String, Object?>{
      'appid': appId,
      'secret': secret,
      'grant_type': 'client_credential',
    },
  );
  final accessBody = _map(accessResponse.body);
  if (!jsTruthy(accessBody['access_token'])) {
    return _endpointFailure(context, accessBody);
  }
  final ticketResponse = await _weChatRequest(
    context,
    '/cgi-bin/ticket/getticket',
    <String, Object?>{'access_token': accessBody['access_token'], 'type': 2},
  );
  final ticketBody = _map(ticketResponse.body);
  if (ticketBody['errcode'] != 0) return _endpointFailure(context, ticketBody);
  final timestamp = context.nowMilliseconds;
  final nonce = md5Hex(randomString());
  final signature = sha1Hex(
    'appid=$appId&noncestr=$nonce&sdk_ticket=${ticketBody['ticket']}'
    '&timestamp=$timestamp',
  );
  final connectResponse = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://open.weixin.qq.com'),
      path: '/connect/sdk/qrconnect',
      parameters: <String, Object?>{
        'appid': appId,
        'noncestr': nonce,
        'timestamp': timestamp,
        'scope': 'snsapi_userinfo',
        'signature': signature,
      },
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );
  final connectBody = _map(connectResponse.body);
  if (connectBody['errcode'] != 0) {
    return _endpointFailure(context, connectBody);
  }
  final qrCode = _map(connectBody['qrcode']);
  qrCode['qrcodeurl'] =
      'https://open.weixin.qq.com/connect/confirm?uuid=${connectBody['uuid']}';
  connectBody['qrcode'] = qrCode;
  return KugouResponse<Object?>(
    status: 200,
    httpStatus: connectResponse.httpStatus,
    body: connectBody,
    cookies: connectResponse.cookies,
    headers: connectResponse.headers,
  );
}

Future<KugouResponse<Object?>> _weChatRequest(
  KugouEndpointContext context,
  String path,
  Map<String, Object?> parameters,
) => context.request(
  KugouRequest(
    baseUri: Uri.parse('https://api.weixin.qq.com'),
    path: path,
    parameters: parameters,
    clearDefaultParameters: true,
    skipSignature: true,
  ),
);

KugouResponse<Object?> _finishLogin(
  KugouEndpointContext context,
  KugouResponse<Object?> response,
  String temporaryKey, {
  bool alwaysSetCookies = false,
}) {
  final body = _map(response.body);
  if (body['status'] != 1) return response;
  final data = _map(body['data']);
  final secureParameters = data['secu_params'];
  final cookies = <String>[];
  if (secureParameters is String && secureParameters.isNotEmpty) {
    final decrypted = context.crypto.aesDecrypt(secureParameters, temporaryKey);
    if (decrypted is Map<Object?, Object?>) {
      final tokenData = _map(decrypted);
      data.addAll(tokenData);
      for (final entry in tokenData.entries) {
        cookies.add('${entry.key}=${jsString(entry.value)}');
      }
    } else {
      data['token'] = decrypted;
      cookies.add('token=${jsString(decrypted)}');
    }
  }
  if (alwaysSetCookies || secureParameters != null) {
    cookies.addAll(<String>[
      if (alwaysSetCookies) 't1=${jsString(data['t1'])}',
      if (alwaysSetCookies) 'token=${jsString(data['token'])}',
      'userid=${jsString(jsOr(data['userid'], 0))}',
      'vip_type=${jsString(jsOr(data['vip_type'], 0))}',
      'vip_token=${jsString(jsOr(data['vip_token'], ''))}',
    ]);
  }
  body['data'] = data;
  return _appendCookies(
    context,
    KugouResponse<Object?>(
      status: response.status,
      httpStatus: response.httpStatus,
      body: body,
      cookies: response.cookies,
      headers: response.headers,
    ),
    cookies,
  );
}

KugouResponse<Object?> _appendCookies(
  KugouEndpointContext context,
  KugouResponse<Object?> response,
  List<String> cookies,
) {
  context.session.updateCookies(cookies);
  return KugouResponse<Object?>(
    status: response.status,
    httpStatus: response.httpStatus,
    body: response.body,
    cookies: <String>[...response.cookies, ...cookies],
    headers: response.headers,
  );
}

KugouResponse<Object?> _endpointFailure(
  KugouEndpointContext context,
  Object? message,
) {
  final response = KugouResponse<Object?>(
    status: 502,
    httpStatus: 0,
    body: <String, Object?>{'status': 0, 'msg': message},
  );
  if (context.config.throwOnApiError) throw KugouApiException(response);
  return response;
}

Map<String, Object?> _map(Object? value) => stringObjectMap(value);

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
      key: 'fd14b35e3f81af3817a20ae7adae7020',
      iv: '17a20ae7adae7020',
    )
    .ciphertext;

String _liteT1(KugouEndpointContext context, String value) => context.crypto
    .aesEncrypt(
      value,
      key: '5e4ef500e9597fe004bd09a46d8add98',
      iv: '04bd09a46d8add98',
    )
    .ciphertext;

String _substring(String value, int start, int end) {
  if (start >= value.length) return '';
  return value.substring(start, end.clamp(start, value.length));
}

const _passwordLoginT1 =
    '562a6f12a6e803453647d16a08f5f0c2ff7eee692cba2ab74cc4c8ab47fc4675'
    '61a7c6b586ce7dc46a63613b246737c03a1dc8f8d162d8ce1d2c71893d19f1d4'
    'b797685a4c6d3d81341cbde65e488c4829a9b4d42ef2df470eb102979fa5adcdd'
    '9b4eecfea8b909ff7599abeb49867640f10c3c70fc444effca9d15db44a9a6c9'
    '07731e2bb0f22cd9b3536380169995693e5f0e2424e3378097d3813186e3fe96b'
    'be7023808a0981b4e2b6135a76faac';

const _passwordLoginT2 =
    '31c4daf4cf480169ccea1cb7d4a209295865a9d2b788510301694db229b8780746'
    '9ea0d41b4d4b9173c2151da7294aeebfc9738df154bbdf11a4e117bb5dff6a3af'
    '8ce5ce333e681c1f29a44038f27567d58992eb81283e080778ac77db1400fdf49'
    'b7cf7e26be2e5af4da7830cc3be4';
