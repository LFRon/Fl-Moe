import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';

import '../../core/backend/music_backend.dart';
import '../../core/storage/key_value_store.dart';
import '../../kugou_api.dart';
import '../music/music_models.dart';
import 'audio_engine.dart';
import 'playback_quality.dart';

enum PlaybackMode { shuffle, listLoop, singleLoop, sequential }

final class PlaybackController extends GetxController {
  PlaybackController(
    this._api,
    this._engine,
    this._libraryStore, {
    Random? random,
    KugouPlaybackQuality Function()? preferredQuality,
  }) : _random = random ?? Random() {
    _preferredQuality = preferredQuality ?? _defaultPreferredPlaybackQuality;
    _restoreRecentTracks();
    _restorePlaybackMode();
    _restoreCurrentTrack();
    _playingSubscription = _engine.playing.listen((value) {
      _playing = value;
      update();
    });
    _bufferingSubscription = _engine.buffering.listen((value) {
      _buffering = value;
      update();
    });
    _completedSubscription = _engine.completed.listen((value) {
      if (value) unawaited(_handleCompleted());
    });
    _positionSubscription = _engine.position.listen(_handleEnginePosition);
    _durationSubscription = _engine.duration.listen((value) {
      _duration = value;
      update();
    });
    _volumeSubscription = _engine.volume.listen((value) {
      _volume = value.clamp(0, 100);
      update();
    });
    _errorSubscription = _engine.errors.listen((value) {
      _error = value;
      update();
    });
    unawaited(_engine.setVolume(_volume));
  }

  static const String _recentKey = 'recent_tracks';
  static const String _playbackModeKey = 'player_playback_mode';
  static const String _currentTrackKey = 'player_current_track';
  static const int _seekConfirmationToleranceMs = 500;
  static const Duration _seekConfirmationTimeout = Duration(seconds: 8);

  final MusicBackend _api;
  final AudioEngine _engine;
  final KeyValueStore _libraryStore;
  final Random _random;
  late final KugouPlaybackQuality Function() _preferredQuality;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<String>? _errorSubscription;
  Timer? _seekConfirmationTimer;

  // The source is an internal playback context, not a user-editable queue.
  // It is the exact list that the user started playback from (for example a
  // playlist, album, search result, or favorites view) and intentionally only
  // lives in memory.
  List<MusicTrack> _sourceTracks = const <MusicTrack>[];
  List<MusicTrack> _recentTracks = const <MusicTrack>[];
  final List<int> _shuffleHistory = <int>[];
  int _sourceIndex = -1;
  PlaybackMode _playbackMode = PlaybackMode.listLoop;
  MusicTrack? _currentTrack;
  bool _playing = false;
  bool _buffering = false;
  bool _resolving = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 70;
  String? _error;
  KugouPlaybackQuality? _resolvedQuality;
  bool _sourceLoaded = false;
  bool _handlingCompletion = false;
  Duration? _pendingSeekTarget;
  Duration? _positionBeforeSeek;
  int _seekRequestId = 0;

  List<MusicTrack> get recentTracks => _recentTracks;
  PlaybackMode get playbackMode => _playbackMode;
  MusicTrack? get currentTrack => _currentTrack;
  bool get playing => _playing;
  bool get buffering => _buffering;
  bool get resolving => _resolving;
  bool get seeking => _pendingSeekTarget != null;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  String? get error => _error;
  KugouPlaybackQuality? get resolvedQuality => _resolvedQuality;
  bool get _hasCurrentSourceTrack =>
      _sourceIndex >= 0 && _sourceIndex < _sourceTracks.length;
  bool get canGoPrevious => switch (_playbackMode) {
    PlaybackMode.sequential => _sourceIndex > 0,
    _ => _hasCurrentSourceTrack && _sourceTracks.length > 1,
  };
  bool get canGoNext => switch (_playbackMode) {
    PlaybackMode.sequential =>
      _hasCurrentSourceTrack && _sourceIndex < _sourceTracks.length - 1,
    _ => _hasCurrentSourceTrack && _sourceTracks.length > 1,
  };

  /// Starts [track] within the exact list the user selected it from.
  ///
  /// [sourceTracks] is an internal, immutable playback context. It controls
  /// previous/next, sequential, shuffle, and list-loop behavior, but is not a
  /// visible or editable playback queue and is deliberately not persisted.
  Future<void> playTrack(
    MusicTrack track, {
    List<MusicTrack>? sourceTracks,
  }) async {
    if (!track.canPlay) return;
    _setPlaybackSource(track, sourceTracks);
    _shuffleHistory.clear();
    await _startTrack(track);
  }

  void _setPlaybackSource(
    MusicTrack selectedTrack,
    List<MusicTrack>? sourceTracks,
  ) {
    final normalized = <MusicTrack>[];
    final hashes = <String>{};
    for (final track in sourceTracks ?? const <MusicTrack>[]) {
      if (!track.canPlay || !hashes.add(track.hash.toUpperCase())) continue;
      normalized.add(track);
    }
    final selectedHash = selectedTrack.hash.toUpperCase();
    var selectedIndex = normalized.indexWhere(
      (track) => track.hash.toUpperCase() == selectedHash,
    );
    if (selectedIndex < 0) {
      normalized.insert(0, selectedTrack);
      selectedIndex = 0;
    } else {
      // Keep the exact object selected by the page as current metadata.
      normalized[selectedIndex] = selectedTrack;
    }
    _sourceTracks = List<MusicTrack>.unmodifiable(normalized);
    _sourceIndex = selectedIndex;
  }

  Future<void> _startTrack(MusicTrack track) async {
    _invalidatePendingSeek();
    _currentTrack = track;
    _position = Duration.zero;
    _duration = track.duration;
    _error = null;
    _resolvedQuality = null;
    _sourceLoaded = false;
    _resolving = true;
    update();
    try {
      await _persistCurrentTrack();
      final source = await _resolvePlaybackUri(track);
      await _engine.open(source.uri);
      _sourceLoaded = true;
      _resolvedQuality = source.quality;
      await _remember(track);
    } on Object catch (error) {
      _error = _friendlyPlaybackError(error);
    } finally {
      _resolving = false;
      update();
    }
  }

  Future<_ResolvedPlaybackSource> _resolvePlaybackUri(MusicTrack track) async {
    // The reference client registers its emulated Android device during app
    // bootstrap. Await the shared request here as well so /song/url never races
    // it and falls back to an untrusted random dfid.
    await _api.ensureDeviceRegistered();
    final loggedIn = _api.sessionState.isLoggedIn;
    final preferredQuality = normalizeSelectablePlaybackQuality(
      _preferredQuality(),
    );
    final candidates = loggedIn
        ? await _privilegedCandidates(track, preferredQuality)
        : <_PlaybackCandidate>[
            _PlaybackCandidate(
              hash: track.hash,
              quality: KugouPlaybackQuality.standard,
            ),
          ];
    Object? lastError;
    for (final candidate in candidates) {
      try {
        final response = await _api.resolveSongUrl(
          KugouSongUrlQuery(
            hash: candidate.hash,
            albumId: track.albumId,
            albumAudioId: track.albumAudioId,
            quality: candidate.quality,
            freePart: !loggedIn,
            parentPageId: loggedIn ? '356753938' : null,
          ),
        );
        final uri = _findAudioUri(response.body);
        if (uri != null && !_isMp4Response(response.body)) {
          return _ResolvedPlaybackSource(uri: uri, quality: candidate.quality);
        }
      } on Object catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) throw lastError;
    throw StateError('酷狗没有返回可播放地址，可能需要切换音源或检查会员权限');
  }

  Future<List<_PlaybackCandidate>> _privilegedCandidates(
    MusicTrack track,
    KugouPlaybackQuality preferredQuality,
  ) async {
    try {
      final response = await _api.songPrivileges(
        KugouSongPrivilegeQuery(hash: track.hash, albumId: track.albumId),
      );
      final candidates = _parsePrivilegeCandidates(
        response.body,
        preferredQuality,
      );
      if (candidates.isNotEmpty) return candidates;
    } on Object {
      // The legacy URL endpoint can still succeed when privilege metadata is
      // temporarily unavailable, so retain the original hash as a fallback.
    }
    return _fallbackPlaybackCandidates(track.hash, preferredQuality);
  }

  Future<void> toggle() async {
    final track = _currentTrack;
    if (track == null || _resolving) return;
    if (!_sourceLoaded) {
      await _startTrack(track);
      return;
    }
    await _engine.playOrPause();
  }

  Future<void> previous() async {
    if (!canGoPrevious) return;
    final previousIndex = switch (_playbackMode) {
      PlaybackMode.shuffle =>
        _shuffleHistory.isNotEmpty
            ? _shuffleHistory.removeLast()
            : _randomSourceIndex(),
      PlaybackMode.sequential => _sourceIndex - 1,
      PlaybackMode.listLoop || PlaybackMode.singleLoop =>
        (_sourceIndex - 1 + _sourceTracks.length) % _sourceTracks.length,
    };
    await _playSourceIndex(previousIndex, rememberCurrent: false);
  }

  Future<void> next() async {
    if (!canGoNext) return;
    final nextIndex = switch (_playbackMode) {
      PlaybackMode.shuffle => _randomSourceIndex(),
      PlaybackMode.sequential => _sourceIndex + 1,
      PlaybackMode.listLoop ||
      PlaybackMode.singleLoop => (_sourceIndex + 1) % _sourceTracks.length,
    };
    await _playSourceIndex(nextIndex);
  }

  Future<void> setPlaybackMode(PlaybackMode value) async {
    if (_playbackMode == value) return;
    _playbackMode = value;
    _shuffleHistory.clear();
    update();
    await _libraryStore.write(_playbackModeKey, value.name);
  }

  Future<void> clearRecentTracks() async {
    await _libraryStore.delete(_recentKey);
    if (_recentTracks.isEmpty) return;
    _recentTracks = const <MusicTrack>[];
    update();
  }

  Future<void> seek(Duration value) async {
    final safe = value < Duration.zero
        ? Duration.zero
        : value > _duration
        ? _duration
        : value;
    final requestId = ++_seekRequestId;
    _seekConfirmationTimer?.cancel();
    _positionBeforeSeek ??= _position;
    _pendingSeekTarget = safe;
    _position = safe;
    update();
    _seekConfirmationTimer = Timer(_seekConfirmationTimeout, () {
      if (requestId != _seekRequestId) return;
      _pendingSeekTarget = null;
      _positionBeforeSeek = null;
      _seekConfirmationTimer = null;
      update();
    });
    // Give the optimistic UI update a turn before dispatching the native seek.
    // Rapid slider/lyric requests are also coalesced to the newest target.
    await Future<void>.delayed(Duration.zero);
    if (requestId != _seekRequestId) return;
    try {
      await _engine.seek(safe);
    } on Object catch (error) {
      if (requestId != _seekRequestId) return;
      final previous = _positionBeforeSeek;
      _clearPendingSeek();
      if (previous != null) _position = previous;
      _error = _friendlyPlaybackError(error);
      update();
    }
  }

  void _handleEnginePosition(Duration value) {
    final target = _pendingSeekTarget;
    if (target != null) {
      final distance = (value.inMilliseconds - target.inMilliseconds).abs();
      // media_kit/mpv may publish one or more pre-seek positions while the
      // remote source buffers. Keep the selected lyric stable until the
      // backend reaches the requested neighborhood.
      if (distance > _seekConfirmationToleranceMs) return;
      _clearPendingSeek();
    }
    _position = value;
    update();
  }

  void _clearPendingSeek() {
    _seekConfirmationTimer?.cancel();
    _seekConfirmationTimer = null;
    _pendingSeekTarget = null;
    _positionBeforeSeek = null;
  }

  void _invalidatePendingSeek() {
    _seekRequestId += 1;
    _clearPendingSeek();
  }

  Future<void> setVolume(double value) async {
    final safe = value.clamp(0, 100).toDouble();
    _volume = safe;
    update();
    await _engine.setVolume(safe);
  }

  Future<void> _handleCompleted() async {
    if (_handlingCompletion || !_hasCurrentSourceTrack) return;
    _handlingCompletion = true;
    try {
      switch (_playbackMode) {
        case PlaybackMode.singleLoop:
          await _replayCurrent();
          break;
        case PlaybackMode.listLoop:
          if (_sourceTracks.length == 1) {
            await _replayCurrent();
          } else {
            await _playSourceIndex((_sourceIndex + 1) % _sourceTracks.length);
          }
          break;
        case PlaybackMode.shuffle:
          if (_sourceTracks.length == 1) {
            await _replayCurrent();
          } else {
            await _playSourceIndex(_randomSourceIndex());
          }
          break;
        case PlaybackMode.sequential:
          if (_sourceIndex < _sourceTracks.length - 1) {
            await _playSourceIndex(_sourceIndex + 1);
          }
          break;
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  Future<void> _replayCurrent() async {
    _position = Duration.zero;
    _error = null;
    update();
    try {
      await _engine.replay();
    } on Object catch (error) {
      _error = _friendlyPlaybackError(error);
      update();
    }
  }

  int _randomSourceIndex() {
    final offset = _random.nextInt(_sourceTracks.length - 1) + 1;
    return (_sourceIndex + offset) % _sourceTracks.length;
  }

  Future<void> _playSourceIndex(
    int index, {
    bool rememberCurrent = true,
  }) async {
    if (rememberCurrent && _playbackMode == PlaybackMode.shuffle) {
      _shuffleHistory.add(_sourceIndex);
      if (_shuffleHistory.length > 100) _shuffleHistory.removeAt(0);
    }
    final track = _sourceTracks[index];
    _sourceIndex = index;
    await _startTrack(track);
  }

  Future<void> _remember(MusicTrack track) async {
    final updated = <MusicTrack>[
      track,
      ..._recentTracks.where((item) => item.hash != track.hash),
    ];
    _recentTracks = List<MusicTrack>.unmodifiable(updated.take(50));
    await _persistRecentTracks();
  }

  Future<void> _persistRecentTracks() => _libraryStore.write(
    _recentKey,
    jsonEncode(_recentTracks.map((item) => item.toJson()).toList()),
  );

  Future<void> _persistCurrentTrack() {
    if (_currentTrack == null) return _libraryStore.delete(_currentTrackKey);
    return _libraryStore.write(
      _currentTrackKey,
      jsonEncode(_PersistedCurrentTrack(currentTrack: _currentTrack!).toJson()),
    );
  }

  void _restoreRecentTracks() {
    final objects = decodeStoredObjectList(_libraryStore.read(_recentKey));
    _recentTracks = List<MusicTrack>.unmodifiable(
      objects.map(MusicTrack.fromJson).where((track) => track.canPlay),
    );
  }

  void _restorePlaybackMode() {
    final raw = _libraryStore.read(_playbackModeKey);
    if (raw is! String) return;
    for (final mode in PlaybackMode.values) {
      if (mode.name == raw) {
        _playbackMode = mode;
        return;
      }
    }
  }

  void _restoreCurrentTrack() {
    final state = _PersistedCurrentTrack.fromStored(
      _libraryStore.read(_currentTrackKey),
    );
    if (state == null) return;
    _currentTrack = state.currentTrack;
    _sourceTracks = List<MusicTrack>.unmodifiable(<MusicTrack>[
      state.currentTrack,
    ]);
    _sourceIndex = 0;
    _duration = state.currentTrack.duration;
    // Restoring metadata must stay completely offline. The URL and native
    // player are initialized only when the user explicitly presses play.
    _sourceLoaded = false;
  }

  @override
  void onClose() {
    _invalidatePendingSeek();
    unawaited(_playingSubscription?.cancel());
    unawaited(_bufferingSubscription?.cancel());
    unawaited(_completedSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_volumeSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());
    unawaited(_engine.dispose());
    super.onClose();
  }
}

final class _PersistedCurrentTrack {
  const _PersistedCurrentTrack({required this.currentTrack});

  static const int _version = 1;

  final MusicTrack currentTrack;

  JsonObject toJson() => <String, Object?>{
    'version': _version,
    'currentTrack': currentTrack.toJson(),
  };

  static _PersistedCurrentTrack? fromStored(Object? stored) {
    final Object? decoded;
    if (stored is String) {
      try {
        decoded = jsonDecode(stored);
      } on FormatException {
        return null;
      }
    } else {
      decoded = stored;
    }
    final json = asJsonObject(decoded);
    if (json == null || _readStoredInt(json['version']) != _version) {
      return null;
    }

    final currentObject = asJsonObject(json['currentTrack']);
    if (currentObject == null) return null;
    final currentTrack = MusicTrack.fromJson(currentObject);
    if (!currentTrack.canPlay) return null;
    return _PersistedCurrentTrack(currentTrack: currentTrack);
  }
}

int? _readStoredInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

Uri? _findAudioUri(KugouJsonObject body) {
  Uri? fromValue(Object? value) {
    if (value is String) {
      final uri = Uri.tryParse(value);
      if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
        return uri;
      }
    }
    for (final item in asJsonList(value)) {
      final uri = fromValue(item);
      if (uri != null) return uri;
    }
    return null;
  }

  for (final key in const <String>['url', 'play_url', 'backup_url']) {
    final uri = fromValue(body[key]);
    if (uri != null) return uri;
  }
  final data = asJsonObject(body['data']);
  if (data == null) return null;
  for (final key in const <String>['url', 'play_url', 'backup_url']) {
    final uri = fromValue(data[key]);
    if (uri != null) return uri;
  }
  return null;
}

List<_PlaybackCandidate> _parsePrivilegeCandidates(
  KugouJsonObject body,
  KugouPlaybackQuality preferredQuality,
) {
  final qualities = playbackQualityFallbackChain(preferredQuality);
  final variants = <_PlaybackCandidate>[];
  final seen = <String>{};
  for (final rawItem in asJsonList(body['data'])) {
    final item = asJsonObject(rawItem);
    if (item == null) continue;
    for (final rawVariant in <Object?>[
      item,
      ...asJsonList(item['relate_goods']),
    ]) {
      final variant = asJsonObject(rawVariant);
      if (variant == null || _isUnavailablePrivilege(variant['level'])) {
        continue;
      }
      final hash = readString(variant, const <String>['hash']);
      final quality = _qualityFromWire(
        readString(variant, const <String>['quality']),
      );
      if (hash.isEmpty || quality == null) continue;
      final key = '${hash.toLowerCase()}:${quality.wireValue}';
      if (seen.add(key)) {
        variants.add(_PlaybackCandidate(hash: hash, quality: quality));
      }
    }
  }
  final byQuality = <KugouPlaybackQuality, List<_PlaybackCandidate>>{};
  for (final candidate in variants) {
    (byQuality[candidate.quality] ??= <_PlaybackCandidate>[]).add(candidate);
  }
  return <_PlaybackCandidate>[
    for (final quality in qualities) ...?byQuality[quality],
  ];
}

bool _isUnavailablePrivilege(Object? level) => switch (level) {
  final num value => value == 0,
  final String value => num.tryParse(value) == 0,
  _ => false,
};

KugouPlaybackQuality? _qualityFromWire(String value) {
  for (final quality in KugouPlaybackQuality.values) {
    if (quality.wireValue == value) return quality;
  }
  return null;
}

bool _isMp4Response(KugouJsonObject body) {
  final direct = readString(body, const <String>['extName', 'extname']);
  if (direct.toLowerCase() == 'mp4') return true;
  final data = asJsonObject(body['data']);
  if (data == null) return false;
  return readString(data, const <String>['extName', 'extname']).toLowerCase() ==
      'mp4';
}

final class _PlaybackCandidate {
  const _PlaybackCandidate({required this.hash, required this.quality});

  final String hash;
  final KugouPlaybackQuality quality;
}

final class _ResolvedPlaybackSource {
  const _ResolvedPlaybackSource({required this.uri, required this.quality});

  final Uri uri;
  final KugouPlaybackQuality quality;
}

List<_PlaybackCandidate> _fallbackPlaybackCandidates(
  String hash,
  KugouPlaybackQuality maximum,
) => playbackQualityFallbackChain(maximum)
    .map((quality) => _PlaybackCandidate(hash: hash, quality: quality))
    .toList(growable: false);

KugouPlaybackQuality _defaultPreferredPlaybackQuality() =>
    KugouPlaybackQuality.standard;

String _friendlyPlaybackError(Object error) {
  if (error is KugouTransportException) return '网络连接失败，无法获取歌曲';
  if (error is KugouApiException) {
    final body = asJsonObject(error.response.body);
    final code = body == null
        ? 0
        : readInt(body, const <String>['error_code', 'errcode', 'code']);
    final message = body == null
        ? ''
        : readString(body, const <String>['error', 'msg', 'message', 'data']);
    if (code == 20028 || _riskEventId(error).isNotEmpty) {
      return '酷狗要求完成安全验证（20028），请重新播放；若持续出现请重新登录';
    }
    if (code == 20018) {
      return '当前酷狗登录凭据无效或与所选客户端不匹配（20018），请重新登录';
    }
    if (code == 20006) return '酷狗拒绝了歌曲地址请求签名（20006）';
    final detail = <String>[
      if (code != 0) '$code',
      if (message.isNotEmpty) message,
    ].join('：');
    return detail.isEmpty ? '歌曲地址解析失败' : '歌曲地址解析失败（酷狗返回 $detail）';
  }
  return error.toString().replaceFirst('Bad state: ', '');
}

String _riskEventId(KugouApiException error) {
  final body = asJsonObject(error.response.body);
  if (body != null) {
    final direct = readString(body, const <String>['ssaCode', 'ssa_code']);
    if (direct.isNotEmpty) return direct;
    final data = asJsonObject(body['data']);
    if (data != null) {
      final nested = readString(data, const <String>['ssaCode', 'ssa_code']);
      if (nested.isNotEmpty) return nested;
    }
  }
  return error.response.headers['ssa-code'] ?? '';
}
