import '../endpoint.dart';
import '../models.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createSsaEndpointHandlers() =>
    <String, KugouEndpointHandler>{
      '/sidedt': _sideDt,
      // Override the generated version so sidedt and direct verification share
      // one statically typed implementation.
      '/verify/user/info': _verifyUserInfo,
    };

Future<KugouResponse<Object?>> _sideDt(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final generated = context.ssa.generate(
    mid: input['mid'] ?? endpointCookie(context, input, 'KUGOU_API_MID') ?? '0',
    userId: input['userid'] ?? endpointCookie(context, input, 'userid') ?? '0',
    dfid: input['dfid'] ?? endpointCookie(context, input, 'dfid') ?? '0',
    webGlHash: jsString(
      endpointCookie(context, input, 'KUGOU_API_WEBGL') ?? generateWebGlHash(),
    ),
  );
  return _verifyUserInfo(context, <String, Object?>{
    ...input,
    'edt': generated.edt,
    'sid': generated.sid,
  });
}

Future<KugouResponse<Object?>> _verifyUserInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final verificationType = jsNumber(jsOr(input['v_type'], 23)).toInt();
  final userId = jsNumber(
    input['userid'] ?? endpointCookie(context, input, 'userid') ?? '0',
  ).toInt();
  final data = <String, Object?>{
    'eventid': input['eventid'],
    'userid': userId,
    'platid': jsOr(input['platid'], 2),
    'v_type': verificationType,
    'wasm': 1,
    'i': '',
    'sid': Uri.decodeComponent(jsString(jsOr(input['sid'], ''))),
    'edt': Uri.decodeComponent(jsString(jsOr(input['edt'], ''))),
  };
  if (verificationType == 23) {
    final encrypted = context.crypto.aesEncrypt(<String, Object?>{});
    data.addAll(<String, Object?>{
      'verifycode': Uri.decodeComponent(
        jsString(jsOr(input['verifycode'], '')),
      ),
      'pk': context.crypto.rsaRawEncrypt(<String, Object?>{
        'key': encrypted.key,
      }),
      'params': encrypted.ciphertext,
    });
  }
  if (verificationType == 32) {
    final encrypted = context.crypto.aesEncrypt(<String, Object?>{
      'code': jsOr(input['verifycode'], ''),
    });
    data.addAll(<String, Object?>{
      'code': Uri.decodeComponent(jsString(jsOr(input['verifycode'], ''))),
      'pk': context.crypto.rsaRawEncrypt(<String, Object?>{
        'key': encrypted.key,
      }),
      'params': encrypted.ciphertext,
    });
  }
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://verifyservice.kugou.com'),
      path: '/v4/verify_user_info',
      method: 'POST',
      parameters: <String, Object?>{'clientver': 11510},
      data: data,
    ),
  );
}
