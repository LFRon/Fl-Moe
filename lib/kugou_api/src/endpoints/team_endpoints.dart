import '../config.dart';
import '../crypto.dart';
import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';

Map<String, KugouEndpointHandler> createTeamEndpointHandlers() =>
    <String, KugouEndpointHandler>{
      '/team/history': _teamHistory,
      '/team/join': _teamJoin,
      '/team/my': _teamMy,
      '/team/my/info': _teamMyInfo,
      '/team/my/status': _teamMyStatus,
      '/team/period/info': _teamPeriodInfo,
    };

Map<String, Object?> _teamParams(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final rawToken = jsString(
    jsOr(input['token'], endpointCookie(context, input, 'token')),
  );
  final userid = jsNumber(
    jsOr(input['userid'], jsOr(endpointCookie(context, input, 'userid'), '0')),
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
  final uuid = jsString(
    jsOr(input['uuid'], jsOr(endpointCookie(context, input, 'uuid'), '-')),
  );
  final token =
      'h5${context.crypto.rsaRawEncrypt('moc.uoguk.59::$rawToken', publicKeyPem: liteKugouPublicKey).toUpperCase()}';
  return <String, Object?>{
    'srcappid': KugouApiConfig.sourceAppId,
    'clientver': context.config.clientVersion,
    'clienttime': context.nowMilliseconds,
    'mid': mid,
    'uuid': uuid,
    'dfid': dfid,
    'appid': context.config.appId,
    'userid': userid,
    'token': token,
  };
}

Future<KugouResponse<Object?>> _teamRequest(
  KugouEndpointContext context,
  Map<String, Object?> input, {
  required String path,
  required String method,
  Map<String, Object?> extra = const <String, Object?>{},
  Object? data,
}) {
  final params = <String, Object?>{..._teamParams(context, input), ...extra};
  final bodyString = data == null ? null : jsJsonEncode(data);
  params['signature'] = context.signatures.web(params, bodyString);
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://gateway.kugou.com'),
      path: path,
      method: method,
      parameters: params,
      data: data,
      headers: const <String, Object?>{'Host': 'gateway.kugou.com'},
      skipSignature: true,
    ),
  );
}

Future<KugouResponse<Object?>> _teamHistory(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => _teamRequest(
  context,
  input,
  path: '/youth/v1/ut/get_team_record',
  method: 'GET',
  extra: <String, Object?>{
    'page': jsOr(input['page'], 1),
    'page_size': jsOr(input['page_size'], 10),
  },
);

Future<KugouResponse<Object?>> _teamJoin(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => _teamRequest(
  context,
  input,
  path: '/youth/v1/ut/join_team',
  method: 'POST',
  data: <String, Object?>{'team_code': input['team_code']},
);

Future<KugouResponse<Object?>> _teamMy(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => _teamRequest(
  context,
  input,
  path: '/youth/v1/ut/create_team',
  method: 'POST',
  data: <String, Object?>{'period_id': input['period_id']},
);

Future<KugouResponse<Object?>> _teamMyInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => _teamRequest(
  context,
  input,
  path: '/youth/v1/ut/get_my_team_info',
  method: 'GET',
  extra: <String, Object?>{'period_id': input['period_id']},
);

Future<KugouResponse<Object?>> _teamMyStatus(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => _teamRequest(
  context,
  input,
  path: '/youth/v1/ut/get_user_status',
  method: 'GET',
  extra: <String, Object?>{'period_id': input['period_id']},
);

Future<KugouResponse<Object?>> _teamPeriodInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => _teamRequest(
  context,
  input,
  path: '/youth/v1/ut/get_period_info',
  method: 'GET',
);
