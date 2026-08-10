import 'dart:io';

import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final live = Platform.environment['KUGOU_LIVE_TEST'] == '1';
  final authentication = _parseCookies(
    Platform.environment['KUGOU_LIVE_COOKIE'],
  );

  test(
    'public discovery endpoints respond through the real KuGou gateway',
    () async {
      final api = KugouApi();
      addTearDown(api.close);

      final hot = await api.call('/search/hot');
      expect(hot.httpStatus, 200);
      expect(hot.body, isA<Map<String, Object?>>());
      expect(
        findObjectList(hot.body, const <String>['info', 'list', 'hot', 'data']),
        isNotEmpty,
      );

      final ranks = await api.call('/rank/list');
      expect(ranks.httpStatus, 200);
      expect(ranks.body, isA<Map<String, Object?>>());
      final rankObjects = findObjectList(ranks.body, const <String>[
        'list',
        'info',
        'rank_list',
        'data',
      ]);
      final rankCollections = rankObjects
          .map(
            (object) => MusicCollection.fromKugou(
              object,
              kind: MusicCollectionKind.ranking,
            ),
          )
          .where((collection) => collection.id.isNotEmpty)
          .toList(growable: false);
      expect(rankCollections, isNotEmpty);

      final playlists = await api.call(
        '/top/playlist',
        parameters: const <String, Object?>{'page': 1, 'pagesize': 12},
      );
      expect(playlists.httpStatus, 200);
      expect(playlists.body, isA<Map<String, Object?>>());
      final playlistObjects = findObjectList(playlists.body, const <String>[
        'special_list',
        'list',
        'info',
        'data',
      ]);
      final playlistCollections = playlistObjects
          .map(
            (object) => MusicCollection.fromKugou(
              object,
              kind: MusicCollectionKind.playlist,
            ),
          )
          .where((collection) => collection.id.isNotEmpty)
          .toList(growable: false);
      expect(playlistCollections, isNotEmpty);

      final playlistTracks = await api.call(
        '/playlist/track/all',
        parameters: <String, Object?>{
          'id': playlistCollections.first.id,
          'page': 1,
          'pagesize': 5,
        },
      );
      final parsedPlaylistTracks = findObjectList(
        playlistTracks.body,
        const <String>['songs', 'lists', 'list', 'info', 'data'],
      ).map(MusicTrack.fromKugou).where((track) => track.canPlay).toList();
      expect(parsedPlaylistTracks, isNotEmpty);

      final conceptApi = KugouApi(
        config: const KugouApiConfig(variant: KugouClientVariant.lite),
        session: KugouSession(variant: KugouClientVariant.lite),
      );
      addTearDown(conceptApi.close);
      final privilege = await conceptApi.songPrivileges(
        KugouSongPrivilegeQuery(
          hash: parsedPlaylistTracks.first.hash,
          albumId: parsedPlaylistTracks.first.albumId,
        ),
      );
      expect(privilege.httpStatus, 200);
      expect(asJsonList(privilege.body['data']), isNotEmpty);

      final rankTracks = await api.call(
        '/rank/audio',
        parameters: <String, Object?>{
          'rankid': rankCollections.first.id,
          'page': 1,
          'pagesize': 5,
        },
      );
      final parsedRankTracks = findObjectList(rankTracks.body, const <String>[
        'songlist',
        'songs',
        'lists',
        'list',
        'info',
        'data',
      ]).map(MusicTrack.fromKugou).where((track) => track.canPlay);
      expect(parsedRankTracks, isNotEmpty);
    },
    skip: live ? false : 'Set KUGOU_LIVE_TEST=1 to use the real network.',
  );

  test(
    'background isolate reaches the real KuGou gateway',
    () async {
      final backend = await IsolatedMusicBackend.start(
        initialSession: KugouSession(variant: KugouClientVariant.lite).toJson(),
        clientVariant: KugouClientVariant.lite,
      );
      addTearDown(backend.close);

      final hot = await backend.hotSearch();

      expect(hot.httpStatus, 200);
      expect(backend.clientVariant, KugouClientVariant.lite);
      expect(
        findObjectList(hot.body, const <String>['info', 'list', 'hot', 'data']),
        isNotEmpty,
      );
    },
    skip: live ? false : 'Set KUGOU_LIVE_TEST=1 to use the real network.',
  );

  test(
    'authenticated search responds through the real KuGou gateway',
    () async {
      final api = KugouApi(session: KugouSession(cookies: authentication));
      addTearDown(api.close);

      final search = await api.call(
        '/search',
        parameters: const <String, Object?>{'keywords': '初音未来', 'pagesize': 30},
      );
      expect(search.httpStatus, 200);
      expect(search.body, isA<Map<String, Object?>>());
    },
    skip: live && authentication.isNotEmpty
        ? false
        : 'Set KUGOU_LIVE_TEST=1 and KUGOU_LIVE_COOKIE for search.',
  );

  test(
    'authenticated concept session registers and resolves a signed song URL',
    () async {
      final session = KugouSession(
        variant: KugouClientVariant.lite,
        cookies: authentication,
      );
      final api = KugouApi(
        config: const KugouApiConfig(variant: KugouClientVariant.lite),
        session: session,
      );
      final backend = LocalMusicBackend(api);
      addTearDown(backend.close);

      expect(await backend.ensureDeviceRegistered(), isTrue);
      expect(backend.sessionState.hasRegisteredDevice, isTrue);

      final search = await backend.search(
        const KugouSearchQuery(keywords: '初音未来', pageSize: 10),
      );
      final tracks = findObjectList(search.body, const <String>[
        'info',
        'lists',
        'songs',
        'list',
        'data',
      ]).map(MusicTrack.fromKugou).where((track) => track.canPlay).toList();
      expect(tracks, isNotEmpty);
      final track = tracks.first;

      final privileges = await backend.songPrivileges(
        KugouSongPrivilegeQuery(hash: track.hash, albumId: track.albumId),
      );
      final hash = _standardPrivilegeHash(privileges.body) ?? track.hash;
      final response = await backend.resolveSongUrl(
        KugouSongUrlQuery(
          hash: hash,
          albumId: track.albumId,
          albumAudioId: track.albumAudioId,
          quality: KugouPlaybackQuality.standard,
          parentPageId: '356753938',
        ),
      );

      expect(_containsAudioUrl(response.body), isTrue);
    },
    skip: live && authentication.isNotEmpty
        ? false
        : 'Set KUGOU_LIVE_TEST=1 and KUGOU_LIVE_COOKIE for playback.',
  );
}

Map<String, String> _parseCookies(String? value) {
  if (value == null || value.trim().isEmpty) return <String, String>{};
  final result = <String, String>{};
  for (final part in value.split(';')) {
    final separator = part.indexOf('=');
    if (separator <= 0) continue;
    result[part.substring(0, separator).trim()] = part
        .substring(separator + 1)
        .trim();
  }
  return result;
}

String? _standardPrivilegeHash(KugouJsonObject body) {
  for (final rawItem in asJsonList(body['data'])) {
    final item = asJsonObject(rawItem);
    if (item == null) continue;
    for (final rawVariant in <Object?>[
      item,
      ...asJsonList(item['relate_goods']),
    ]) {
      final variant = asJsonObject(rawVariant);
      if (variant == null) continue;
      final quality = readString(variant, const <String>['quality']);
      final hash = readString(variant, const <String>['hash']);
      final level = readInt(variant, const <String>['level']);
      if (quality == '128' && hash.isNotEmpty && level != 0) return hash;
    }
  }
  return null;
}

bool _containsAudioUrl(KugouJsonObject body) {
  bool contains(Object? value) {
    if (value is String) {
      final uri = Uri.tryParse(value);
      return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    }
    if (value is Iterable<Object?>) return value.any(contains);
    return false;
  }

  for (final key in const <String>['url', 'play_url', 'backup_url']) {
    if (contains(body[key])) return true;
  }
  final data = asJsonObject(body['data']);
  if (data == null) return false;
  return const <String>[
    'url',
    'play_url',
    'backup_url',
  ].any((key) => contains(data[key]));
}
