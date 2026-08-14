import '../kugou_api.dart';
import 'models.dart';
import 'typed_requests.dart';

/// Strongly typed, application-facing operations on the unified [KugouApi].
///
/// [KugouApi.call] remains available for all 169 compatibility routes. Flutter
/// UI code should prefer these methods and [callJson] so malformed response
/// bodies fail at one explicit protocol boundary.
extension KugouTypedApi on KugouApi {
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) async => _expectJson(route, await call(route, parameters: parameters));

  Future<KugouResponse<KugouJsonObject>> search(KugouSearchQuery query) =>
      callJson('/search', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> complexSearch(
    KugouSearchQuery query,
  ) => callJson('/search/complex', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> hotSearch() => callJson('/search/hot');

  Future<KugouResponse<KugouJsonObject>> searchSuggestions(
    KugouSearchSuggestionQuery query,
  ) => callJson('/search/suggest', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> resolveSongUrl(
    KugouSongUrlQuery query,
  ) => callJson('/song/url', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> songPrivileges(
    KugouSongPrivilegeQuery query,
  ) => callJson('/privilege/lite', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> playlistTracks(
    KugouPlaylistTracksQuery query,
  ) => callJson('/playlist/track/all', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> userPlaylists(
    KugouUserPlaylistsQuery query,
  ) => callJson('/user/playlist', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> userPlaylistTracks(
    KugouUserPlaylistTracksQuery query,
  ) => callJson('/playlist/track/all/new', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> lyrics(KugouLyricsQuery query) =>
      callJson('/lyric', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> searchLyrics(
    KugouLyricSearchQuery query,
  ) => callJson('/search/lyric', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> userDetail() =>
      callJson('/user/detail');

  Future<KugouResponse<KugouJsonObject>> loginQrKey({bool web = false}) =>
      callJson(
        '/login/qr/key',
        parameters: <String, Object?>{if (web) 'type': 'web'},
      );

  /// Returns the QR payload URL itself. Rendering stays in the Flutter UI.
  Future<Uri> loginQrContent(String key) async {
    if (key.isEmpty) throw ArgumentError.value(key, 'key', 'Must not be empty');
    final response = await callJson(
      '/login/qr/create',
      parameters: <String, Object?>{'key': key},
    );
    final data = response.body['data'];
    if (data is! Map<String, Object?>) {
      throw KugouUnexpectedBodyException(
        route: '/login/qr/create',
        actualType: data.runtimeType,
      );
    }
    final content = data['content'];
    if (content is! String || content.isEmpty) {
      throw KugouUnexpectedBodyException(
        route: '/login/qr/create',
        actualType: content.runtimeType,
      );
    }
    return Uri.parse(content);
  }

  Future<KugouResponse<KugouJsonObject>> checkLoginQr(String key) {
    if (key.isEmpty) throw ArgumentError.value(key, 'key', 'Must not be empty');
    return callJson(
      '/login/qr/check',
      parameters: <String, Object?>{'key': key},
    );
  }

  Future<KugouResponse<KugouJsonObject>> cloudPage(KugouCloudPageQuery query) =>
      callJson('/user/cloud', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> deleteCloudFiles(
    List<String> fileIds, {
    List<String> albumAudioIds = const <String>[],
  }) {
    if (fileIds.isEmpty) {
      throw ArgumentError.value(fileIds, 'fileIds', 'Must not be empty');
    }
    return callJson(
      '/user/cloud/del',
      parameters: <String, Object?>{
        'fileids': fileIds,
        if (albumAudioIds.isNotEmpty) 'album_audio_ids': albumAudioIds,
      },
    );
  }

  Future<KugouResponse<KugouJsonObject>> matchCloudFile(
    KugouCloudMatchQuery query,
  ) => callJson('/user/cloud/match', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> uploadCloudFile(
    KugouCloudUploadQuery query,
  ) => callJson('/user/cloud/upload', parameters: query.toParameters());
}

KugouResponse<KugouJsonObject> _expectJson(
  String route,
  KugouResponse<Object?> response,
) {
  final body = response.body;
  if (body is! Map<String, Object?>) {
    throw KugouUnexpectedBodyException(
      route: route,
      actualType: body.runtimeType,
    );
  }
  return KugouResponse<KugouJsonObject>(
    status: response.status,
    httpStatus: response.httpStatus,
    body: body,
    cookies: response.cookies,
    headers: response.headers,
  );
}
