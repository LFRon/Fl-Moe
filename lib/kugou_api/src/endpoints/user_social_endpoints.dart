import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../crypto.dart';
import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createUserSocialHandlers() =>
    <String, KugouEndpointHandler>{
      '/blacklist': _blacklist,
      '/blacklist/list': _blacklistList,
      '/user/batch/union/vipinfo': _userBatchUnionVipInfo,
      '/user/follow/add': _userFollowAdd,
      '/user/follow/chat': _userFollowChat,
      '/user/follow/del': _userFollowDel,
      '/user/follow/message': _userFollowMessage,
      '/user/preference': _userPreference,
      '/user/preference/update': _userPreferenceUpdate,
      '/user/update': _userUpdate,
      '/user/update/avatar': _userUpdateAvatar,
      '/user/verify': _userVerify,
      '/user/visitors': _userVisitors,
    };

const Map<String, int> _blacklistSource = <String, int>{'song': 3, 'singer': 4};

String _label(Map<String, Object?> input) =>
    input['label'] == 'singer' ? 'singer' : 'song';

int _liteAppId(KugouEndpointContext context) =>
    context.config.isLite ? 3116 : 1005;
int _liteClientVer(KugouEndpointContext context) =>
    context.config.isLite ? 11440 : 20489;

Future<KugouResponse<Object?>> _blacklist(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final token = jsString(
    jsOr(input['token'], endpointCookie(context, input, 'token')),
  );
  final userid = jsNumber(
    jsOr(input['userid'], endpointCookie(context, input, 'userid')),
  ).toInt();
  final clienttime = context.nowSeconds;
  final label = _label(input);
  final timestamp = '$clienttime';
  var items = input['items'];
  if (items is String) {
    try {
      items = jsonDecode(items);
    } on FormatException {
      items = null;
    }
  }
  if (items is! List<Object?> || items.isEmpty) {
    if (label == 'song') {
      items = <Object?>[
        <String, Object?>{
          'k': jsString(input['hash']).toLowerCase(),
          'v': jsJsonEncode(<String, Object?>{
            'n': jsOr(input['name'], ''),
            'm': jsString(input['mixsongid']),
            't': timestamp,
          }),
        },
      ];
    } else {
      items = <Object?>[
        <String, Object?>{
          'k': jsString(input['singerid']),
          'v': jsJsonEncode(<String, Object?>{
            'n': jsOr(input['name'], ''),
            't': timestamp,
          }),
        },
      ];
    }
  }
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://relationuser.kugou.com'),
      path: '/v1/edit_list_items',
      method: 'POST',
      data: <String, Object?>{
        'userid': userid,
        'source': jsNumber(
          jsOr(input['source'], _blacklistSource[label]),
        ).toInt(),
        'label': label,
        'items': items,
        'action': jsTruthy(input['isDelete']) ? 'delete' : 'add',
        'p': context.crypto
            .rsaRawEncrypt(
              jsJsonEncode(<String, Object?>{
                'clienttime': clienttime,
                'token': token,
              }),
            )
            .toUpperCase(),
      },
      headers: <String, Object?>{
        'KG-TID': jsString(jsOr(input['moduleId'], 473)),
      },
    ),
  );
}

Future<KugouResponse<Object?>> _blacklistList(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final token = jsString(
    jsOr(input['token'], endpointCookie(context, input, 'token')),
  );
  final userid = jsNumber(
    jsOr(input['userid'], endpointCookie(context, input, 'userid')),
  ).toInt();
  final clienttime = context.nowSeconds;
  final label = _label(input);
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://relationuser.kugou.com'),
      path: '/v2/get_list_items',
      method: 'POST',
      data: <String, Object?>{
        'userid': userid,
        'source': jsNumber(
          jsOr(input['source'], _blacklistSource[label]),
        ).toInt(),
        'label': label,
        'p': context.crypto
            .rsaRawEncrypt(
              jsJsonEncode(<String, Object?>{
                'clienttime': clienttime,
                'token': token,
              }),
            )
            .toUpperCase(),
        'page': jsNumber(jsOr(input['page'], 1)).toInt(),
        'pagesize': min(jsNumber(jsOr(input['pagesize'], 30)).toInt(), 500),
      },
      headers: <String, Object?>{
        'KG-TID': jsString(jsOr(input['moduleId'], 473)),
      },
    ),
  );
}

Map<String, Object?> _followCommon(
  KugouEndpointContext context,
  Map<String, Object?> input,
  int tuid,
) {
  final token = jsString(
    jsOr(input['token'], endpointCookie(context, input, 'token')),
  );
  final userid = jsNumber(
    jsOr(input['userid'], endpointCookie(context, input, 'userid')),
  ).toInt();
  final mid = jsString(
    jsOr(
      input['mid'],
      jsOr(endpointCookie(context, input, 'KUGOU_API_MID'), ''),
    ),
  );
  final dfid = jsString(
    jsOr(input['dfid'], jsOr(endpointCookie(context, input, 'dfid'), '-')),
  );
  final clienttime = context.nowSeconds;
  return <String, Object?>{
    'userid': userid,
    'source': jsNumber(jsOr(input['source'], 0)).toInt(),
    'clienttime': clienttime,
    'mid': mid,
    'key': context.signatures.parametersKey(
      '$clienttime',
      _liteAppId(context),
      _liteClientVer(context),
    ),
    'dfid': dfid,
    'clientver': _liteClientVer(context),
    'appid': _liteAppId(context),
    'p': context.crypto.rsaRawEncrypt(<String, Object?>{
      'clienttime': clienttime,
      'token': token,
      't_userid': tuid,
    }).toUpperCase(),
  };
}

Future<KugouResponse<Object?>> _userFollowAdd(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final tuid = jsNumber(
    jsOr(input['tuid'], jsOr(input['t_userid'], 0)),
  ).toInt();
  if (tuid == 0) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        body: const <String, Object?>{
          'status': 0,
          'error_code': -1,
          'error': '缺少目标用户 tuid',
        },
      ),
    );
  }
  final data = _followCommon(context, input, tuid);
  final userid = data['userid'];
  return context.request(
    KugouRequest(
      path: '/v2/follow',
      method: 'POST',
      parameters: <String, Object?>{'dfid': data['dfid']},
      data: data,
      clearDefaultParameters: true,
      skipSignature: true,
      headers: <String, Object?>{
        'x-router': 'relation.user.kugou.com',
        'User-Agent':
            'Android15-AndroidPhone-${_liteClientVer(context)}-201-0-User-wifi',
        'Content-Type': 'text/plain; charset=ISO-8859-1',
        'KG-FAKE': jsString(userid),
        'KG-FAKE-TYPE': '0,0',
        'KG-FAKE-SUBTYPE': '0,0',
        'KG-RFB': '0',
      },
    ),
  );
}

Future<KugouResponse<Object?>> _userFollowDel(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final tuid = jsNumber(
    jsOr(input['tuid'], jsOr(input['t_userid'], 0)),
  ).toInt();
  if (tuid == 0) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        body: const <String, Object?>{
          'status': 0,
          'error_code': -1,
          'error': '缺少目标用户 tuid',
        },
      ),
    );
  }
  final data = _followCommon(context, input, tuid);
  final userid = data['userid'];
  return context.request(
    KugouRequest(
      path: '/v1/unfollow',
      method: 'POST',
      parameters: <String, Object?>{'dfid': data['dfid']},
      data: data,
      clearDefaultParameters: true,
      skipSignature: true,
      headers: <String, Object?>{
        'x-router': 'relationuser.kugou.com',
        'User-Agent':
            'Android15-AndroidPhone-${_liteClientVer(context)}-201-0-User-wifi',
        'Content-Type': 'text/plain; charset=ISO-8859-1',
        'KG-FAKE': jsString(userid),
        'KG-FAKE-TYPE': '0,0',
        'KG-FAKE-SUBTYPE': '0,0',
        'KG-RFB': '0',
      },
    ),
  );
}

Future<KugouResponse<Object?>> _userFollowMessage(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final userid = jsString(
    jsOr(input['userid'], jsOr(endpointCookie(context, input, 'userid'), '0')),
  );
  final tag = jsString(
    jsOr(input['tag'], 'chat:${jsString(input['id'])}_$userid'),
  );
  if (tag == 'chat:undefined_0') {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        body: const <String, Object?>{
          'status': 0,
          'errcode': -1,
          'error': '需要提供 tag（如 mchat:1270119904）或对方 id',
        },
      ),
    );
  }
  return context.request(
    KugouRequest(
      path: '/msg.mobile/v3/msgtag/history',
      method: 'GET',
      parameters: <String, Object?>{
        'filter': 1,
        'maxid': input['maxid'] ?? 0,
        'pagesize': input['pagesize'] ?? 30,
        'tag': tag,
      },
    ),
  );
}

Future<KugouResponse<Object?>> _userFollowChat(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final tag = jsString(input['tag']);
  final tuid = jsNumber(input['tuid']).toInt();
  if (tag.isEmpty && tuid == 0) {
    return rejectEndpoint(
      context,
      body: const <String, Object?>{
        'status': 0,
        'errcode': -1,
        'error': 'tuid 与 tag 至少需要传一个',
      },
    );
  }
  final token = jsString(
    jsOr(input['token'], endpointCookie(context, input, 'token')),
  );
  final userid = jsString(
    jsOr(input['userid'], jsOr(endpointCookie(context, input, 'userid'), 0)),
  );
  final mid = jsString(
    jsOr(
      input['mid'],
      jsOr(endpointCookie(context, input, 'KUGOU_API_MID'), ''),
    ),
  );
  final dfid = jsString(
    jsOr(input['dfid'], jsOr(endpointCookie(context, input, 'dfid'), '-')),
  );
  final uuid = jsString(jsOr(input['uuid'], '-'));
  final msgtype = jsNumber(jsOr(input['msgtype'], 201)).toInt();
  final message = <String, Object?>{
    'msgtype': msgtype,
    'alert': jsOr(input['alert'], ''),
    'nickname': jsOr(input['nickname'], ''),
    'source': jsNumber(jsOr(input['source'], 0)).toInt(),
    'follow_source': jsNumber(jsOr(input['follow_source'], 0)).toInt(),
    'nt': jsOr(input['nt'], ''),
  };
  if (jsTruthy(input['location'])) message['location'] = input['location'];
  if (jsTruthy(input['groupid'])) {
    message['groupid'] = jsNumber(input['groupid']).toInt();
  }
  if (msgtype == 202) {
    message['alert'] = jsTruthy(message['alert']) ? message['alert'] : '[图片]';
    var url = jsString(input['url']);
    if (url.isEmpty) {
      final image = _imageBytes(input);
      if (image == null) {
        return rejectEndpoint(
          context,
          body: const <String, Object?>{
            'status': 0,
            'errcode': -1,
            'error':
                '图片消息需要提供 url，或通过二进制请求体/octet-stream、imgFile(base64/dataURL) 传入图片',
          },
        );
      }
      try {
        url = await _uploadChatImage(
          context,
          image,
          userid: userid,
          token: token,
          mid: mid,
          dfid: dfid,
          uuid: uuid,
          isOriginal: jsTruthy(jsOr(input['is_original'], input['isOriginal'])),
          extendname: jsString(jsOr(input['extendname'], 'jpg')),
        );
      } on Object catch (error) {
        return rejectEndpoint(
          context,
          body: <String, Object?>{
            'status': 0,
            'errcode': -1,
            'error': error.toString(),
          },
        );
      }
    }
    message['url'] = url;
    if (jsTruthy(input['width'])) {
      message['width'] = jsNumber(input['width']).toInt();
    }
    if (jsTruthy(input['height'])) {
      message['height'] = jsNumber(input['height']).toInt();
    }
    message['isOriginal'] = jsTruthy(
      jsOr(input['is_original'], input['isOriginal']),
    );
    if (jsTruthy(message['isOriginal']) &&
        jsTruthy(jsOr(input['original_size'], input['originalSize']))) {
      message['originalSize'] = jsNumber(
        jsOr(input['original_size'], input['originalSize']),
      ).toInt();
    }
  } else if (msgtype == 205) {
    message['alert'] = jsTruthy(message['alert']) ? message['alert'] : '[表情]';
    if (!jsTruthy(input['url']) || !jsTruthy(input['thumbUrl'])) {
      return rejectEndpoint(
        context,
        body: const <String, Object?>{
          'status': 0,
          'errcode': -1,
          'error': '表情消息需要提供 url 与 thumbUrl',
        },
      );
    }
    message['url'] = jsString(input['url']);
    message['thumbUrl'] = jsString(input['thumbUrl']);
  } else if (msgtype == 201) {
    if (!jsTruthy(message['alert'])) {
      return rejectEndpoint(
        context,
        body: const <String, Object?>{
          'status': 0,
          'errcode': -1,
          'error': '文本消息缺少 alert 内容',
        },
      );
    }
  } else {
    if (jsTruthy(input['url'])) {
      message['url'] = jsString(input['url']);
    }
    if (jsTruthy(input['thumbUrl'])) {
      message['thumbUrl'] = jsString(input['thumbUrl']);
    }
    if (jsTruthy(input['timelen'])) {
      message['timelen'] = jsNumber(input['timelen']).toInt();
    }
    if (!jsTruthy(message['alert']) && !jsTruthy(message['url'])) {
      return rejectEndpoint(
        context,
        body: <String, Object?>{
          'status': 0,
          'errcode': -1,
          'error': 'msgtype=$msgtype 需要提供 alert 或 url',
        },
      );
    }
  }
  if (jsTruthy(input['fakeid'])) message['fakeid'] = jsString(input['fakeid']);
  final body = <String, Object?>{};
  if (tag.isNotEmpty) {
    body['tag'] = tag;
  } else {
    body['tuid'] = tuid;
  }
  final sourcePath = jsString(jsOr(input['source_path'], input['ingress']));
  if (sourcePath.isNotEmpty) body['ingress'] = sourcePath;
  if (jsTruthy(input['retry'])) body['retry'] = 1;
  body['message'] = message;
  final data = jsJsonEncode(body).replaceAll('/', r'\/');
  return context.request(
    KugouRequest(
      path: '/v1/chat/send',
      method: 'POST',
      data: data,
      headers: <String, Object?>{
        'x-router': 'msg.mobile.kugou.com',
        'User-Agent':
            'Android15-AndroidPhone-${_liteClientVer(context)}-201-0-ChatSend-wifi',
        'Content-Type': 'text/plain; charset=UTF-8',
      },
    ),
  );
}

Uint8List? _imageBytes(Map<String, Object?> input) {
  final data = input['data'];
  if (data is Uint8List) return data;
  if (data is List<int>) return Uint8List.fromList(data);
  final raw = input['imgFile'];
  if (raw is! String || raw.isEmpty) return null;
  final base64Text =
      (raw.startsWith('data:') ? raw.substring(raw.indexOf(',') + 1) : raw)
          .replaceAll(RegExp(r'\s'), '');
  if (base64Text.isEmpty ||
      base64Text.length % 4 != 0 ||
      !RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(base64Text)) {
    return null;
  }
  return Uint8List.fromList(base64Decode(base64Text));
}

Future<String> _uploadChatImage(
  KugouEndpointContext context,
  Uint8List image, {
  required String userid,
  required String token,
  required String mid,
  required String dfid,
  required String uuid,
  required bool isOriginal,
  required String extendname,
}) async {
  final appId = _liteAppId(context);
  final clientVer = _liteClientVer(context);
  Map<String, Object?> sign(Map<String, Object?> params) {
    final signed = <String, Object?>{...params};
    signed.remove('signature');
    signed['signature'] = context.signatures.android(signed);
    return signed;
  }

  final authResponse = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://encounter.kugou.com'),
      path: '/v1/upload/auth',
      method: 'GET',
      parameters: sign(<String, Object?>{
        'bucket': 'imagemsg',
        'filename': '',
        'method': 'POST',
        'loginType': token.isNotEmpty ? 1 : 0,
        'buVerifyCode': md5Hex('${appId}imagemsgb8a37aa141c842f9'),
        'extranet': 1,
        'userid': userid,
        'token': token,
        'version': clientVer,
        'dfid': dfid,
        'mid': mid,
        'uuid': uuid,
        'appid': appId,
        'clientver': clientVer,
        'clienttime': context.nowSeconds,
      }),
      headers: const <String, Object?>{
        'x-router': 'bsstrackercdngz.kugou.com',
        'Host': 'gateway.kugou.com',
      },
      clearDefaultParameters: true,
      clearDefaultHeaders: true,
      skipSignature: true,
    ),
  );
  final authData = stringObjectMap(stringObjectMap(authResponse.body)['data']);
  final authorization = jsString(authData['authorization']);
  if (authorization.isEmpty) {
    throw StateError('获取上传授权失败: ${jsJsonEncode(authResponse.body)}');
  }
  final uploadResponse = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://bssul.service.kugou.com'),
      path: '/v3/upload',
      method: 'POST',
      parameters: sign(<String, Object?>{
        'bucket': 'imagemsg',
        'authorization': authorization,
        'extendname': extendname.replaceFirst(RegExp(r'^\.'), ''),
        'userid': userid,
        'token': token,
        'dfid': dfid,
        'mid': mid,
        'appid': appId,
        'clientver': clientVer,
        'body_empty': 1,
      }),
      data: image,
      headers: <String, Object?>{
        'Authorization': authorization,
        'Content-Type': 'application/octet-stream',
        'User-Agent':
            'Android15-AndroidPhone-$clientVer-201-0-UploadImageChatMsg-wifi',
      },
      clearDefaultParameters: true,
      clearDefaultHeaders: true,
      skipSignature: true,
    ),
  );
  final uploadBody = stringObjectMap(uploadResponse.body);
  final uploadData = stringObjectMap(uploadBody['data']);
  final bssFilename = jsString(uploadData['x-bss-filename']);
  if (uploadBody['status'] != 1 || bssFilename.isEmpty) {
    throw StateError('图片上传失败: ${jsJsonEncode(uploadResponse.body)}');
  }
  final host = isOriginal ? 'bssdlbig.kugou.com' : 'bssdl.kugou.com';
  return 'http://${jsString(uploadData['x-bss-bucket'])}.$host/$bssFilename';
}

Future<KugouResponse<Object?>> _userBatchUnionVipInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final ids = _toUserIds(
    firstValue(<Object?>[
      input['useridlist'],
      input['userids'],
      input['userid_list'],
    ]),
  );
  if (ids.isEmpty) {
    return Future<KugouResponse<Object?>>.value(
      const KugouResponse<Object?>(
        status: 200,
        httpStatus: 200,
        body: <String, Object?>{
          'status': 1,
          'error_code': 0,
          'data': <String, Object?>{'busi_vip': <String, Object?>{}},
        },
      ),
    );
  }
  final kugouid = jsNumber(
    firstValue(<Object?>[
      input['kugouid'],
      input['userid'],
      endpointCookie(context, input, 'userid'),
      0,
    ]),
  ).toInt();
  final token = jsString(
    firstValue(<Object?>[
      input['clienttoken'],
      input['token'],
      endpointCookie(context, input, 'token'),
    ]),
  );
  final data = <String, Object?>{
    'get_type': jsString(firstValue(<Object?>[input['get_type'], '2'])),
    'busi_type': jsString(firstValue(<Object?>[input['busi_type'], 'concept'])),
    'useridlist': ids,
    'clientappid': jsString(
      firstValue(<Object?>[
        input['clientappid'],
        endpointCookie(context, input, 'appid'),
        '',
      ]),
    ),
  };
  if (kugouid > 0) data['kugouid'] = '$kugouid';
  if (token.isNotEmpty) data['clienttoken'] = token;
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://kugouvip.kugou.com'),
      path: '/v2/batch_union_vipinfo',
      method: 'POST',
      data: data,
      headers: const <String, Object?>{
        'Content-Type': 'application/json; charset=utf-8',
      },
    ),
  );
}

List<int> _toUserIds(Object? value) {
  final raw = value is Iterable<Object?>
      ? value
      : value is String
      ? value.split(RegExp(r'[,\s]+'))
      : value == null
      ? const <Object?>[]
      : <Object?>[value];
  final ids = <int>[];
  final seen = <String>{};
  for (final item in raw) {
    final id = jsNumber(item);
    if (!id.isFinite || id <= 0) continue;
    final key = '${id.toInt()}';
    if (!seen.add(key)) continue;
    ids.add(id.toInt());
    if (ids.length >= 20) break;
  }
  return ids;
}

Future<KugouResponse<Object?>> _userVerify(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('http://gateway.kugou.com'),
      path: '/v1/user_verify',
      method: 'GET',
      parameters: const <String, Object?>{'module_id': 51},
      headers: const <String, Object?>{'x-router': 'trackercdngz.kugou.com'},
      cookies: stringStringMap(input['cookie']),
    ),
  );
  final body = stringObjectMap(response.body);
  final data = stringObjectMap(body['data']);
  if (body['status'] == 1 && jsTruthy(data['auth'])) {
    final cookie = 'auth=${jsString(data['auth'])}';
    context.session.updateCookies(<String>[cookie]);
    return KugouResponse<Object?>(
      status: response.status,
      httpStatus: response.httpStatus,
      body: response.body,
      cookies: <String>[...response.cookies, cookie],
      headers: response.headers,
    );
  }
  return response;
}

Future<KugouResponse<Object?>> _userVisitors(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final isLite = context.config.isLite;
  final appId = jsNumber(jsOr(input['appid'], _liteAppId(context))).toInt();
  final clientVer = jsNumber(
    jsOr(input['clientver'], isLite ? 10672 : 20809),
  ).toInt();
  final publicKey = input['rsaPublicKey'] is String
      ? input['rsaPublicKey']! as String
      : appId == 3116
      ? liteKugouPublicKey
      : standardKugouPublicKey;
  final token = jsString(
    jsOr(input['token'], endpointCookie(context, input, 'token')),
  );
  final userid = jsNumber(
    jsOr(input['userid'], endpointCookie(context, input, 'userid')),
  ).toInt();
  final mid = jsString(
    jsOr(
      input['mid'],
      jsOr(endpointCookie(context, input, 'KUGOU_API_MID'), ''),
    ),
  );
  final dfid = jsString(
    jsOr(input['dfid'], jsOr(endpointCookie(context, input, 'dfid'), '-')),
  );
  final uuid = jsString(jsOr(input['uuid'], '-'));
  final tUserid = jsNumber(
    jsOr(jsOr(input['t_userid'], input['visit_userid']), userid),
  ).toInt();
  final clienttime = context.nowSeconds;
  final pPlain =
      '{"clienttime":$clienttime,"token":"$token","t_userid":$tUserid}';
  final p = context.crypto
      .rsaRawEncrypt(pPlain, publicKeyPem: publicKey)
      .toUpperCase();
  final data = <String, Object?>{
    'userid': userid,
    't_userid': tUserid,
    'p': p,
    'page': jsNumber(jsOr(input['page'], 1)).toInt(),
  };
  if (jsTruthy(input['busi_type'])) data['busi_type'] = input['busi_type'];
  final query = <String, Object?>{
    'dfid': dfid,
    'plat': '1',
    'clienttime': '$clienttime',
    'mid': mid,
    'uuid': uuid,
    'clientver': '$clientVer',
    'appid': '$appId',
  };
  final keys = query.keys.toList()..sort();
  final signatureSource = keys.map((key) => '$key=${query[key]}').join();
  final salt = appId == 3116
      ? 'LnT6xpN3khm36zse0QzvmgTZ3waWdRSA'
      : 'OIlwieks28dk2k092lksi2UIkp';
  query['signature'] = md5Hex(
    '$salt$signatureSource${jsJsonEncode(data)}$salt',
  );
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('http://usercenter.kugou.com'),
      path: '/v2/get_visitors',
      method: 'POST',
      data: data,
      parameters: query,
      clearDefaultParameters: true,
      skipSignature: true,
      headers: <String, Object?>{
        'Content-Type': 'text/plain; charset=ISO-8859-1',
        'User-Agent': 'Android15-1070-$clientVer-201-0-User-wifi',
        'KG-RC': '1',
        'KG-Rec': '1',
        'KG-THash': '3980f3c',
        if (jsTruthy(input['kg_devid']))
          'KG-DEVID': jsString(input['kg_devid']),
        if (jsTruthy(input['kg_clienttimems']))
          'KG-CLIENTTIMEMS': jsString(input['kg_clienttimems']),
      },
    ),
  );
}

Future<KugouResponse<Object?>> _userPreference(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final token = jsString(
    jsOr(input['token'], endpointCookie(context, input, 'token')),
  );
  final userid = jsNumber(
    jsOr(input['userid'], endpointCookie(context, input, 'userid')),
  ).toInt();
  final mid = jsString(
    jsOr(
      input['mid'],
      jsOr(
        endpointCookie(context, input, 'mid'),
        jsOr(endpointCookie(context, input, 'KUGOU_API_MID'), '-'),
      ),
    ),
  );
  final uuid = jsString(
    jsOr(
      input['uuid'],
      jsOr(
        endpointCookie(context, input, 'uuid'),
        jsOr(endpointCookie(context, input, 'KUGOU_API_GUID'), '-'),
      ),
    ),
  );
  final dfid = jsString(
    jsOr(input['dfid'], jsOr(endpointCookie(context, input, 'dfid'), '-')),
  );
  final appId = _liteAppId(context);
  final clientVer = _liteClientVer(context);
  final clienttime = context.nowSeconds;
  final strG2 = randomHexBytes(8);
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://gateway.kugou.com'),
      path: '/userpreferservice/v1/get_user_conf',
      method: 'POST',
      parameters: <String, Object?>{
        'appid': appId,
        'clientver': clientVer,
        'clienttime': clienttime,
        'mid': mid,
        'dfid': dfid,
        'uuid': uuid,
      },
      data: <String, Object?>{
        'plat': 1,
        'userid': userid,
        'p': context.crypto.rsaPkcs1Encrypt(
          jsJsonEncode(<String, Object?>{
            'key': strG2,
            'clienttime': '$clienttime',
          }),
        ),
        'params': context.crypto
            .aesEncrypt(
              jsJsonEncode(<String, Object?>{'token': token}),
              temporaryKey: strG2,
            )
            .ciphertext,
      },
      clearDefaultParameters: true,
      headers: <String, Object?>{
        'Content-Type': 'application/json',
        'User-Agent': 'Android15-1070-$clientVer-201-0-get_user_conf-wifi',
        'KG-Rec': '1',
        'KG-RC': '1',
      },
    ),
  );
}

Future<KugouResponse<Object?>> _userPreferenceUpdate(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  const fields = <String>[
    'mode',
    'gender',
    'age',
    'lang',
    'style',
    'song_lang',
    'stylerec_taglist',
    'wish_taglist',
    'inactive_taglist',
    'inactive_singerlist',
  ];
  if (!fields.any((key) => input[key] != null)) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        status: 400,
        httpStatus: 400,
        body: const <String, Object?>{
          'status': 0,
          'msg': '至少需要提供 gender/age/lang/style 等偏好字段之一',
        },
      ),
    );
  }
  final token = jsString(
    jsOr(input['token'], endpointCookie(context, input, 'token')),
  );
  final userid = jsNumber(
    jsOr(input['userid'], endpointCookie(context, input, 'userid')),
  ).toInt();
  final mid = jsString(
    jsOr(
      input['mid'],
      jsOr(
        endpointCookie(context, input, 'mid'),
        jsOr(endpointCookie(context, input, 'KUGOU_API_MID'), '-'),
      ),
    ),
  );
  final uuid = jsString(
    jsOr(
      input['uuid'],
      jsOr(
        endpointCookie(context, input, 'uuid'),
        jsOr(endpointCookie(context, input, 'KUGOU_API_GUID'), '-'),
      ),
    ),
  );
  final dfid = jsString(
    jsOr(input['dfid'], jsOr(endpointCookie(context, input, 'dfid'), '-')),
  );
  final appId = _liteAppId(context);
  final clientVer = _liteClientVer(context);
  final clienttime = context.nowSeconds;
  final strG2 = randomHexBytes(8);
  final data = <String, Object?>{
    for (final key in fields)
      if (input[key] != null)
        key:
            input[key] is Map<Object?, Object?> ||
                input[key] is Iterable<Object?>
            ? jsJsonEncode(input[key])
            : jsString(input[key]),
  };
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://gateway.kugou.com'),
      path: '/userpreferservice/v1/update_user_conf',
      method: 'POST',
      parameters: <String, Object?>{
        'appid': appId,
        'clientver': clientVer,
        'clienttime': clienttime,
        'mid': mid,
        'dfid': dfid,
        'uuid': uuid,
      },
      data: <String, Object?>{
        'plat': 1,
        'userid': userid,
        'p': context.crypto.rsaPkcs1Encrypt(
          jsJsonEncode(<String, Object?>{
            'key': strG2,
            'clienttime': '$clienttime',
          }),
        ),
        'data': data,
        'params': context.crypto
            .aesEncrypt(
              jsJsonEncode(<String, Object?>{'token': token}),
              temporaryKey: strG2,
            )
            .ciphertext,
      },
      clearDefaultParameters: true,
      headers: <String, Object?>{
        'Content-Type': 'application/json',
        'User-Agent': 'Android15-1070-$clientVer-201-0-update_user_conf-wifi',
        'KG-Rec': '1',
        'KG-RC': '1',
      },
    ),
  );
}

Future<KugouResponse<Object?>> _userUpdate(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  const nullable = <String>{'signature', 'tags', 'birthday'};
  const fields = <String>[
    'nickname',
    'sex',
    'birthday',
    'photo',
    'province',
    'city',
    'memo',
    'signature',
    'tags',
  ];
  final appId = _liteAppId(context);
  final clientVer = _liteClientVer(context);
  final token = jsString(
    jsOr(input['token'], endpointCookie(context, input, 'token')),
  );
  final userid = jsNumber(
    jsOr(input['userid'], endpointCookie(context, input, 'userid')),
  ).toInt();
  final mid = jsString(
    jsOr(
      input['mid'],
      jsOr(endpointCookie(context, input, 'KUGOU_API_MID'), ''),
    ),
  );
  final clienttime = context.nowSeconds;
  final data = <String, Object?>{};
  for (final key in fields) {
    final value = input[key];
    if (value == null) continue;
    if ('$value'.isEmpty && !nullable.contains(key)) continue;
    data[key] = '$value';
  }
  if (data.isEmpty) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        status: 400,
        httpStatus: 400,
        body: const <String, Object?>{'status': 0, 'msg': '至少需要提供一个待修改字段'},
      ),
    );
  }
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('http://update.user.kugou.com'),
      path: '/v1/update_userinfo',
      method: 'POST',
      data: <String, Object?>{
        'clienttime': clienttime,
        'appid': appId,
        'clientver': clientVer,
        'mid': mid,
        'uuid': '-',
        'userid': userid,
        'key': context.signatures.parametersKey(clienttime, appId, clientVer),
        'p': context.crypto
            .rsaRawEncrypt(
              jsJsonEncode(<String, Object?>{
                'clienttime': clienttime,
                'token': token,
              }),
            )
            .toUpperCase(),
        'data': data,
      },
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );
}

Future<KugouResponse<Object?>> _userUpdateAvatar(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final image = _imageBytes(<String, Object?>{
    'data': input['data'],
    'imgFile': firstValue(<Object?>[
      input['imgFile'],
      input['img'],
      input['file'],
    ]),
  });
  if (image == null || !_isImage(image)) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'msg':
            '图片数据无效（imgFile 需为 Buffer / base64 / dataURL，且为 JPEG/PNG/GIF/BMP/WEBP 格式）',
      },
    );
  }
  final now = DateTime.now();
  final date =
      '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  final upload = await context.request(
    KugouRequest(
      baseUri: Uri.parse('http://imgphp.kugou.com/imageupload'),
      path: '/post.php',
      method: 'POST',
      formFields: <String, String>{
        'type': 'kugouicon',
        'md5': md5Hex('${date}hewry678WEK23D'),
      },
      formFileBytes: image,
      formFileName: jsString(jsOr(input['filename'], 'avatar.jpg')),
      clearDefaultParameters: true,
      clearDefaultHeaders: true,
      skipSignature: true,
    ),
  );
  final uploadBody = stringObjectMap(upload.body);
  final fileName = uploadBody['FileName'] is List<Object?>
      ? (uploadBody['FileName']! as List<Object?>).isEmpty
            ? ''
            : jsString((uploadBody['FileName']! as List<Object?>).first)
      : jsString(uploadBody['FileName']);
  if (!jsTruthy(uploadBody['IsSuccess']) || fileName.isEmpty) {
    final message = uploadBody['Message'] is List<Object?>
        ? (uploadBody['Message']! as List<Object?>).isEmpty
              ? '图床上传失败'
              : jsString((uploadBody['Message']! as List<Object?>).first)
        : '图床上传失败';
    return rejectEndpoint(
      context,
      body: <String, Object?>{'status': 0, 'msg': message},
    );
  }
  final result = await _userUpdate(context, <String, Object?>{
    ...input,
    'photo': fileName,
  });
  final body = Map<String, Object?>.from(stringObjectMap(result.body));
  body['photo'] = fileName;
  body['pic'] = 'http://c1.kgimg.com/v2/kugouicon/$fileName';
  return KugouResponse<Object?>(
    status: result.status,
    httpStatus: result.httpStatus,
    body: body,
    cookies: result.cookies,
    headers: result.headers,
  );
}

bool _isImage(Uint8List bytes) {
  if (bytes.length < 4) return false;
  return (bytes[0] == 0xff && bytes[1] == 0xd8) ||
      (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47) ||
      (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) ||
      (bytes[0] == 0x42 && bytes[1] == 0x4d) ||
      (bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP');
}
