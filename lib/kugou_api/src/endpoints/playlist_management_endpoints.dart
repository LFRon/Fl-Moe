import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../cloud_request.dart';
import '../endpoint.dart';
import '../models.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createPlaylistManagementHandlers() =>
    <String, KugouEndpointHandler>{
      '/import/playlist': _importPlaylist,
      '/playlist/pic': _playlistPic,
      '/playlist/pic/upload': _playlistPicUpload,
      '/playlist/share/official': _playlistShareOfficial,
      '/playlist/sort': _playlistSort,
      '/playlist/tracks/sort': _playlistTracksSort,
      '/playlist/update': _playlistUpdate,
    };

Future<KugouResponse<Object?>> _playlistPic(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final resource = <Object?>[];
  for (final entry in jsString(input['data']).split(',')) {
    final fields = entry.split('|');
    final pic = fields.length > 2 ? fields[2] : '';
    final normalized = pic.startsWith('stdmusic/')
        ? pic
        : 'stdmusic/${pic.split('/').last}';
    resource.add(<String, Object?>{
      'listid': jsNumber(fields.isEmpty ? '' : fields[0]).toInt(),
      'type': jsNumber(fields.length > 1 ? fields[1] : 0).toInt(),
      'pic': normalized,
    });
  }
  return createCloudRequest(
    context,
    path: '/v1/modify_list_pic',
    data: <String, Object?>{
      'total_ver': jsNumber(input['total_ver']).toInt(),
      'data': resource,
    },
    cookies: stringObjectMap(input['cookie']),
  );
}

Future<KugouResponse<Object?>> _playlistSort(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final resource = <Object?>[];
  for (final entry in jsString(input['data']).split(',')) {
    final fields = entry.split('|');
    resource.add(<String, Object?>{
      'listid': jsNumber(fields.isEmpty ? '' : fields[0]).toInt(),
      'type': jsNumber(fields.length > 1 ? fields[1] : 0).toInt(),
      'sort': jsNumber(fields.length > 2 ? fields[2] : 0).toInt(),
    });
  }
  return createCloudRequest(
    context,
    path: '/v1/modify_list_sort',
    data: <String, Object?>{
      'total_ver': jsNumber(input['total_ver']).toInt(),
      'data': resource,
    },
    cookies: stringObjectMap(input['cookie']),
  );
}

Future<KugouResponse<Object?>> _playlistTracksSort(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final resource = <Object?>[];
  for (final entry in jsString(input['data']).split(',')) {
    final fields = entry.split('|');
    resource.add(<String, Object?>{
      'fileid': jsNumber(fields.isEmpty ? '' : fields[0]).toInt(),
      'sort': jsNumber(fields.length > 1 ? fields[1] : 0).toInt(),
    });
  }
  return createCloudRequest(
    context,
    path: '/v1/modify_song_sort',
    data: <String, Object?>{
      'listid': jsNumber(input['listid']).toInt(),
      'list_ver': jsNumber(input['list_ver']).toInt(),
      'type': jsNumber(input['type']).toInt(),
      'data': resource,
    },
    cookies: stringObjectMap(input['cookie']),
  );
}

Future<KugouResponse<Object?>> _playlistUpdate(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final data = <String, Object?>{
    'total_ver': jsNumber(input['total_ver']).toInt(),
    'listid': jsNumber(input['listid']).toInt(),
    'type': jsNumber(input['type']).toInt(),
    'sort': jsNumber(input['sort']).toInt(),
    'tags': jsOr(input['tags'], ''),
    'intro': jsOr(input['intro'], ''),
  };
  if (jsTruthy(input['name'])) data['name'] = input['name'];
  if (jsTruthy(input['pic'])) data['pic'] = input['pic'];
  return createCloudRequest(
    context,
    path: '/v1/modify_list',
    data: data,
    cookies: stringObjectMap(input['cookie']),
  );
}

Future<KugouResponse<Object?>> _playlistPicUpload(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final image = await _readImage(input);
  if (image == null || !_isImage(image)) {
    return rejectEndpoint(
      context,
      status: 400,
      httpStatus: 400,
      body: const <String, Object?>{'status': 0, 'msg': '文件不存在或不是有效图片'},
    );
  }
  final now = DateTime.now();
  final date =
      '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('http://imgphp.kugou.com/imageupload'),
      path: '/stream.php',
      method: 'POST',
      parameters: <String, Object?>{
        'type': jsOr(input['type'], 'custom'),
        'extendName': jsOr(input['extendName'], '.jpg'),
        'md5': jsOr(input['md5'], md5Hex('${date}hewry678WEK23D')),
        'jsonResponse': 1,
      },
      data: image,
      headers: const <String, Object?>{
        'Content-Type': 'application/octet-stream',
      },
      clearDefaultParameters: true,
      clearDefaultHeaders: true,
      skipSignature: true,
    ),
  );
  final body = stringObjectMap(response.body);
  if (jsTruthy(body['IsSuccess'])) {
    return KugouResponse<Object?>(
      status: 200,
      httpStatus: 200,
      body: <String, Object?>{'status': 1, 'FileName': body['FileName']},
    );
  }
  return rejectEndpoint(
    context,
    body: <String, Object?>{'status': 0, 'msg': jsOr(body['Message'], '上传失败')},
  );
}

Future<Uint8List?> _readImage(Map<String, Object?> input) async {
  final data = input['data'];
  if (data is Uint8List) return data;
  if (data is List<int>) return Uint8List.fromList(data);
  final file = input['file'];
  if (file is! String || file.isEmpty) return null;
  final root = Platform.environment['KUGOU_API_UPLOAD_FILE_ROOT'];
  final resolved = File(file).absolute.path;
  if (root != null &&
      root.isNotEmpty &&
      !resolved.startsWith('$root${Platform.pathSeparator}')) {
    return null;
  }
  if (!RegExp(
    r'\.(jpe?g|png|gif|webp|bmp)$',
    caseSensitive: false,
  ).hasMatch(resolved)) {
    return null;
  }
  try {
    final stat = await File(resolved).stat();
    if (stat.type != FileSystemEntityType.file ||
        stat.size <= 0 ||
        stat.size > 10 * 1024 * 1024) {
      return null;
    }
    return await File(resolved).readAsBytes();
  } on FileSystemException {
    return null;
  }
}

bool _isImage(Uint8List bytes) {
  if (bytes.length < 12) return false;
  final head = bytes
      .sublist(0, 12)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return head.startsWith('89504e47') ||
      head.startsWith('ffd8ff') ||
      head.startsWith('47494638') ||
      head.startsWith('424d') ||
      (head.startsWith('52494646') &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP');
}

Future<KugouResponse<Object?>> _playlistShareOfficial(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final id = input['id'];
  if (id == null || id.toString().isEmpty) {
    return Future<KugouResponse<Object?>>.value(
      endpointFailure(
        status: 400,
        httpStatus: 400,
        body: const <String, Object?>{'status': 0, 'msg': '歌单id不得为空！请检查重试。'},
      ),
    );
  }
  final type = jsOr(input['type'], 1);
  final isType1 = jsNumber(type) == 1;
  final specialId = isType1 ? '-2147483648' : '0';
  final cType = isType1 ? '0' : '1';
  final uid = jsOr(
    endpointCookie(context, input, 'userid'),
    jsOr(input['userid'], 0),
  );
  final link =
      'https://activity.kugou.com/share/v-a00a45b0/index.html'
      '?u=$uid'
      '&h1=143298444507010930495471534764048014549'
      '&h2=406dd14b2efd5e51affd6da64c84d0f6'
      '&specialid=$specialId'
      '&global_specialid=$id'
      '&cType=$cType';
  final md5 = md5Hex('kgclientshare${md5Hex(link)}');
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('http://t.service.kugou.com/'),
      path: '/app',
      parameters: <String, Object?>{
        'caller': 'mlist',
        'url': link,
        'cmid': 5,
        'md5': md5,
      },
      headers: <String, Object?>{
        'User-Agent': 'Android9-1070-10597-18-0-Share-wifi',
        'KG-THash': Random.secure()
            .nextInt(0xfffffff)
            .toRadixString(16)
            .padLeft(7, '0'),
      },
      clearDefaultParameters: true,
      clearDefaultHeaders: true,
      skipSignature: true,
    ),
  );
}

Future<KugouResponse<Object?>> _importPlaylist(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final body = input['body'];
  final bodyMap = body is Map<Object?, Object?>
      ? stringObjectMap(body)
      : body is String
      ? stringObjectMap(_tryDecode(body))
      : const <String, Object?>{};
  final merged = <String, Object?>{...input, ...bodyMap};
  final userid = jsString(
    jsOr(merged['userid'], endpointCookie(context, merged, 'userid')),
  );
  final token = jsString(
    jsOr(merged['token'], endpointCookie(context, merged, 'token')),
  );
  final operation = merged['operation'];
  final isLite = context.config.isLite;
  final appId = isLite ? 3116 : 1005;
  final clientVer = isLite ? 11440 : 20489;
  final clienttime = context.nowSeconds;
  final query = <String, Object?>{
    'appid': '$appId',
    'clientver': '$clientVer',
    'clienttime': '$clienttime',
    'mid': jsString(
      jsOr(
        merged['mid'],
        jsOr(endpointCookie(context, merged, 'KUGOU_API_MID'), '-'),
      ),
    ),
    'uuid': jsString(
      jsOr(merged['uuid'], jsOr(endpointCookie(context, merged, 'uuid'), '-')),
    ),
    'dfid': jsString(
      jsOr(merged['dfid'], jsOr(endpointCookie(context, merged, 'dfid'), '-')),
    ),
  };
  Future<KugouResponse<Object?>> send(String path, Map<String, Object?> data) =>
      context.request(
        KugouRequest(
          baseUri: Uri.parse('https://gateway.kugou.com'),
          path: path,
          method: 'POST',
          parameters: query,
          data: data,
          headers: const <String, Object?>{
            'Content-Type': 'application/json;charset=utf-8',
          },
          clearDefaultParameters: true,
        ),
      );

  if (operation == 'add_task') {
    final taskType = jsNumber(merged['task_type']).toInt();
    final data = <String, Object?>{
      'userid': userid,
      'token': token,
      'source': jsNumber(jsOr(merged['source'], 3)).toInt(),
      'task_type': taskType,
    };
    if (taskType == 0) {
      data['url'] = jsString(jsOr(merged['url'], ''));
    } else {
      data['listid'] = jsNumber(merged['listid']).toInt();
      if (jsTruthy(merged['list_name'])) {
        data['list_name'] = jsString(merged['list_name']);
      }
      data['task_sn'] = jsString(
        jsOr(merged['task_sn'], '$userid${context.nowMilliseconds}'),
      );
    }
    return send('/assetservice/import/v1/add_task', data);
  }
  if (operation == 'submit_img') {
    final image = jsString(
      merged['img_base64'],
    ).replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '');
    return send('/assetservice/import/v1/submit_img', <String, Object?>{
      'userid': userid,
      'token': token,
      'img_base64': image,
      'task_sn': jsString(jsOr(merged['task_sn'], '')),
    });
  }
  if (operation == 'task_count') {
    return send('/assetservice/import/v1/task_count', <String, Object?>{
      'userid': userid,
      'token': token,
      'classify': jsNumber(jsOr(merged['classify'], 1)).toInt(),
    });
  }
  if (operation == 'query_task_status') {
    return send('/assetservice/import/v1/query_task_status', <String, Object?>{
      'userid': userid,
      'token': token,
      'ids': _parseIds(merged['ids']),
    });
  }
  if (operation == 'query_task') {
    return send('/pubsongs/v1/query_task', <String, Object?>{
      'userid': userid,
      'token': token,
      'listid': jsString(jsOr(merged['listid'], '')),
      'page': max(1, jsNumber(jsOr(merged['page'], 1)).toInt()),
      'pagesize': max(1, jsNumber(jsOr(merged['pagesize'], 30)).toInt()),
      'show_missed': jsNumber(jsOr(merged['show_missed'], 1)) != 0 ? 1 : 0,
    });
  }
  return rejectEndpoint(
    context,
    status: 400,
    httpStatus: 400,
    body: <String, Object?>{
      'status': 0,
      'error_code': 400,
      'error_msg': '不支持的操作: ${operation ?? ''}',
    },
  );
}

List<int> _parseIds(Object? value) {
  if (value is List<Object?>) {
    return <int>[
      for (final item in value)
        if (jsNumber(item).isFinite) jsNumber(item).toInt(),
    ];
  }
  final text = jsString(value);
  try {
    final decoded = jsonDecode(text);
    if (decoded is List<Object?>) {
      return <int>[
        for (final item in decoded)
          if (jsNumber(item).isFinite) jsNumber(item).toInt(),
      ];
    }
  } on FormatException {
    // Fall through to comma-separated parsing.
  }
  return text
      .split(',')
      .map((item) => num.tryParse(item.trim()))
      .whereType<num>()
      .map((item) => item.toInt())
      .toList(growable: false);
}

Object? _tryDecode(String value) {
  try {
    return jsonDecode(value);
  } on FormatException {
    return null;
  }
}
