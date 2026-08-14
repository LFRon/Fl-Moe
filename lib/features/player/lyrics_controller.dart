import 'package:get/get.dart';

import '../../core/backend/music_backend.dart';
import '../../kugou_api.dart';
import '../music/music_models.dart';
import 'lyrics_models.dart';

enum LyricsLoadState { idle, loading, ready, empty, failed }

final class LyricsController extends GetxController {
  LyricsController(this._api);

  final MusicBackend _api;
  LyricsLoadState _state = LyricsLoadState.idle;
  List<TimedLyricLine> _lines = const <TimedLyricLine>[];
  MusicTrack? _track;
  String? _error;
  int _requestId = 0;

  LyricsLoadState get state => _state;
  List<TimedLyricLine> get lines => _lines;
  String? get error => _error;
  String get trackHash => _track?.hash ?? '';

  Future<void> loadFor(MusicTrack? track, {bool force = false}) async {
    if (track == null || !track.canPlay) {
      if (_state == LyricsLoadState.idle && _track == null) return;
      _requestId += 1;
      _track = null;
      _state = LyricsLoadState.idle;
      _lines = const <TimedLyricLine>[];
      _error = null;
      update();
      return;
    }
    if (!force && track.hash == _track?.hash) return;

    _track = track;
    _state = LyricsLoadState.loading;
    _lines = const <TimedLyricLine>[];
    _error = null;
    final requestId = ++_requestId;
    update();

    try {
      final searchResponse = await _api.searchLyrics(
        KugouLyricSearchQuery(
          hash: track.hash,
          albumAudioId: track.albumAudioId,
          duration: track.duration,
          keywords: track.artist == '未知歌手'
              ? track.title
              : '${track.artist} - ${track.title}',
        ),
      );
      if (requestId != _requestId) return;
      final candidate = _firstLyricsCandidate(searchResponse.body);
      if (candidate == null) {
        _state = LyricsLoadState.empty;
        update();
        return;
      }
      final id = readString(candidate, const <String>['id']);
      final accessKey = readString(candidate, const <String>[
        'accesskey',
        'access_key',
      ]);
      if (id.isEmpty || accessKey.isEmpty) {
        _state = LyricsLoadState.empty;
        update();
        return;
      }
      final lyricsResponse = await _api.lyrics(
        KugouLyricsQuery(id: id, accessKey: accessKey),
      );
      if (requestId != _requestId) return;
      final parsed = parseKugouLyrics(_decodedLyrics(lyricsResponse.body));
      _lines = List<TimedLyricLine>.unmodifiable(parsed);
      _state = parsed.isEmpty ? LyricsLoadState.empty : LyricsLoadState.ready;
    } on Object catch (error) {
      if (requestId != _requestId) return;
      _error = error.toString().replaceFirst('Bad state: ', '');
      _state = LyricsLoadState.failed;
    }
    update();
  }

  Future<void> retry() => loadFor(_track, force: true);
}

JsonObject? _firstLyricsCandidate(KugouJsonObject body) {
  final candidates = findObjectList(body, const <String>['candidates']);
  return candidates.isEmpty ? null : candidates.first;
}

String _decodedLyrics(KugouJsonObject body) {
  final direct = readString(body, const <String>[
    'decodeContent',
    'decode_content',
  ]);
  if (direct.isNotEmpty) return direct;
  final data = asJsonObject(body['data']);
  if (data == null) return '';
  return readString(data, const <String>['decodeContent', 'decode_content']);
}
