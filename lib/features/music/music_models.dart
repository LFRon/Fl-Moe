import 'dart:convert';

typedef JsonObject = Map<String, Object?>;

enum MusicCollectionKind { playlist, ranking }

final class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.hash,
    required this.title,
    required this.artist,
    this.album = '',
    this.coverUrl = '',
    this.duration = Duration.zero,
    this.albumId = 0,
    this.albumAudioId = 0,
  });

  factory MusicTrack.fromKugou(JsonObject json) {
    final audioInfo =
        asJsonObject(json['audio_info']) ?? const <String, Object?>{};
    final albumInfo =
        asJsonObject(json['album_info']) ?? const <String, Object?>{};
    final transParam =
        asJsonObject(json['trans_param']) ?? const <String, Object?>{};
    final deprecated =
        asJsonObject(json['deprecated']) ?? const <String, Object?>{};
    final rawTitle = readString(json, const <String>[
      'OriSongName',
      'SongName',
      'songname',
      'song_name',
      'ori_audio_name',
      'name',
      'audio_name',
      'FileName',
      'filename',
    ]);
    final artist = readString(json, const <String>[
      'SingerName',
      'singername',
      'author_name',
      'author',
      'singer_name',
    ]);
    final title = _withoutArtistPrefix(rawTitle, artist);
    final directHash = readString(json, const <String>[
      'FileHash',
      'hash',
      'hash_128',
      'HQFileHash',
      'hash_320',
      'SQFileHash',
      'hash_flac',
    ]);
    final hash = directHash.isNotEmpty
        ? directHash
        : _firstNonEmpty(<String>[
            readString(audioInfo, const <String>['hash_128', 'hash']),
            readString(deprecated, const <String>['hash']),
          ]);
    final directCover = readString(json, const <String>[
      'Image',
      'image',
      'img',
      'cover',
      'cover_url',
      'sizable_cover',
    ]);
    final cover = normalizeImageUrl(
      directCover.isNotEmpty
          ? directCover
          : _firstNonEmpty(<String>[
              readString(albumInfo, const <String>['sizable_cover', 'cover']),
              readString(transParam, const <String>['union_cover']),
            ]),
    );
    final directDuration = readInt(json, const <String>[
      'timeLength',
      'TimeLength',
      'duration',
      'timelen',
    ]);
    final durationRaw = directDuration > 0
        ? directDuration
        : readInt(audioInfo, const <String>['duration_128', 'duration']);
    final duration = durationRaw > 10000
        ? Duration(milliseconds: durationRaw)
        : Duration(seconds: durationRaw);
    final albumAudioId = readInt(json, const <String>[
      'MixSongID',
      'mixsongid',
      'album_audio_id',
      'album_audioid',
    ]);
    final id = albumAudioId > 0
        ? albumAudioId.toString()
        : readString(json, const <String>['audio_id', 'Audioid', 'id']);
    return MusicTrack(
      id: id.isEmpty ? hash : id,
      hash: hash,
      title: title.isEmpty ? '未知歌曲' : title,
      artist: artist.isEmpty ? '未知歌手' : artist,
      album: _firstNonEmpty(<String>[
        readString(json, const <String>[
          'AlbumName',
          'album_name',
          'albumname',
        ]),
        readString(albumInfo, const <String>['album_name', 'name']),
      ]),
      coverUrl: cover,
      duration: duration,
      albumId: readInt(json, const <String>['AlbumID', 'album_id', 'albumid']),
      albumAudioId: albumAudioId,
    );
  }

  factory MusicTrack.fromJson(JsonObject json) => MusicTrack(
    id: readString(json, const <String>['id']),
    hash: readString(json, const <String>['hash']),
    title: readString(json, const <String>['title']),
    artist: readString(json, const <String>['artist']),
    album: readString(json, const <String>['album']),
    coverUrl: readString(json, const <String>['coverUrl']),
    duration: Duration(
      milliseconds: readInt(json, const <String>['durationMs']),
    ),
    albumId: readInt(json, const <String>['albumId']),
    albumAudioId: readInt(json, const <String>['albumAudioId']),
  );

  final String id;
  final String hash;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final Duration duration;
  final int albumId;
  final int albumAudioId;

  bool get canPlay => hash.isNotEmpty;

  JsonObject toJson() => <String, Object?>{
    'id': id,
    'hash': hash,
    'title': title,
    'artist': artist,
    'album': album,
    'coverUrl': coverUrl,
    'durationMs': duration.inMilliseconds,
    'albumId': albumId,
    'albumAudioId': albumAudioId,
  };
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _withoutArtistPrefix(String title, String artist) {
  if (title.isEmpty || artist.isEmpty) return title;
  for (final separator in const <String>[' - ', ' — ', ' – ']) {
    final prefix = '$artist$separator';
    if (title.startsWith(prefix) && title.length > prefix.length) {
      return title.substring(prefix.length).trim();
    }
  }
  return title;
}

final class MusicCollection {
  const MusicCollection({
    required this.id,
    required this.title,
    required this.kind,
    this.subtitle = '',
    this.coverUrl = '',
    this.playCount = 0,
  });

  factory MusicCollection.fromKugou(
    JsonObject json, {
    required MusicCollectionKind kind,
  }) => MusicCollection(
    id: readString(json, const <String>[
      'global_collection_id',
      'specialid',
      'special_id',
      'collect_id',
      'rankid',
      'rank_id',
      'id',
    ]),
    title: readString(json, const <String>[
      'specialname',
      'rankname',
      'name',
      'title',
    ]),
    subtitle: readString(json, const <String>[
      'intro',
      'description',
      'update_frequency',
    ]),
    coverUrl: normalizeImageUrl(
      readString(json, const <String>[
        'imgurl',
        'img',
        'image',
        'cover',
        'banner7url',
      ]),
    ),
    playCount: readInt(json, const <String>['playcount', 'play_count', 'heat']),
    kind: kind,
  );

  final String id;
  final String title;
  final MusicCollectionKind kind;
  final String subtitle;
  final String coverUrl;
  final int playCount;
}

JsonObject? asJsonObject(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is! Map<Object?, Object?>) return null;
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is String) result[key] = entry.value;
  }
  return result;
}

List<Object?> asJsonList(Object? value) {
  if (value is List<Object?>) return value;
  if (value is Iterable<Object?>) return value.toList(growable: false);
  return const <Object?>[];
}

String readString(JsonObject json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
  }
  return '';
}

int readInt(JsonObject json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

String normalizeImageUrl(String value, {int size = 480}) {
  if (value.isEmpty) return '';
  final result = value.replaceAll('{size}', size.toString());
  return result.startsWith('//') ? 'https:$result' : result;
}

List<JsonObject> findObjectList(
  Object? root,
  List<String> preferredKeys, {
  int maxDepth = 5,
}) {
  if (maxDepth < 0) return const <JsonObject>[];
  final object = asJsonObject(root);
  if (object != null) {
    for (final key in preferredKeys) {
      final candidates = _objectsFromList(object[key]);
      if (candidates.isNotEmpty) return candidates;
    }
    for (final value in object.values) {
      final nested = findObjectList(
        value,
        preferredKeys,
        maxDepth: maxDepth - 1,
      );
      if (nested.isNotEmpty) return nested;
    }
  }
  for (final value in asJsonList(root)) {
    final nested = findObjectList(value, preferredKeys, maxDepth: maxDepth - 1);
    if (nested.isNotEmpty) return nested;
  }
  return const <JsonObject>[];
}

List<JsonObject> decodeStoredObjectList(Object? value) {
  final source = switch (value) {
    final String text => _tryDecode(text),
    _ => value,
  };
  return _objectsFromList(source);
}

List<JsonObject> _objectsFromList(Object? value) {
  final items = asJsonList(value);
  if (items.isEmpty) return const <JsonObject>[];
  final result = <JsonObject>[];
  for (final item in items) {
    final object = asJsonObject(item);
    if (object != null) result.add(object);
  }
  return result;
}

Object? _tryDecode(String value) {
  try {
    return jsonDecode(value);
  } on FormatException {
    return null;
  }
}
