import '../endpoint.dart';
import '../models.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createCoreEndpointHandlers() =>
    <String, KugouEndpointHandler>{
      '/search': _search,
      '/search/lyric': _searchLyric,
      '/song/url': _songUrl,
      '/playlist/track/all': _playlistTrackAll,
      '/lyric': _lyric,
    };

Future<KugouResponse<Object?>> _search(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  const types = {'special', 'lyric', 'song', 'album', 'author', 'mv'};
  final requestedType = stringParameter(input, 'type', 'song');
  final type = types.contains(requestedType) ? requestedType : 'song';
  return context.request(
    KugouRequest(
      path: '/${type == 'song' ? 'v3' : 'v1'}/search/$type',
      parameters: <String, Object?>{
        'albumhide': 0,
        'iscorrection': 1,
        'keyword': stringParameter(input, 'keywords'),
        'nocollect': 0,
        'page': intParameter(input, 'page', 1),
        'pagesize': intParameter(input, 'pagesize', 30),
        'platform': 'AndroidFilter',
      },
      headers: const <String, Object?>{'x-router': 'complexsearch.kugou.com'},
    ),
  );
}

Future<KugouResponse<Object?>> _searchLyric(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  // The current lyrics service returns an empty body (x-kg-errcode 20010)
  // for the newer /v1/search shape used by the generated compatibility
  // endpoint. The desktop-compatible endpoint remains the source used by the
  // KuGou clients and returns the same candidates contract.
  return context.request(
    KugouRequest(
      baseUri: Uri.parse('https://lyrics.kugou.com'),
      path: '/search',
      parameters: <String, Object?>{
        'ver': 1,
        'man': 'yes',
        'client': 'pc',
        'keyword': stringParameter(input, 'keywords'),
        'duration': intParameter(input, 'duration'),
        'hash': stringParameter(input, 'hash'),
      },
      clearDefaultParameters: true,
      skipSignature: true,
    ),
  );
}

Future<KugouResponse<Object?>> _songUrl(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  const magicQualities = {
    'piano',
    'acappella',
    'subwoofer',
    'ancient',
    'dj',
    'surnay',
  };
  final requestedQuality = input['quality'];
  final quality = magicQualities.contains(requestedQuality)
      ? 'magic_$requestedQuality'
      : requestedQuality ?? 128;
  final isLite = context.config.isLite;
  return context.request(
    KugouRequest(
      path: '/v5/url',
      parameters: <String, Object?>{
        'album_id': intParameter(input, 'album_id'),
        'area_code': 1,
        'hash': stringParameter(input, 'hash').toLowerCase(),
        'ssa_flag': 'is_fromtrack',
        'version': 11430,
        'page_id': isLite ? 967177915 : 151369488,
        'quality': quality,
        'album_audio_id': intParameter(input, 'album_audio_id'),
        'behavior': 'play',
        'pid': isLite ? 411 : 2,
        'cmd': 26,
        'pidversion': 3001,
        'IsFreePart': boolParameter(input, 'free_part') ? 1 : 0,
        'ppage_id': isLite
            ? input['ppage_id'] ?? '356753938,823673182,967485191'
            : '463467626,350369493,788954147',
        'cdnBackup': 1,
        'module': '',
        'clientver': 11430,
      },
      headers: const <String, Object?>{'x-router': 'trackercdn.kugou.com'},
      encryptKey: true,
      cookies: <String, String>{
        'dfid': randomString(24),
        ...context.session.cookies,
      },
    ),
  );
}

Future<KugouResponse<Object?>> _playlistTrackAll(
  KugouEndpointContext context,
  Map<String, Object?> input,
) {
  final pageSize = intParameter(input, 'pagesize', 30);
  return context.request(
    KugouRequest(
      path: '/pubsongs/v2/get_other_list_file_nofilt',
      parameters: <String, Object?>{
        'area_code': 1,
        'begin_idx': (intParameter(input, 'page', 1) - 1) * pageSize,
        'plat': 1,
        'type': 1,
        'mode': 1,
        'personal_switch': 1,
        'extend_fields': 'abtags,hot_cmt,popularization',
        'pagesize': pageSize,
        'global_collection_id': input['id'],
      },
    ),
  );
}

Future<KugouResponse<Object?>> _lyric(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final response = await context.request(
    KugouRequest(
      baseUri: Uri.parse('https://lyrics.kugou.com'),
      path: '/download',
      parameters: <String, Object?>{
        'ver': 1,
        'client': input['client'] ?? 'android',
        'id': input['id'],
        'accesskey': input['accesskey'],
        'fmt': input['fmt'] ?? 'krc',
        'charset': 'utf8',
      },
    ),
  );
  if (!boolParameter(input, 'decode') ||
      response.body is! Map<String, Object?>) {
    return response;
  }
  final body = Map<String, Object?>.from(
    response.body! as Map<String, Object?>,
  );
  final content = body['content'];
  if (content is String) {
    final plainText =
        input['fmt'] == 'lrc' ||
        int.tryParse(body['contenttype']?.toString() ?? '') != 0;
    body['decodeContent'] = plainText
        ? String.fromCharCodes(
            Uri.parse('data:;base64,$content').data!.contentAsBytes(),
          )
        : decodeKrcLyrics(content);
  }
  return KugouResponse<Object?>(
    status: response.status,
    httpStatus: response.httpStatus,
    body: body,
    cookies: response.cookies,
    headers: response.headers,
  );
}
