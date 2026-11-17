import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';

const String _commentHost = 'm.comment.service.kugou.com';
const String _songCommentCode = 'fc4be23b4e972707f36b8a828a93ba8a';
const String _albumCommentCode = '94f1792ced1df89aa68a7939eaf2efca';
const String _playlistCommentCode = 'ca53b96fe5a1d9c22d71c8f522ef7c4f';
const String _songBarrageCode = 'articulossong';
const String _videoBarrageCode = 'db3664c219a6e350b00ab08d7f723a79';

Map<String, KugouEndpointHandler> createCommentEndpointHandlers() =>
    <String, KugouEndpointHandler>{
      '/comment/album/send': _commentAlbumSend,
      '/comment/floor/send': _commentFloorSend,
      '/comment/music/del': _commentMusicDel,
      '/comment/music/send': _commentMusicSend,
      '/comment/playlist/send': _commentPlaylistSend,
      '/song/barrage': _songBarrage,
      '/song/barrage/send': _songBarrageSend,
      '/video/barrage': _videoBarrage,
      '/video/barrage/send': _videoBarrageSend,
    };

typedef _CommentIdentity = ({
  int clienttime,
  String mid,
  String token,
  Object? userid,
  String dfid,
  String uuid,
});

_CommentIdentity _identity(
  KugouEndpointContext context,
  Map<String, Object?> params,
) {
  final clienttime = jsNumber(
    jsOr(params['clienttime'], context.nowSeconds),
  ).toInt();
  final mid = jsString(
    jsOr(params['mid'], endpointCookie(context, params, 'KUGOU_API_MID')),
  );
  final token = jsString(
    jsOr(
      jsOr(params['clienttoken'], params['token']),
      endpointCookie(context, params, 'token'),
    ),
  );
  final userid = jsOr(
    jsOr(params['kugouid'], params['userid']),
    jsOr(endpointCookie(context, params, 'userid'), 0),
  );
  final dfid = jsString(
    jsOr(jsOr(params['dfid'], endpointCookie(context, params, 'dfid')), '-'),
  );
  final uuid = jsString(
    jsOr(jsOr(params['uuid'], endpointCookie(context, params, 'uuid')), '-'),
  );
  return (
    clienttime: clienttime,
    mid: mid,
    token: token,
    userid: userid,
    dfid: dfid,
    uuid: uuid,
  );
}

Map<String, Object?> _listAuthParams(
  KugouEndpointContext context,
  Map<String, Object?> params,
) {
  final identity = _identity(context, params);
  return <String, Object?>{
    'kugouid': identity.userid,
    'ver': jsOr(params['ver'], 6),
    'clienttoken': identity.token,
    'appid': context.config.appId,
    'clientver': context.config.clientVersion,
    'mid': identity.mid,
    'clienttime': identity.clienttime,
    'key': context.signatures.parametersKey('${identity.clienttime}'),
    'uuid': identity.uuid,
    'dfid': identity.dfid,
  };
}

KugouRequest _commentRequest(
  KugouEndpointContext context,
  Map<String, Object?> params,
  Map<String, Object?> query, {
  String method = 'GET',
  Object? data,
}) => KugouRequest(
  path: '/index.php',
  method: method,
  parameters: compactObject(query),
  data: data,
  cookies: stringStringMap(params['cookie']),
  clearDefaultParameters: true,
  skipSignature: true,
  headers: compactObject(<String, Object?>{
    'x-router': _commentHost,
    'Content-Type': data == null ? null : 'application/json; charset=UTF-8',
  }),
);

Map<String, Object?> _buildSongBarrageListQuery(
  KugouEndpointContext context,
  Map<String, Object?> params,
) {
  final specialId = firstValue(<Object?>[
    params['special_id'],
    params['childrenid'],
    params['id'],
  ]);
  final hash = firstValue(<Object?>[
    params['hash'],
    params['schash'],
    params['extdata'],
  ]);
  return <String, Object?>{
    'r': 'comments/getCommentWithLike',
    'code': _songBarrageCode,
    'childrenid': specialId,
    'extdata': specialId == null ? hash : null,
    'childrenname': firstValue(<Object?>[
      params['name'],
      params['song_name'],
      params['childrenname'],
    ]),
    'mixsongid': firstValue(<Object?>[
      params['mixsongid'],
      params['album_audio_id'],
    ]),
    'p': firstValue(<Object?>[params['page'], params['p'], 1]),
    'pagesize': firstValue(<Object?>[params['pagesize'], 20]),
    ..._listAuthParams(context, params),
  };
}

Map<String, Object?> _buildVideoBarrageListQuery(
  KugouEndpointContext context,
  Map<String, Object?> params,
) {
  final videoId = firstValue(<Object?>[
    params['video_id'],
    params['childrenid'],
    params['id'],
  ]);
  final hash = firstValue(<Object?>[
    params['hash'],
    params['mvhash'],
    params['extdata'],
  ]);
  return <String, Object?>{
    'r': 'comments/getCommentWithLike',
    'code': _videoBarrageCode,
    'childrenid': videoId,
    'extdata': videoId == null ? hash : null,
    'childrenname': firstValue(<Object?>[
      params['name'],
      params['video_name'],
      params['childrenname'],
    ]),
    'p': firstValue(<Object?>[params['page'], params['p'], 1]),
    'pagesize': firstValue(<Object?>[params['pagesize'], 20]),
    ..._listAuthParams(context, params),
  };
}

typedef _CommentSendPayload = ({Map<String, Object?> query, Object? data});

_CommentSendPayload _commentSendQuery(
  KugouEndpointContext context,
  Map<String, Object?> params,
  String code,
) {
  final identity = _identity(context, params);
  final contentData = compactObject(<String, Object?>{
    'content': params['content'],
    'album_audio_id': firstValue(<Object?>[
      params['mixsongid'],
      params['album_audio_id'],
    ]),
    'title': params['title'],
    'extdata': params['content_extdata'],
    'images': params['images'] is List<Object?>
        ? params['images']
        : <Object?>[],
  });
  final data = jsJsonEncode(<String, Object?>{'data': contentData});
  return (
    query: <String, Object?>{
      'r': 'commentsv3/add',
      'code': code,
      'childrenid': firstValue(<Object?>[
        params['special_id'],
        params['childrenid'],
        params['id'],
      ]),
      'childrenname': firstValue(<Object?>[
        params['name'],
        params['song_name'],
        params['album_name'],
        params['playlist_name'],
        params['childrenname'],
      ]),
      'kugouid': identity.userid,
      'ver': firstValue(<Object?>[params['ver'], 6]),
      'clienttoken': identity.token,
      'appid': context.config.appId,
      'clientver': context.config.clientVersion,
      'mid': identity.mid,
      'clienttime': identity.clienttime,
      'key': context.signatures.parametersKey(
        '${identity.clienttime}${identity.mid}$data',
      ),
      'uuid': identity.uuid,
      'dfid': identity.dfid,
      'source': params['source'],
    },
    data: data,
  );
}

Map<String, Object?> _commentReplyQuery(
  KugouEndpointContext context,
  Map<String, Object?> params,
  String code,
) {
  final identity = _identity(context, params);
  final pid = firstValue(<Object?>[params['pid'], 0]);
  final isTopLevelReply = firstValue(<Object?>[
    params['is_t'],
    params['isT'],
    '$pid' == '0' ? 1 : 0,
  ]);
  final replyUserName = firstValue(<Object?>[
    params['reply_user_name'],
    params['puser'],
  ]);
  final replyContent = firstValue(<Object?>[
    params['reply_content'],
    params['pcontent'],
  ]);
  final rawContent = jsString(params['content']);
  final content =
      replyUserName != null &&
          replyContent != null &&
          !rawContent.contains('//@')
      ? '$rawContent//@$replyUserName:$replyContent'
      : params['content'];
  return <String, Object?>{
    'r': 'commentsv2/reply',
    'code': code,
    'childrenid': firstValue(<Object?>[
      params['special_id'],
      params['childrenid'],
      params['id'],
    ]),
    'childrenname': firstValue(<Object?>[
      params['name'],
      params['song_name'],
      params['album_name'],
      params['playlist_name'],
      params['childrenname'],
    ]),
    'kugouid': identity.userid,
    'ver': firstValue(<Object?>[params['ver'], 6]),
    'clienttoken': identity.token,
    'appid': context.config.appId,
    'clientver': context.config.clientVersion,
    'mid': identity.mid,
    'clienttime': identity.clienttime,
    'key': context.signatures.parametersKey(
      '${identity.clienttime}${identity.mid}',
    ),
    'uuid': identity.uuid,
    'dfid': identity.dfid,
    'extdata': params['extdata'],
    'content': content,
    'tid': params['tid'],
    'is_t': isTopLevelReply,
    'pid': pid,
    'source': params['source'],
  };
}

Map<String, Object?> _commentDelQuery(
  KugouEndpointContext context,
  Map<String, Object?> params,
  String code,
) {
  final identity = _identity(context, params);
  return <String, Object?>{
    'r': 'commentsv2/delcomment',
    'code': code,
    'childrenid': firstValue(<Object?>[
      params['special_id'],
      params['childrenid'],
      params['id'],
    ]),
    'cid': firstValue(<Object?>[params['cid'], params['comment_id']]),
    'tid': params['tid'],
    'kugouid': identity.userid,
    'ver': firstValue(<Object?>[params['ver'], 6]),
    'clienttoken': identity.token,
    'appid': context.config.appId,
    'clientver': context.config.clientVersion,
    'mid': identity.mid,
    'clienttime': identity.clienttime,
    'key': context.signatures.parametersKey(
      '${identity.clienttime}${identity.mid}',
    ),
    'uuid': identity.uuid,
    'dfid': identity.dfid,
  };
}

Map<String, Object?> _videoBarrageSendQuery(
  KugouEndpointContext context,
  Map<String, Object?> params,
) {
  final identity = _identity(context, params);
  return <String, Object?>{
    'r': 'comments/addcomment',
    'code': _videoBarrageCode,
    'childrenid': firstValue(<Object?>[
      params['video_id'],
      params['childrenid'],
      params['id'],
    ]),
    'childrenname': firstValue(<Object?>[
      params['name'],
      params['video_name'],
      params['childrenname'],
    ]),
    'ver': firstValue(<Object?>[params['ver'], '1.02']),
    'content': params['content'],
    'pid': params['pid'],
    'clientver': context.config.clientVersion,
    'mid': identity.mid,
    'clienttoken': identity.token,
    'kugouid': identity.userid,
    'appid': context.config.appId,
  };
}

String _resolveCommentCode(Map<String, Object?> params) {
  final explicit = firstValue(<Object?>[params['code']]);
  if (explicit != null) return jsString(explicit);
  final resourceType = jsString(
    firstValue(<Object?>[
      params['resource_type'],
      params['resourceType'],
      'song',
    ]),
  ).toLowerCase();
  if (resourceType == 'album') return _albumCommentCode;
  if (resourceType == 'playlist') return _playlistCommentCode;
  return _songCommentCode;
}

List<Map<String, Object?>> _objectList(Object? value) {
  final result = <Map<String, Object?>>[];
  if (value is! Iterable<Object?>) return result;
  for (final item in value) {
    final object = stringObjectMap(item);
    if (object.isNotEmpty) result.add(object);
  }
  return result;
}

({String? id, String? name}) _extractResolvedResource(
  KugouResponse<Object?> response,
) {
  final body = stringObjectMap(response.body);
  final list = _objectList(body['list']);
  final first = list.isEmpty ? <String, Object?>{} : list.first;
  final rawId = firstValue(<Object?>[
    body['childrenid'],
    first['special_child_id'],
  ]);
  final rawName = firstValue(<Object?>[
    first['special_child_name'],
    first['song_show_text'],
  ]);
  return (
    id: rawId == null ? null : jsString(rawId),
    name: rawName == null ? null : jsString(rawName),
  );
}

Future<KugouResponse<Object?>> _commentAlbumLookup(
  KugouEndpointContext context,
  Map<String, Object?> params,
  Object albumId,
) => context.request(
  KugouRequest(
    path: '/m.comment.service/v1/cmtlist',
    method: 'POST',
    parameters: <String, Object?>{
      'childrenid': albumId,
      'need_show_image': 1,
      'p': jsOr(params['page'], 1),
      'pagesize': jsOr(params['pagesize'], 30),
      'show_classify': jsOr(params['show_classify'], 1),
      'show_hotword_list': jsOr(params['show_hotword_list'], 1),
      'code': _albumCommentCode,
    },
    cookies: stringStringMap(params['cookie']),
  ),
);

Future<KugouResponse<Object?>> _commentPlaylistLookup(
  KugouEndpointContext context,
  Map<String, Object?> params,
  Object playlistId,
) => context.request(
  KugouRequest(
    path: '/m.comment.service/v1/cmtlist',
    method: 'POST',
    parameters: <String, Object?>{
      'childrenid': playlistId,
      'need_show_image': 1,
      'p': jsOr(params['page'], 1),
      'pagesize': jsOr(params['pagesize'], 30),
      'show_classify': jsOr(params['show_classify'], 1),
      'show_hotword_list': jsOr(params['show_hotword_list'], 1),
      'code': _playlistCommentCode,
      'content_type': 0,
      'tag': 5,
    },
    cookies: stringStringMap(params['cookie']),
  ),
);

Future<KugouResponse<Object?>> _commentMusicLookup(
  KugouEndpointContext context,
  Map<String, Object?> params,
  Object mixsongid,
) => context.request(
  KugouRequest(
    path: '/mcomment/v1/cmtlist',
    method: 'POST',
    parameters: <String, Object?>{
      'ver': jsOr(params['ver'], 6),
      'mixsongid': mixsongid,
      'need_show_image': 1,
      'p': jsOr(params['page'], 1),
      'pagesize': jsOr(params['pagesize'], 30),
      'show_classify': jsOr(params['show_classify'], 1),
      'show_hotword_list': jsOr(params['show_hotword_list'], 1),
      'extdata': '0',
      'code': _songCommentCode,
    },
    cookies: stringStringMap(params['cookie']),
  ),
);

Future<KugouResponse<Object?>> _commentAlbumSend(
  KugouEndpointContext context,
  Map<String, Object?> params,
) async {
  if (jsString(params['content']).trim().isEmpty) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'content 不能为空',
      },
    );
  }
  final albumId = firstValue(<Object?>[
    params['album_id'],
    params['special_id'],
    params['childrenid'],
    params['id'],
  ]);
  if (albumId == null) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'id 不能为空',
      },
    );
  }
  var name = firstValue(<Object?>[
    params['name'],
    params['album_name'],
    params['childrenname'],
  ]);
  if (name == null) {
    final lookup = await _commentAlbumLookup(context, <String, Object?>{
      ...params,
      'id': albumId,
      'page': 1,
      'pagesize': 1,
    }, albumId);
    name = _extractResolvedResource(lookup).name;
  }
  final payload = _commentSendQuery(context, <String, Object?>{
    ...params,
    'special_id': albumId,
    'name': name,
  }, _albumCommentCode);
  return context.request(
    _commentRequest(
      context,
      params,
      payload.query,
      method: 'POST',
      data: payload.data,
    ),
  );
}

Future<KugouResponse<Object?>> _commentPlaylistSend(
  KugouEndpointContext context,
  Map<String, Object?> params,
) async {
  if (jsString(params['content']).trim().isEmpty) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'content 不能为空',
      },
    );
  }
  final playlistId = firstValue(<Object?>[
    params['playlist_id'],
    params['special_id'],
    params['childrenid'],
    params['id'],
  ]);
  if (playlistId == null) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'id 不能为空',
      },
    );
  }
  var name = firstValue(<Object?>[
    params['name'],
    params['playlist_name'],
    params['childrenname'],
  ]);
  if (name == null) {
    final lookup = await _commentPlaylistLookup(context, <String, Object?>{
      ...params,
      'id': playlistId,
      'page': 1,
      'pagesize': 1,
    }, playlistId);
    name = _extractResolvedResource(lookup).name;
  }
  final payload = _commentSendQuery(context, <String, Object?>{
    ...params,
    'special_id': playlistId,
    'name': name,
  }, _playlistCommentCode);
  return context.request(
    _commentRequest(
      context,
      params,
      payload.query,
      method: 'POST',
      data: payload.data,
    ),
  );
}

Future<KugouResponse<Object?>> _commentMusicSend(
  KugouEndpointContext context,
  Map<String, Object?> params,
) async {
  if (jsString(params['content']).trim().isEmpty) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'content 不能为空',
      },
    );
  }
  final mixsongid = firstValue(<Object?>[
    params['mixsongid'],
    params['album_audio_id'],
  ]);
  var specialId = firstValue(<Object?>[
    params['special_id'],
    params['childrenid'],
    params['id'],
  ]);
  var name = firstValue(<Object?>[
    params['name'],
    params['song_name'],
    params['childrenname'],
  ]);
  if ((specialId == null || name == null) && mixsongid != null) {
    final lookup = await _commentMusicLookup(context, <String, Object?>{
      ...params,
      'mixsongid': mixsongid,
      'page': 1,
      'pagesize': 1,
    }, mixsongid);
    final resolved = _extractResolvedResource(lookup);
    specialId ??= resolved.id;
    name ??= resolved.name;
  }
  if (specialId == null) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': '无法解析歌曲评论 special_id，请传入 mixsongid 或 special_id',
      },
    );
  }
  final payload = _commentSendQuery(context, <String, Object?>{
    ...params,
    'special_id': specialId,
    'mixsongid': mixsongid,
    'name': name,
  }, _songCommentCode);
  return context.request(
    _commentRequest(
      context,
      params,
      payload.query,
      method: 'POST',
      data: payload.data,
    ),
  );
}

Future<KugouResponse<Object?>> _commentFloorSend(
  KugouEndpointContext context,
  Map<String, Object?> params,
) async {
  if (jsString(params['content']).trim().isEmpty) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'content 不能为空',
      },
    );
  }
  final specialId = firstValue(<Object?>[
    params['special_id'],
    params['childrenid'],
    params['id'],
  ]);
  if (specialId == null) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'special_id 不能为空',
      },
    );
  }
  if (firstValue(<Object?>[params['tid']]) == null) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'tid 不能为空',
      },
    );
  }
  final code = _resolveCommentCode(params);
  var name = firstValue(<Object?>[
    params['name'],
    params['song_name'],
    params['album_name'],
    params['playlist_name'],
    params['childrenname'],
  ]);
  if (name == null) {
    final lookup = await context.request(
      _commentFloorLookupRequest(context, <String, Object?>{
        ...params,
        'special_id': specialId,
        'code': code,
        'page': 1,
        'pagesize': 1,
      }, code),
    );
    name = _extractResolvedResource(lookup).name;
  }
  final query = _commentReplyQuery(context, <String, Object?>{
    ...params,
    'special_id': specialId,
    'name': name,
  }, code);
  return context.request(
    _commentRequest(context, params, query, method: 'POST'),
  );
}

KugouRequest _commentFloorLookupRequest(
  KugouEndpointContext context,
  Map<String, Object?> params,
  String code,
) {
  final resourceType = jsString(
    firstValue(<Object?>[params['resource_type'], params['resourceType'], '']),
  ).toLowerCase();
  final serviceEndpoint =
      resourceType == 'playlist' ||
      resourceType == 'album' ||
      code == _playlistCommentCode ||
      code == _albumCommentCode;
  final mixSongId = jsString(params['mixsongid']).trim();
  return KugouRequest(
    path: serviceEndpoint
        ? '/m.comment.service/v1/hot_replylist'
        : '/mcomment/v1/hot_replylist',
    method: 'POST',
    parameters: <String, Object?>{
      'childrenid': params['special_id'],
      'need_show_image': 1,
      'p': jsOr(params['page'], 1),
      'pagesize': jsOr(params['pagesize'], 30),
      'show_classify': params['show_classify'] ?? 1,
      'show_hotword_list': params['show_hotword_list'] ?? 1,
      'code': code,
      'tid': params['tid'],
      if (mixSongId.isNotEmpty &&
          mixSongId != 'null' &&
          mixSongId != 'undefined')
        'mixsongid': params['mixsongid'],
    },
    cookies: stringStringMap(params['cookie']),
  );
}

Future<KugouResponse<Object?>> _commentMusicDel(
  KugouEndpointContext context,
  Map<String, Object?> params,
) async {
  final cid = firstValue(<Object?>[params['cid'], params['comment_id']]);
  if (cid == null) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'cid（评论 ID）不能为空，可从评论列表接口获取',
      },
    );
  }
  final mixsongid = firstValue(<Object?>[
    params['mixsongid'],
    params['album_audio_id'],
  ]);
  var specialId = firstValue(<Object?>[
    params['special_id'],
    params['childrenid'],
  ]);
  if (specialId == null && mixsongid != null) {
    final lookup = await _commentMusicLookup(context, <String, Object?>{
      ...params,
      'mixsongid': mixsongid,
      'page': 1,
      'pagesize': 1,
    }, mixsongid);
    specialId = _extractResolvedResource(lookup).id;
  }
  if (specialId == null) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': '无法解析评论资源 special_id，请传入 special_id 或 mixsongid',
      },
    );
  }
  final query = _commentDelQuery(context, <String, Object?>{
    ...params,
    'special_id': specialId,
    'cid': cid,
  }, _resolveCommentCode(params));
  return context.request(_commentRequest(context, params, query));
}

Future<KugouResponse<Object?>> _songBarrage(
  KugouEndpointContext context,
  Map<String, Object?> params,
) {
  final specialId = firstValue(<Object?>[
    params['special_id'],
    params['childrenid'],
    params['id'],
  ]);
  final hash = firstValue(<Object?>[
    params['hash'],
    params['schash'],
    params['extdata'],
  ]);
  if (specialId == null && hash == null) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        status: 400,
        httpStatus: 400,
        body: const <String, Object?>{
          'status': 0,
          'error_code': 400,
          'msg': 'special_id 和 hash 至少需要传入一个',
        },
      ),
    );
  }
  return context.request(
    _commentRequest(
      context,
      params,
      _buildSongBarrageListQuery(context, params),
    ),
  );
}

Future<KugouResponse<Object?>> _videoBarrage(
  KugouEndpointContext context,
  Map<String, Object?> params,
) {
  final videoId = firstValue(<Object?>[
    params['video_id'],
    params['childrenid'],
    params['id'],
  ]);
  final hash = firstValue(<Object?>[
    params['hash'],
    params['mvhash'],
    params['extdata'],
  ]);
  if (videoId == null && hash == null) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        status: 400,
        httpStatus: 400,
        body: const <String, Object?>{
          'status': 0,
          'error_code': 400,
          'msg': 'video_id 和 hash 至少需要传入一个',
        },
      ),
    );
  }
  return context.request(
    _commentRequest(
      context,
      params,
      _buildVideoBarrageListQuery(context, params),
    ),
  );
}

Future<KugouResponse<Object?>> _songBarrageSend(
  KugouEndpointContext context,
  Map<String, Object?> params,
) async {
  if (jsString(params['content']).trim().isEmpty) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'content 不能为空',
      },
    );
  }
  var specialId = firstValue(<Object?>[
    params['special_id'],
    params['childrenid'],
    params['id'],
  ]);
  var name = firstValue(<Object?>[
    params['name'],
    params['song_name'],
    params['childrenname'],
  ]);
  if (specialId == null) {
    final hash = firstValue(<Object?>[
      params['hash'],
      params['schash'],
      params['extdata'],
    ]);
    if (hash == null) {
      return rejectEndpoint(
        context,
        status: 400,
        httpStatus: 400,
        body: const <String, Object?>{
          'status': 0,
          'error_code': 400,
          'msg': 'special_id 和 hash 至少需要传入一个',
        },
      );
    }
    final lookup = await context.request(
      _commentRequest(
        context,
        params,
        _buildSongBarrageListQuery(context, <String, Object?>{
          ...params,
          'page': 1,
          'pagesize': 1,
        }),
      ),
    );
    final resolved = _extractResolvedResource(lookup);
    specialId = resolved.id;
    name ??= resolved.name;
  }
  if (specialId == null) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': '无法根据 hash 解析歌曲弹幕 special_id',
      },
    );
  }
  final payload = _commentSendQuery(context, <String, Object?>{
    ...params,
    'special_id': specialId,
    'name': name,
  }, _songBarrageCode);
  return context.request(
    _commentRequest(
      context,
      params,
      payload.query,
      method: 'POST',
      data: payload.data,
    ),
  );
}

Future<KugouResponse<Object?>> _videoBarrageSend(
  KugouEndpointContext context,
  Map<String, Object?> params,
) async {
  if (jsString(params['content']).trim().isEmpty) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': 'content 不能为空',
      },
    );
  }
  var videoId = firstValue(<Object?>[
    params['video_id'],
    params['childrenid'],
    params['id'],
  ]);
  var name = firstValue(<Object?>[
    params['name'],
    params['video_name'],
    params['childrenname'],
  ]);
  if (videoId == null) {
    final hash = firstValue(<Object?>[
      params['hash'],
      params['mvhash'],
      params['extdata'],
    ]);
    if (hash == null) {
      return rejectEndpoint(
        context,
        status: 400,
        httpStatus: 400,
        body: const <String, Object?>{
          'status': 0,
          'error_code': 400,
          'msg': 'video_id 和 hash 至少需要传入一个',
        },
      );
    }
    final lookup = await context.request(
      _commentRequest(
        context,
        params,
        _buildVideoBarrageListQuery(context, <String, Object?>{
          ...params,
          'page': 1,
          'pagesize': 1,
        }),
      ),
    );
    final resolved = _extractResolvedResource(lookup);
    videoId = resolved.id;
    name ??= resolved.name;
  }
  if (videoId == null) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{
        'status': 0,
        'error_code': 400,
        'msg': '无法根据 hash 解析视频弹幕 video_id',
      },
    );
  }
  return context.request(
    _commentRequest(
      context,
      params,
      _videoBarrageSendQuery(context, <String, Object?>{
        ...params,
        'video_id': videoId,
        'name': name,
      }),
    ),
  );
}
