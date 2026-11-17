import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';
import '../signatures.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createManualEndpointHandlers() =>
    <String, KugouEndpointHandler>{
      '/audio/accompany/matching': _audioAccompanyMatching,
      '/audio/ktv/total': _audioKtvTotal,
      '/audio/related': _audioRelated,
      '/comment/count': _commentCount,
      '/comment/floor': _commentFloor,
      '/fm/songs': _fmSongs,
      '/images': _images,
      '/images/audio': _imagesAudio,
      '/playlist/tracks/add': _playlistTracksAdd,
      '/privilege/lite': _privilegeLite,
    };

Future<KugouResponse<Object?>> _audioAccompanyMatching(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final parameters = <String, Object?>{
    'isteen': 0,
    'mixId': jsNumber(input['mixId']).toInt(),
    'usemkv': 1,
    'platform': 2,
    'fileName': jsOr(input['fileName'], ''),
    'hash': input['hash'],
    'version': 12375,
    'appid': context.config.appId,
  };
  parameters['sign'] = _singSign(parameters);
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://nsongacsing.kugou.com'),
      path:
          '/sing7/accompanywan/json/v2/cdn/'
          'optimal_matching_accompany_2_listen.do',
      parameters: parameters,
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );
}

Future<KugouResponse<Object?>> _audioKtvTotal(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final parameters = <String, Object?>{
    'isteen': 0,
    'songId': jsNumber(input['songId']).toInt(),
    'usemkv': 1,
    'platform': 2,
    'singerName': input['singerName'],
    'songHash': input['songHash'],
    'version': 12375,
    'appid': context.config.appId,
  };
  parameters['sign'] = _singSign(parameters);
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://acsing.service.kugou.com'),
      path:
          '/sing7/listenguide/json/v2/cdn/listenguide/'
          'get_total_opus_num_v02.do',
      parameters: parameters,
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );
}

String _singSign(Map<String, Object?> parameters) {
  final keys = parameters.keys.toList()..sort();
  final source = keys
      .map((key) {
        final value = parameters[key];
        final serialized =
            value is Map<Object?, Object?> || value is Iterable<Object?>
            ? jsJsonEncode(value)
            : jsString(value);
        return '$key=$serialized';
      })
      .join('&');
  return md5Hex('$source*s&iN#G70*').substring(8, 24);
}

Future<KugouResponse<Object?>> _audioRelated(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  const sortTypes = <String, int>{'all': 1, 'hot': 2, 'new': 3};
  final showDetail = jsNumber(input['show_detail']) == 0;
  final parameters = <String, Object?>{
    'album_audio_id': jsNumber(input['album_audio_id']).toInt(),
    'appid': 1005,
    'area_code': 1,
    'clientver': 12329,
    if (!showDetail) ...<String, Object?>{
      'page': jsOr(input['page'], 1),
      'pagesize': jsOr(input['pagesize'], 30),
      'show_input': 1,
      'show_type': jsOr(input['show_type'], 0),
      'sort': sortTypes[input['sort']] ?? 1,
      'type': jsOr(input['type'], 0),
    },
    'version': 1,
  };
  parameters['signature'] = context.signatures.androidStandard(parameters);
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://listkmrp3cdnretry.kugou.com'),
      path: showDetail ? '/v2/audio_related/total' : '/v3/album_audio/related',
      parameters: parameters,
      clearDefaultParameters: true,
    ),
  );
}

Future<KugouResponse<Object?>> _commentCount(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final parameters = <String, Object?>{
    'r': 'comments/getcommentsnum',
    'code': 'fc4be23b4e972707f36b8a828a93ba8a',
    if (jsTruthy(input['hash']))
      'hash': input['hash']
    else if (jsTruthy(input['special_id']))
      'childrenid': input['special_id'],
  };
  return context.request(
    KugouRequest(
      path: '/index.php',
      parameters: parameters,
      signatureType: KugouSignatureType.web,
      headers: const <String, Object?>{
        'x-router': 'sum.comment.service.kugou.com',
      },
    ),
  );
}

Future<KugouResponse<Object?>> _commentFloor(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  const songCode = 'fc4be23b4e972707f36b8a828a93ba8a';
  const playlistCode = 'ca53b96fe5a1d9c22d71c8f522ef7c4f';
  const albumCode = '94f1792ced1df89aa68a7939eaf2efca';
  final resourceType = jsString(
    jsOr(jsOr(input['resource_type'], input['resourceType']), ''),
  ).toLowerCase();
  final suppliedCode = jsString(input['code']).trim();
  final hasCode =
      suppliedCode.isNotEmpty &&
      suppliedCode != 'null' &&
      suppliedCode != 'undefined';
  final code = hasCode
      ? suppliedCode
      : resourceType == 'playlist'
      ? playlistCode
      : resourceType == 'album'
      ? albumCode
      : songCode;
  final serviceEndpoint =
      resourceType == 'playlist' ||
      resourceType == 'album' ||
      code == playlistCode ||
      code == albumCode;
  final mixSongId = jsString(input['mixsongid']).trim();
  final parameters = <String, Object?>{
    'childrenid': input['special_id'],
    'need_show_image': 1,
    'p': jsOr(input['page'], 1),
    'pagesize': jsOr(input['pagesize'], 30),
    'show_classify': input['show_classify'] ?? 1,
    'show_hotword_list': input['show_hotword_list'] ?? 1,
    'code': code,
    'tid': input['tid'],
    if (mixSongId.isNotEmpty && mixSongId != 'null' && mixSongId != 'undefined')
      'mixsongid': input['mixsongid'],
  };
  return context.request(
    KugouRequest(
      path: serviceEndpoint
          ? '/m.comment.service/v1/hot_replylist'
          : '/mcomment/v1/hot_replylist',
      method: 'POST',
      parameters: parameters,
    ),
  );
}

Future<KugouResponse<Object?>> _fmSongs(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final ids = jsString(jsOr(input['fmid'], '')).split(',');
  final types = jsString(jsOr(input['fmtype'], '')).split(',');
  final offsets = jsString(jsOr(input['fmoffset'], '')).split(',');
  final sizes = jsString(jsOr(input['fmsize'], '')).split(',');
  final data = <Object?>[
    for (var index = 0; index < ids.length; index++)
      <String, Object?>{
        'fmid': ids[index],
        'fmtype': index < types.length && types[index].isNotEmpty
            ? types[index]
            : jsOr(input['type'], 2),
        'offset': index < offsets.length && offsets[index].isNotEmpty
            ? offsets[index]
            : jsOr(input['offset'], -1),
        'size': index < sizes.length && sizes[index].isNotEmpty
            ? sizes[index]
            : jsOr(input['size'], 20),
        'singername': '',
      },
  ];
  final now = context.nowMilliseconds;
  final body = <String, Object?>{
    'appid': context.config.appId,
    'area_code': 1,
    'clienttime': now,
    'clientver': context.config.clientVersion,
    'data': data,
    'get_tracker': 1,
    'key': context.signatures.parametersKey(now),
    'mid': endpointCookie(context, input, 'KUGOU_API_MID'),
    'uid': endpointCookie(context, input, 'userid') ?? input['userid'],
  };
  return context.request(
    KugouRequest(
      path: '/v1/app_song_list_offset',
      method: 'POST',
      data: body,
      headers: const <String, Object?>{
        'x-router': 'fm.service.kugou.com',
        'Content-Type': 'application/json',
      },
    ),
  );
}

Future<KugouResponse<Object?>> _images(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => _imageRequest(context, input, audio: false);

Future<KugouResponse<Object?>> _imagesAudio(
  KugouEndpointContext context,
  Map<String, Object?> input,
) => _imageRequest(context, input, audio: true);

Future<KugouResponse<Object?>> _imageRequest(
  KugouEndpointContext context,
  Map<String, Object?> input, {
  required bool audio,
}) {
  final hashes = jsString(jsOr(input['hash'], '')).split(',');
  final firstIds = jsString(
    jsOr(input[audio ? 'audio_id' : 'album_id'], ''),
  ).split(',');
  final albumAudioIds = jsString(jsOr(input['album_audio_id'], '')).split(',');
  final filenames = jsString(jsOr(input['filename'], '')).split(',');
  final data = <Object?>[
    for (var index = 0; index < hashes.length; index++)
      <String, Object?>{
        if (audio) 'audio_id': _listValue(firstIds, index, 0),
        if (!audio) 'album_id': _listValue(firstIds, index, 0),
        'hash': hashes[index],
        'album_audio_id': _listValue(albumAudioIds, index, 0),
        if (audio) 'filename': _listValue(filenames, index, ''),
      },
  ];
  final parameters = <String, Object?>{
    if (!audio) 'album_image_type': '-3',
    'appid': context.config.appId,
    'clientver': context.config.clientVersion,
    if (!audio) 'author_image_type': '3,4,5',
    'count': jsOr(input['count'], 5),
    'data': data,
    'isCdn': 1,
    'publish_time': 1,
    if (audio) 'show_authors': 1,
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
      baseUri: Uri.parse('https://expendablekmr.kugou.com'),
      path:
          '${audio ? '/v2/author_image/audio' : '/container/v2/image'}?$query',
      parameters: <String, Object?>{
        'signature': context.signatures.android(parameters),
      },
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );
}

Object? _listValue(List<String> values, int index, Object? fallback) =>
    index < values.length && values[index].isNotEmpty
    ? values[index]
    : fallback;

Future<KugouResponse<Object?>> _playlistTracksAdd(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final userId =
      input['userid'] ?? endpointCookie(context, input, 'userid') ?? 0;
  final token = input['token'] ?? endpointCookie(context, input, 'token') ?? '';
  final resources = jsString(jsOr(input['data'], ''))
      .split(',')
      .map<Object?>((item) {
        final fields = item.split('|');
        String field(int index) => index < fields.length ? fields[index] : '';
        return <String, Object?>{
          'number': 1,
          'name': field(0),
          'hash': field(1),
          'size': 0,
          'sort': 0,
          'timelen': 0,
          'bitrate': 0,
          'album_id': jsNumber(field(2)).toInt(),
          'mixsongid': jsNumber(field(3)).toInt(),
        };
      })
      .toList(growable: false);
  return context.request(
    KugouRequest(
      path: '/cloudlist.service/v6/add_song',
      method: 'POST',
      parameters: <String, Object?>{
        'last_time': context.nowSeconds,
        'last_area': 'gztx',
        'userid': userId,
        'token': token,
      },
      data: <String, Object?>{
        'userid': userId,
        'token': token,
        'listid': input['listid'],
        'list_ver': 0,
        'type': 0,
        'slow_upload': 1,
        'scene': 'false;null',
        'data': resources,
      },
    ),
  );
}

Future<KugouResponse<Object?>> _privilegeLite(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final hashes = jsString(jsOr(input['hash'], ''))
      .split(',')
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  if (hashes.isEmpty) {
    return rejectEndpoint(
      context,
      body: const <String, Object?>{
        'status': 0,
        'error_code': -1,
        'error': '缺少歌曲 hash',
      },
    );
  }

  final albumIds = jsString(jsOr(input['album_id'], '')).split(',');
  final albumAudioIds = jsString(jsOr(input['album_audio_id'], '')).split(',');
  final resource = <Object?>[
    for (var index = 0; index < hashes.length; index++)
      <String, Object?>{
        'type': 'audio',
        'page_id': 0,
        'hash': hashes[index],
        'album_id': _listValue(albumIds, index, 0),
      },
  ];
  final qualitiesParam = jsString(
    jsOr(input['qualities'], ''),
  ).trim().toLowerCase();
  final qualities = qualitiesParam == 'all'
      ? const <String>[
          '128',
          '320',
          'flac',
          'high',
          'viper_atmos',
          'viper_tape',
          'viper_clear',
          'super',
          'multitrack',
        ]
      : (qualitiesParam.isEmpty
                ? '128,320,flac,high,viper_tape,viper_clear,viper_atmos'
                : qualitiesParam)
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);

  final response = await context.request(
    KugouRequest(
      path: '/v2/get_res_privilege/lite',
      method: 'POST',
      data: <String, Object?>{
        'appid': context.config.appId,
        'area_code': 1,
        'behavior': 'play',
        'clientver': context.config.clientVersion,
        'need_hash_offset': 1,
        'relate': 1,
        'support_verify': 1,
        'resource': resource,
        'qualities': const <String>[
          '128',
          '320',
          'flac',
          'high',
          'viper_atmos',
          'viper_tape',
          'viper_clear',
          'super',
          'multitrack',
        ],
      },
      headers: const <String, Object?>{
        'x-router': 'media.store.kugou.com',
        'Content-Type': 'application/json',
      },
    ),
  );
  final body = Map<String, Object?>.from(stringObjectMap(response.body));
  final data = asObjectList(body['data']);
  final qualityVip = <Object?>[
    for (var index = 0; index < hashes.length; index++)
      _buildQualityVip(
        hashes[index],
        resource[index] as Map<String, Object?>,
        _listValue(albumAudioIds, index, null),
        _findPrivilegeItem(data, hashes[index], index),
        qualities,
        context.config.isLite,
      ),
  ];
  body['quality_vip'] = qualityVip;
  return KugouResponse<Object?>(
    status: response.status,
    httpStatus: response.httpStatus,
    body: body,
    cookies: response.cookies,
    headers: response.headers,
  );
}

const List<String> _qualityOrder = <String>[
  '128',
  '320',
  'flac',
  'high',
  'super',
  'viper_clear',
  'viper_tape',
  'viper_atmos',
  'multitrack',
];

const Map<String, String> _qualityVipType = <String, String>{
  'viper_tape': 'suvip',
  'viper_clear': 'suvip',
  'viper_atmos': 'suvip',
};

const Map<String, List<int>> _qualityLevel = <String, List<int>>{
  '128': <int>[1, 2],
  '320': <int>[4],
  'flac': <int>[5],
  'high': <int>[6],
  'super': <int>[7],
};

Map<String, Object?> _findPrivilegeItem(
  List<Map<String, Object?>> data,
  String hash,
  int index,
) {
  for (final item in data) {
    if (jsString(item['hash']).toLowerCase() == hash) return item;
  }
  return index < data.length ? data[index] : <String, Object?>{};
}

Map<String, Object?> _buildQualityVip(
  String hash,
  Map<String, Object?> resource,
  Object? albumAudioId,
  Map<String, Object?> upstream,
  List<String> qualities,
  bool isLite,
) {
  final relateGoods = asObjectList(upstream['relate_goods']);
  final transParam = stringObjectMap(resource['trans_param']);
  final list = <Map<String, Object?>>[
    for (final quality in qualities)
      _buildQualityEntry(quality, relateGoods, transParam, isLite),
  ];
  final free =
      list.where((item) => jsTruthy(item['obtainable'])).toList(growable: false)
        ..sort((left, right) {
          final level = jsNumber(
            left['level'],
          ).toInt().compareTo(jsNumber(right['level']).toInt());
          if (level != 0) return level;
          return _qualityOrder
              .indexOf(jsString(left['quality']))
              .compareTo(_qualityOrder.indexOf(jsString(right['quality'])));
        });
  final bestFree = free.isEmpty ? null : free.last;
  final freeQualities = list
      .where((item) => jsTruthy(item['obtainable']))
      .map((item) => item['quality'])
      .toList(growable: false);
  final vipQualities = list
      .where(
        (item) =>
            jsTruthy(item['exists']) &&
            jsTruthy(item['need_vip']) &&
            !jsTruthy(item['obtainable']),
      )
      .map((item) => item['quality'])
      .toList(growable: false);
  final superVipQualities = list
      .where((item) => jsString(item['require_vip_type']) == 'suvip')
      .map((item) => item['quality'])
      .toList(growable: false);
  final blockedQualities = list
      .where(
        (item) =>
            jsTruthy(item['exists']) &&
            !jsTruthy(item['obtainable']) &&
            !jsTruthy(item['need_vip']),
      )
      .map((item) => item['quality'])
      .toList(growable: false);
  final missingQualities = list
      .where((item) => !jsTruthy(item['exists']))
      .map((item) => item['quality'])
      .toList(growable: false);
  final freeSong =
      list.isNotEmpty && list.every((item) => !jsTruthy(item['need_vip']));
  return <String, Object?>{
    'hash': hash,
    'album_id': jsString(
      jsOr(resource['album_id'], jsOr(upstream['album_id'], '')),
    ),
    'album_audio_id': jsString(
      jsOr(upstream['album_audio_id'], jsOr(albumAudioId, '')),
    ),
    'name': upstream['name'] ?? '',
    'singername': upstream['singername'] ?? '',
    'albumname': upstream['albumname'] ?? '',
    'free_song': freeSong,
    'free_listen': list.any((item) => jsTruthy(item['free_listen'])),
    'qualities': list,
    'free_qualities': freeQualities,
    'vip_qualities': vipQualities,
    'super_vip_qualities': superVipQualities,
    'blocked_qualities': blockedQualities,
    'missing_qualities': missingQualities,
    'best_free_quality': bestFree?['quality'] ?? '',
  };
}

Map<String, Object?> _buildQualityEntry(
  String quality,
  List<Map<String, Object?>> relateGoods,
  Map<String, Object?> transParam,
  bool isLite,
) {
  Map<String, Object?>? relateItem;
  for (final level in _qualityLevel[quality] ?? const <int>[]) {
    for (final item in relateGoods) {
      if (jsNumber(item['level']).toInt() == level &&
          jsString(item['quality']) == quality) {
        relateItem = item;
        break;
      }
    }
    if (relateItem != null) break;
  }
  if (relateItem == null) {
    for (final item in relateGoods) {
      if (jsString(item['quality']) == quality) {
        relateItem = item;
        break;
      }
    }
  }
  final exists = relateItem != null;
  final privilege = relateItem?['privilege'] ?? -1;
  final needVip = exists && privilege != 0;
  final freeListen = isLite && quality == '128' && needVip;
  final status = relateItem?['status'] ?? 0;
  final obtainable = freeListen || (exists && !needVip && status != 0);
  final info = stringObjectMap(relateItem?['info']);
  final oggHash = quality == '128'
      ? transParam['ogg_128_hash']
      : quality == '320'
      ? transParam['ogg_320_hash']
      : null;
  final oggSize = quality == '128'
      ? transParam['ogg_128_filesize']
      : quality == '320'
      ? transParam['ogg_320_filesize']
      : null;
  final size = exists ? jsNumber(jsOr(oggSize, info['filesize'])).toInt() : 0;
  final extname = exists
      ? (jsTruthy(oggHash) ? 'ogg' : jsString(info['extname']))
      : '';
  final hash = exists
      ? (jsTruthy(oggHash) ? jsString(oggHash) : jsString(relateItem['hash']))
      : '';
  return <String, Object?>{
    'quality': quality,
    'exists': exists,
    'level': relateItem?['level'] ?? 0,
    'bitrate': info['bitrate'] ?? 0,
    'extname': extname,
    'hash': hash,
    'size': size,
    'size_text': _formatPrivilegeSize(size),
    'privilege': privilege,
    'status': status,
    'pay_type': relateItem?['pay_type'] ?? -1,
    'price': relateItem?['price'] ?? 0,
    'fail_process': relateItem?['fail_process'] ?? 0,
    'need_vip': needVip,
    'obtainable': obtainable,
    'free_listen': freeListen,
    'require_vip_type': exists && !obtainable && needVip
        ? _qualityVipType[quality] ?? 'concept'
        : '',
    'msg': relateItem?['_msg'] ?? '',
  };
}

String _formatPrivilegeSize(int bytes) {
  if (bytes <= 0) return '';
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)}G';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)}M';
  }
  return '${(bytes / 1024).toStringAsFixed(1)}K';
}

List<Map<String, Object?>> asObjectList(Object? value) {
  final result = <Map<String, Object?>>[];
  if (value is! Iterable<Object?>) return result;
  for (final item in value) {
    final object = stringObjectMap(item);
    if (object.isNotEmpty) result.add(object);
  }
  return result;
}
