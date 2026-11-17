import 'dart:convert';
import 'dart:math';

import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';

const String _youthBase = 'https://youth.kugou.com';
const String _gatewayBase = 'https://gateway.kugou.com';
const String _selfStudyBiz = '1000';
const String _musicRoomBiz = '1009';
const String _defaultMusicRoomBg =
    'https://youthimgbssdl.kugou.com/6e9cdcef8d163d06225d8cbeaa2f1ece.JPEG';
const int _studyPageId = 711586122;
const String _parentPageId = '356753938';

Map<String, KugouEndpointHandler> createListenTogetherHandlers() =>
    <String, KugouEndpointHandler>{
      '/listen/together/chat': _chat,
      '/listen/together/discovery': _discovery,
      '/listen/together/music': _music,
      '/listen/together/room': _room,
      '/listen/together/study': _study,
    };

typedef _ParamBuilder = Map<String, Object?> Function(Map<String, Object?>);
typedef _DataBuilder = Object? Function(Map<String, Object?>);

final class _Operation {
  const _Operation(
    this.baseUri,
    this.path,
    this.method, {
    this.params,
    this.data,
  });

  final String baseUri;
  final String path;
  final String method;
  final _ParamBuilder? params;
  final _DataBuilder? data;
}

Object? _parseJsonValue(Object? value, Object? fallback) {
  if (value == null || value == '') return fallback;
  if (value is! String) return value;
  try {
    return jsonDecode(value);
  } on FormatException {
    return fallback;
  }
}

Map<String, Object?> _parseObject(
  Object? value, [
  Map<String, Object?>? fallback,
]) {
  final parsed = _parseJsonValue(value, fallback ?? <String, Object?>{});
  return parsed is Map<Object?, Object?>
      ? stringObjectMap(parsed)
      : <String, Object?>{};
}

List<Object?> _parseArray(Object? value) {
  final parsed = _parseJsonValue(value, <Object?>[]);
  return parsed is List<Object?> ? parsed : <Object?>[];
}

Map<String, Object?> _authBody(Map<String, Object?> params) {
  final cookie = stringObjectMap(params['cookie']);
  return <String, Object?>{
    'userid': jsNumber(
      jsOr(params['userid'], jsOr(cookie['userid'], 0)),
    ).toInt(),
    'token': jsOr(params['token'], jsOr(cookie['token'], '')),
  };
}

List<Object?> _musicRoomAudios(Map<String, Object?> params) {
  final audios = _parseArray(params['audios']);
  final result = <Object?>[];
  for (final raw in audios.take(50)) {
    final audio = stringObjectMap(raw);
    final hash = jsString(jsOr(audio['hash'], ''));
    if (hash.isEmpty) continue;
    result.add(<String, Object?>{
      'hash': hash,
      'mixsongid': jsOr(audio['mixsongid'], jsOr(audio['mixSongId'], '')),
      'fid': jsOr(audio['fid'], 0),
    });
  }
  return result;
}

Future<KugouResponse<Object?>> _domainHandler(
  KugouEndpointContext context,
  Map<String, Object?> params,
  Map<String, _Operation> operations,
) {
  final body = _parseObject(params['body']);
  final input = <String, Object?>{...params, ...body};
  final operation = input['operation'];
  final config = operations[jsString(operation)];
  if (config == null) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        status: 400,
        httpStatus: 400,
        body: <String, Object?>{
          'status': 0,
          'error_code': 400,
          'error_msg': '不支持的操作: ${operation ?? ''}',
        },
      ),
    );
  }
  return context.request(
    KugouRequest(
      baseUri: Uri.parse(config.baseUri),
      path: config.path,
      method: config.method,
      parameters: config.params?.call(input) ?? const <String, Object?>{},
      data:
          config.data?.call(input) ??
          (config.method == 'POST' ? <String, Object?>{} : null),
      cookies: stringStringMap(input['cookie']),
    ),
  );
}

Future<KugouResponse<Object?>> _chat(
  KugouEndpointContext context,
  Map<String, Object?> params,
) => _domainHandler(context, params, <String, _Operation>{
  'send': _Operation(
    _gatewayBase,
    '/rmservice/v1/group/chat',
    'POST',
    data: (input) => <String, Object?>{
      ..._authBody(input),
      'biz': jsOr(input['biz'], _selfStudyBiz),
      'groupid': jsOr(input['groupid'], jsOr(input['room_id'], '')),
      'message': <String, Object?>{
        'msgtype': jsOr(input['msgtype'], 801),
        'nickname': jsOr(input['nickname'], ''),
        'img': jsOr(input['img'], ''),
        'alert': jsOr(input['alert'], jsOr(input['message'], '')),
      },
    },
  ),
  'history': _Operation(
    _gatewayBase,
    '/rmservice/v1/group/msg_history',
    'POST',
    data: (input) => <String, Object?>{
      ..._authBody(input),
      'biz': jsOr(input['biz'], _selfStudyBiz),
      'groupid': jsOr(input['groupid'], jsOr(input['room_id'], '')),
      'maxid': jsOr(input['maxid'], '0'),
      'pagesize': jsOr(input['pagesize'], '20'),
    },
  ),
});

Future<KugouResponse<Object?>> _discovery(
  KugouEndpointContext context,
  Map<String, Object?> params,
) => _domainHandler(context, params, <String, _Operation>{
  'channel_search': _Operation(
    _youthBase,
    '/v1/search/channel',
    'GET',
    params: (input) => <String, Object?>{
      'keyword': jsOr(input['keyword'], ''),
      'page': jsOr(input['page'], 1),
      'position': jsOr(input['position'], 1),
    },
  ),
  'kugroup_square': _Operation(
    _youthBase,
    '/v1/kugroup/square',
    'GET',
    params: (input) => <String, Object?>{
      'page': jsOr(input['page'], 1),
      'pagesize': jsOr(input['pagesize'], 20),
      'order_type': jsOr(input['order_type'], 1),
    },
  ),
  'genting_square': _Operation(
    _youthBase,
    '/v1/genting/square',
    'GET',
    params: (input) => <String, Object?>{
      'page': jsOr(input['page'], 1),
      'pagesize': jsOr(input['pagesize'], 20),
      'order_type': jsOr(input['order_type'], 1),
    },
  ),
  'kugroup_streamers': _Operation(
    _youthBase,
    '/v1/kugroup/get_streamer_list',
    'GET',
    params: (input) => <String, Object?>{
      'longitude': jsOr(input['longitude'], 0),
      'latitude': jsOr(input['latitude'], 0),
    },
  ),
  'genting_streamers': _Operation(
    _youthBase,
    '/v1/genting/get_streamer_list',
    'GET',
    params: (input) => <String, Object?>{
      'page': jsOr(input['page'], 1),
      'pagesize': jsOr(input['pagesize'], 20),
    },
  ),
  'recent_rooms': _Operation(
    _youthBase,
    '/v3/user/recent_room_dynamic',
    'GET',
    params: (_) => const <String, Object?>{},
  ),
  'privilege': _Operation(
    _youthBase,
    '/v1/privilege/operate',
    'GET',
    params: (input) => <String, Object?>{
      'event_type': jsOr(input['event_type'], 4),
    },
  ),
  'genting_recommend': _Operation(
    'https://concepts.kugou.com',
    '/v1/genting/recommend',
    'POST',
    params: (input) => <String, Object?>{
      'page': jsOr(input['page'], 1),
      'pagesize': jsOr(input['pagesize'], 20),
      'room_biz': jsOr(input['room_biz'], 1006),
    },
  ),
});

Future<KugouResponse<Object?>> _music(
  KugouEndpointContext context,
  Map<String, Object?> params,
) => _domainHandler(context, params, <String, _Operation>{
  'history': _Operation(
    _gatewayBase,
    '/youth/v1/genting/history',
    'GET',
    params: (input) => <String, Object?>{
      'last_id': jsNumber(jsOr(input['last_id'], 0)).toInt(),
    },
  ),
  'list': _Operation(
    _gatewayBase,
    '/youth/v2/genting/recommend',
    'POST',
    params: (input) => <String, Object?>{
      'page': max(0, jsNumber(jsOr(input['page'], 1)).toInt() - 1),
      'pagesize': jsNumber(jsOr(input['pagesize'], 20)).toInt(),
      'loop_pick': jsNumber(jsOr(input['loop_pick'], 0)).toInt(),
      'tags': jsOr(input['tags'], ''),
      'room_biz': _musicRoomBiz,
      if (jsTruthy(input['mixsongid'])) 'mixsongid': input['mixsongid'],
    },
    data: (input) => <String, Object?>{'data': _parseArray(input['behaviors'])},
  ),
  'detail': _Operation(
    _gatewayBase,
    '/youth/v1/genting/get_musicroom_info',
    'GET',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
      'biz': jsOr(input['biz'], _musicRoomBiz),
    },
  ),
  'members': _Operation(
    _gatewayBase,
    '/youth/v1/genting/get_musicroom_member',
    'GET',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
      'page': max(1, jsNumber(jsOr(input['page'], 1)).toInt()),
      'pagesize': jsNumber(jsOr(input['pagesize'], 100)).toInt(),
      'apiver': '3',
    },
  ),
  'initialize': _Operation(
    _gatewayBase,
    '/youth/v1/genting/init_musicroom',
    'POST',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
    },
    data: (input) {
      final body = <String, Object?>{
        'sendall': jsNumber(jsOr(input['sendall'], 1)).toInt(),
        'audios': _musicRoomAudios(input),
      };
      final progress = _parseObject(input['progress_info']);
      if (progress.isNotEmpty) body['progress_info'] = progress;
      return body;
    },
  ),
  'sync_player': _Operation(
    _gatewayBase,
    '/youth/v1/genting/music_sync_player',
    'POST',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
      'frm': jsNumber(jsOr(input['frm'], 2)).toInt(),
    },
    data: (_) => const <String, Object?>{},
  ),
  'playback_url': _Operation(
    _gatewayBase,
    '/youth/v1/genting/music_reqcmd',
    'POST',
    params: (_) => const <String, Object?>{
      'page_id': 147780134,
      'ppage_id': _parentPageId,
    },
    data: (input) => <String, Object?>{
      ..._authBody(input),
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
      'audio': <String, Object?>{
        'hash': jsOr(input['hash'], ''),
        'mixsongid': jsOr(input['mixsongid'], ''),
      },
    },
  ),
  'switch_song': _Operation(
    _gatewayBase,
    '/youth/v1/genting/music_sw',
    'POST',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
    },
    data: (input) => <String, Object?>{
      'act_type': jsNumber(jsOr(input['act_type'], 1)).toInt(),
      'list_version': jsString(jsOr(input['list_version'], '')),
      'is_auto': jsNumber(jsOr(input['is_auto'], 0)) != 0 ? '1' : '0',
      'audio': <String, Object?>{
        'hash': jsOr(input['hash'], ''),
        'mixsongid': jsOr(input['mixsongid'], ''),
      },
    },
  ),
  'player_operation': _Operation(
    _gatewayBase,
    '/youth/v1/genting/music_player_opr',
    'POST',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
    },
    data: (input) {
      final action = jsNumber(jsOr(input['action'], 3)).toInt();
      final body = <String, Object?>{'action': action};
      if (action == 1) {
        body['play_mode'] = jsNumber(jsOr(input['play_mode'], 1)).toInt();
      }
      if (action == 2) {
        body['progress'] = max(0, jsNumber(jsOr(input['progress'], 0)).floor());
      }
      if (action == 3) {
        body['pause'] = jsNumber(jsOr(input['pause'], 2)) == 1 ? '1' : '2';
      }
      return body;
    },
  ),
  'playlist': _Operation(
    _gatewayBase,
    '/youth/v1/genting/music_fetch_list',
    'POST',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
    },
    data: (input) {
      final body = <String, Object?>{
        'pagesize': jsNumber(jsOr(input['pagesize'], 50)).toInt(),
      };
      final audio = _parseObject(input['audio']);
      if (jsTruthy(audio['hash'])) {
        body['audio'] = <String, Object?>{
          'hash': audio['hash'],
          'mixsongid': jsOr(audio['mixsongid'], jsOr(audio['mixSongId'], '')),
        };
      }
      return body;
    },
  ),
  'recent_playlist': _Operation(
    _gatewayBase,
    '/youth/v1/genting/music_recent_list',
    'POST',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
    },
    data: (_) => '',
  ),
  'order_song': _Operation(
    _gatewayBase,
    '/youth/v1/genting/order_song',
    'POST',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
    },
    data: (input) => <String, Object?>{
      'mixsongid': jsOr(input['mixsongid'], ''),
      'hash': jsOr(input['hash'], ''),
    },
  ),
  'song_order_list': _Operation(
    _gatewayBase,
    '/youth/v1/genting/song_order_list',
    'GET',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
    },
  ),
  'remove_song': _Operation(
    _gatewayBase,
    '/youth/v1/genting/remove_song',
    'POST',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
    },
    data: (input) => <String, Object?>{
      'mixsongid': jsOr(input['mixsongid'], ''),
      'hash': jsOr(input['hash'], ''),
      'order_userid': jsString(jsOr(input['order_userid'], '')),
    },
  ),
  'music_add': _Operation(
    _gatewayBase,
    '/youth/v1/genting/music_add',
    'POST',
    params: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
      if (jsTruthy(input['order_userid'])) ...<String, Object?>{
        'order_userid': jsString(input['order_userid']),
        'source': jsString(jsOr(input['source'], 1)),
      },
    },
    data: (input) {
      final body = <String, Object?>{
        'action': jsNumber(jsOr(input['action'], 4)).toInt(),
        'list_version': jsString(jsOr(input['list_version'], '')),
        'sendall': jsNumber(jsOr(input['sendall'], 1)).toInt(),
        'audios': _musicRoomAudios(input),
      };
      final progress = _parseObject(input['progress_info']);
      if (progress.isNotEmpty) body['progress_info'] = progress;
      return body;
    },
  ),
});

Future<KugouResponse<Object?>> _room(
  KugouEndpointContext context,
  Map<String, Object?> params,
) => _domainHandler(context, params, <String, _Operation>{
  'create': _Operation(
    _gatewayBase,
    '/rmservice/v1/group/create',
    'POST',
    data: (input) {
      final biz = jsString(jsOr(input['biz'], _selfStudyBiz));
      final privacy = jsNumber(
        jsOr(input['room_privacy'], biz == _musicRoomBiz ? 1 : 3),
      ).toInt();
      final passThrough = <String, Object?>{
        ..._parseObject(input['pass_through_data']),
        'room_privacy': privacy,
        'cp_notice': 1,
      };
      final body = <String, Object?>{
        ..._authBody(input),
        'biz': biz,
        'pass_through_data': passThrough,
      };
      if (biz == _musicRoomBiz) {
        body['introduction'] = jsOr(
          input['introduction'],
          jsOr(input['room_name'], ''),
        );
        passThrough['room_bg_content'] = jsJsonEncode(<String, Object?>{
          'bg_img': jsOr(input['background_url'], _defaultMusicRoomBg),
          'room_bg_type': jsString(jsOr(input['room_bg_type'], 2)),
        });
        if (privacy == 1) {
          passThrough['global_collection_id'] = jsOr(
            input['global_collection_id'],
            '',
          );
        } else {
          body['capacity'] = jsNumber(jsOr(input['capacity'], 5)).toInt();
        }
      } else {
        final defined = _parseArray(input['biz_defined_data']);
        body['biz_defined_data'] = defined.isNotEmpty
            ? defined
            : <Object?>[
                <String, Object?>{'key': 'lyric_switch', 'value': 1},
              ];
      }
      return body;
    },
  ),
  'join': _Operation(
    _gatewayBase,
    '/rmservice/v1/group/join',
    'POST',
    data: (input) => <String, Object?>{
      ..._authBody(input),
      'biz': jsOr(input['biz'], _selfStudyBiz),
      'groupid': jsOr(input['groupid'], jsOr(input['room_id'], '')),
      'pass_through_data': jsOr(input['pass_through_data'], <String, Object?>{
        'cp_notice': 1,
      }),
    },
  ),
  'state': _Operation(
    _gatewayBase,
    '/rmservice/v1/group/info',
    'POST',
    params: (input) => <String, Object?>{
      'biz': jsOr(input['biz'], _selfStudyBiz),
    },
    data: (input) => <String, Object?>{
      'groupid': jsOr(input['groupid'], jsOr(input['room_id'], '')),
    },
  ),
  'heartbeat': _Operation(
    _gatewayBase,
    '/rmservice/v1/group/heartbeat',
    'POST',
    data: _groupOperationData,
  ),
  'status': _Operation(
    _gatewayBase,
    '/rmservice/v1/user/get_status',
    'POST',
    data: _groupOperationData,
  ),
  'leave': _Operation(
    _gatewayBase,
    '/rmservice/v1/group/leave',
    'POST',
    data: _groupOperationData,
  ),
  'dismiss': _Operation(
    _gatewayBase,
    '/rmservice/v1/group/dismiss',
    'POST',
    data: _groupOperationData,
  ),
  'update_chat': _Operation(
    _gatewayBase,
    '/rmservice/v1/group/update_info',
    'POST',
    data: (input) => <String, Object?>{
      'groupid': jsOr(input['groupid'], jsOr(input['room_id'], '')),
      'biz': _musicRoomBiz,
      'switch': <String, Object?>{'chat': jsNumber(input['chat']) == 1 ? 1 : 2},
    },
  ),
  'check_minor': _Operation(
    _youthBase,
    '/v1/risk/check_minor',
    'GET',
    params: (_) => const <String, Object?>{},
  ),
});

Map<String, Object?> _groupOperationData(Map<String, Object?> input) =>
    <String, Object?>{
      ..._authBody(input),
      'biz': jsOr(input['biz'], _selfStudyBiz),
      'groupid': jsOr(input['groupid'], jsOr(input['room_id'], '')),
    };

Future<KugouResponse<Object?>> _study(
  KugouEndpointContext context,
  Map<String, Object?> params,
) => _domainHandler(context, params, <String, _Operation>{
  'created_rooms': _Operation(
    _youthBase,
    '/v1/study/user_create_room_list',
    'GET',
    params: (_) => const <String, Object?>{},
  ),
  'delete_created_room': _Operation(
    _gatewayBase,
    '/youth/v1/room/delete_room',
    'DELETE',
    params: (input) => <String, Object?>{
      'global_collection_id': jsOr(
        input['global_collection_id'],
        jsOr(input['channel_id'], ''),
      ),
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
    },
  ),
  'list': _Operation(
    _youthBase,
    '/v1/room/get_room_list_by_tag',
    'GET',
    params: (input) => <String, Object?>{
      'page': jsOr(input['page'], 1),
      'pagesize': jsOr(input['pagesize'], 20),
      'sort': jsOr(input['sort'], 0),
      'page_id': jsOr(input['page_id'], 191708212),
      'ppage_id': jsOr(input['ppage_id'], _parentPageId),
      'tag_id': jsOr(input['tag_id'], ''),
    },
  ),
  'detail': _Operation(
    _youthBase,
    '/v1/room/get_room_detail',
    'GET',
    params: (input) => <String, Object?>{'room_id': jsOr(input['room_id'], '')},
  ),
  'members': _Operation(
    _youthBase,
    '/v1/room/get_member_list',
    'GET',
    params: (input) => <String, Object?>{
      'room_id': jsOr(input['room_id'], ''),
      'page': jsOr(input['page'], 1),
      'pagesize': jsOr(input['pagesize'], 20),
      'member_type': jsNumber(jsOr(input['member_type'], 1)).toInt(),
    },
  ),
  'configure': _Operation(
    _youthBase,
    '/v1/user/make_room',
    'POST',
    params: (input) {
      const pageIds = <int, int>{1: _studyPageId, 2: 971343961, 3: 711357575};
      return <String, Object?>{
        'page_id': jsOr(
          input['page_id'],
          pageIds[jsNumber(input['music_type']).toInt()] ?? _studyPageId,
        ),
        'ppage_id': jsOr(input['ppage_id'], _parentPageId),
        'type': input['type'] ?? 1,
      };
    },
    data: (input) {
      final body = <String, Object?>{
        'room_id': jsOr(input['room_id'], ''),
        'room_name': jsOr(input['room_name'], ''),
        'global_collection_id': jsOr(input['global_collection_id'], ''),
        'room_notice': jsOr(input['room_notice'], ''),
        'allow_chat': input['allow_chat'] ?? 1,
        'room_tag': jsOr(input['room_tag'], '2'),
        'music_type': jsNumber(jsOr(input['music_type'], 1)).toInt(),
      };
      if (jsNumber(body['music_type']) == 1 ||
          jsNumber(body['music_type']) == 2) {
        if (jsTruthy(input['music_style'])) {
          body['music_style'] = input['music_style'];
        }
        final audios = _parseArray(input['audios']);
        if (audios.isNotEmpty) body['audios'] = audios;
      } else if (jsNumber(body['music_type']) == 3) {
        body['white_noise_type'] = jsOr(input['white_noise_type'], 1);
      }
      return body;
    },
  ),
  'sync_player': _Operation(
    _youthBase,
    '/v1/music/sync_player',
    'POST',
    params: (input) => <String, Object?>{
      'page_id': jsOr(input['page_id'], _studyPageId),
      'ppage_id': jsOr(input['ppage_id'], _parentPageId),
    },
    data: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
      'frm': jsOr(input['frm'], 2),
      ..._authBody(input),
    },
  ),
  'playlist': _Operation(
    _youthBase,
    '/v1/music/fetch_list',
    'POST',
    params: (input) => <String, Object?>{
      'page_id': jsOr(input['page_id'], _studyPageId),
      'ppage_id': jsOr(input['ppage_id'], _parentPageId),
    },
    data: (input) => <String, Object?>{
      'roomid': jsOr(input['roomid'], jsOr(input['room_id'], '')),
      'frm': jsOr(input['frm'], 2),
      'pagesize': jsOr(input['pagesize'], 50),
      ..._authBody(input),
    },
  ),
});
