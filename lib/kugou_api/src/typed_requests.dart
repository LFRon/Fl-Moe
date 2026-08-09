import 'dart:typed_data';

typedef KugouJsonObject = Map<String, Object?>;

enum KugouSearchType { song, special, lyric, album, author, mv }

enum KugouPlaybackQuality {
  standard('128'),
  high('320'),
  lossless('flac'),
  hiRes('high'),
  atmos('viper_atmos'),
  clear('viper_clear'),
  master('viper_tape'),
  piano('piano'),
  acappella('acappella'),
  subwoofer('subwoofer'),
  ancient('ancient'),
  dj('dj'),
  surnay('surnay');

  const KugouPlaybackQuality(this.wireValue);

  final String wireValue;
}

final class KugouSearchQuery {
  const KugouSearchQuery({
    required this.keywords,
    this.page = 1,
    this.pageSize = 30,
    this.type = KugouSearchType.song,
  }) : assert(keywords.length > 0),
       assert(page > 0),
       assert(pageSize > 0);

  final String keywords;
  final int page;
  final int pageSize;
  final KugouSearchType type;

  KugouJsonObject toParameters() => <String, Object?>{
    'keywords': keywords,
    'page': page,
    'pagesize': pageSize,
    'type': type.name,
  };
}

final class KugouSearchSuggestionQuery {
  const KugouSearchSuggestionQuery({
    required this.keywords,
    this.albumCount = 10,
    this.correctionCount = 10,
    this.mvCount = 10,
    this.musicCount = 10,
  }) : assert(keywords.length > 0),
       assert(albumCount >= 0),
       assert(correctionCount >= 0),
       assert(mvCount >= 0),
       assert(musicCount >= 0);

  final String keywords;
  final int albumCount;
  final int correctionCount;
  final int mvCount;
  final int musicCount;

  KugouJsonObject toParameters() => <String, Object?>{
    'keywords': keywords,
    'albumTipCount': albumCount,
    'correctTipCount': correctionCount,
    'mvTipCount': mvCount,
    'musicTipCount': musicCount,
  };
}

final class KugouSongUrlQuery {
  const KugouSongUrlQuery({
    required this.hash,
    this.albumId = 0,
    this.albumAudioId = 0,
    this.quality = KugouPlaybackQuality.standard,
    this.freePart = false,
    this.parentPageId,
  }) : assert(hash.length > 0);

  final String hash;
  final int albumId;
  final int albumAudioId;
  final KugouPlaybackQuality quality;
  final bool freePart;
  final String? parentPageId;

  KugouJsonObject toParameters() => <String, Object?>{
    'hash': hash,
    'album_id': albumId,
    'album_audio_id': albumAudioId,
    'quality': quality.wireValue,
    'free_part': freePart,
    'ppage_id': ?parentPageId,
  };
}

final class KugouPlaylistTracksQuery {
  const KugouPlaylistTracksQuery({
    required this.collectionId,
    this.page = 1,
    this.pageSize = 30,
  }) : assert(collectionId.length > 0),
       assert(page > 0),
       assert(pageSize > 0);

  final String collectionId;
  final int page;
  final int pageSize;

  KugouJsonObject toParameters() => <String, Object?>{
    'id': collectionId,
    'page': page,
    'pagesize': pageSize,
  };
}

final class KugouLyricsQuery {
  const KugouLyricsQuery({
    required this.id,
    required this.accessKey,
    this.format = 'krc',
    this.client = 'android',
    this.decode = true,
  }) : assert(id.length > 0),
       assert(accessKey.length > 0),
       assert(format.length > 0),
       assert(client.length > 0);

  final String id;
  final String accessKey;
  final String format;
  final String client;
  final bool decode;

  KugouJsonObject toParameters() => <String, Object?>{
    'id': id,
    'accesskey': accessKey,
    'fmt': format,
    'client': client,
    'decode': decode,
  };
}

final class KugouCloudPageQuery {
  const KugouCloudPageQuery({this.page = 1, this.pageSize = 30})
    : assert(page > 0),
      assert(pageSize > 0);

  final int page;
  final int pageSize;

  KugouJsonObject toParameters() => <String, Object?>{
    'page': page,
    'pagesize': pageSize,
  };
}

final class KugouCloudMatchQuery {
  const KugouCloudMatchQuery({
    this.hashes = const <String>[],
    this.albumAudioIds = const <String>[],
    this.data,
  }) : assert(hashes.length > 0 || data != null);

  final List<String> hashes;
  final List<String> albumAudioIds;
  final Uint8List? data;

  KugouJsonObject toParameters() => <String, Object?>{
    if (hashes.isNotEmpty) 'hash': hashes,
    if (albumAudioIds.isNotEmpty) 'album_audio_ids': albumAudioIds,
    'data': ?data,
  };
}

final class KugouCloudUploadQuery {
  const KugouCloudUploadQuery({
    required this.data,
    this.filename,
    this.extension = 'mp3',
    this.autoMatch = true,
    this.standardHash,
    this.audioId = 0,
    this.albumAudioId = 0,
    this.authorName,
    this.trackName,
    this.displayName,
    this.bitrate = 4,
    this.durationSeconds = 0,
    this.listVersion = 0,
  }) : assert(extension.length > 0),
       assert(audioId >= 0),
       assert(albumAudioId >= 0),
       assert(bitrate >= 0),
       assert(durationSeconds >= 0),
       assert(listVersion >= 0);

  final Uint8List data;
  final String? filename;
  final String extension;
  final bool autoMatch;
  final String? standardHash;
  final int audioId;
  final int albumAudioId;
  final String? authorName;
  final String? trackName;
  final String? displayName;
  final int bitrate;
  final int durationSeconds;
  final int listVersion;

  KugouJsonObject toParameters() => <String, Object?>{
    'data': data,
    'filename': ?filename,
    'extendname': extension,
    'auto_match': autoMatch,
    'hash_std': ?standardHash,
    'audio_id': audioId,
    'album_audio_id': albumAudioId,
    'author_name': ?authorName,
    'track_name': ?trackName,
    'name': ?displayName,
    'bitrate': bitrate,
    'timelen': durationSeconds,
    'list_ver': listVersion,
  };
}

final class KugouUnexpectedBodyException implements Exception {
  const KugouUnexpectedBodyException({
    required this.route,
    required this.actualType,
  });

  final String route;
  final Type actualType;

  @override
  String toString() =>
      'KugouUnexpectedBodyException(route: $route, actualType: $actualType)';
}
