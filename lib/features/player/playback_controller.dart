import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';

import '../../core/backend/music_backend.dart';
import '../../core/storage/key_value_store.dart';
import '../../kugou_api.dart';
import '../music/music_models.dart';
import 'audio_engine.dart';

enum PlaybackMode { shuffle, listLoop, singleLoop, sequential }

final class PlaybackController extends GetxController {
  PlaybackController(
    this._api,
    this._engine,
    this._libraryStore, {
    Random? random,
  }) : _random = random ?? Random() {
    _restoreRecentTracks();
    _restorePlaybackMode();
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
    _positionSubscription = _engine.position.listen((value) {
      _position = value;
      update();
    });
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

  final MusicBackend _api;
  final AudioEngine _engine;
  final KeyValueStore _libraryStore;
  final Random _random;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<String>? _errorSubscription;

  List<MusicTrack> _queue = const <MusicTrack>[];
  List<MusicTrack> _recentTracks = const <MusicTrack>[];
  final List<int> _shuffleHistory = <int>[];
  int _currentIndex = -1;
  PlaybackMode _playbackMode = PlaybackMode.listLoop;
  MusicTrack? _currentTrack;
  bool _playing = false;
  bool _buffering = false;
  bool _resolving = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 70;
  String? _error;
  bool _handlingCompletion = false;

  List<MusicTrack> get queue => _queue;
  List<MusicTrack> get recentTracks => _recentTracks;
  PlaybackMode get playbackMode => _playbackMode;
  MusicTrack? get currentTrack => _currentTrack;
  bool get playing => _playing;
  bool get buffering => _buffering;
  bool get resolving => _resolving;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  String? get error => _error;
  bool get _hasCurrentQueueItem =>
      _currentIndex >= 0 && _currentIndex < _queue.length;
  bool get canGoPrevious => switch (_playbackMode) {
    PlaybackMode.sequential => _currentIndex > 0,
    _ => _hasCurrentQueueItem && _queue.length > 1,
  };
  bool get canGoNext => switch (_playbackMode) {
    PlaybackMode.sequential =>
      _hasCurrentQueueItem && _currentIndex < _queue.length - 1,
    _ => _hasCurrentQueueItem && _queue.length > 1,
  };

  Future<void> playTrack(MusicTrack track, {List<MusicTrack>? queue}) async {
    if (!track.canPlay) return;
    if (queue != null && queue.isNotEmpty) {
      final trackIndex = queue.indexWhere((item) => item.hash == track.hash);
      if (trackIndex >= 0) {
        _queue = List<MusicTrack>.unmodifiable(queue);
        _currentIndex = trackIndex;
      } else {
        _queue = List<MusicTrack>.unmodifiable(<MusicTrack>[
          track,
          ...queue.where((item) => item.hash != track.hash),
        ]);
        _currentIndex = 0;
      }
    } else {
      _queue = List<MusicTrack>.unmodifiable(<MusicTrack>[track]);
      _currentIndex = 0;
    }
    _shuffleHistory.clear();
    await _startTrack(track);
  }

  Future<void> _startTrack(MusicTrack track) async {
    _currentTrack = track;
    _position = Duration.zero;
    _duration = track.duration;
    _error = null;
    _resolving = true;
    update();
    try {
      final uri = await _resolvePlaybackUri(track);
      await _engine.open(uri);
      await _remember(track);
    } on Object catch (error) {
      _error = _friendlyPlaybackError(error);
    } finally {
      _resolving = false;
      update();
    }
  }

  Future<Uri> _resolvePlaybackUri(MusicTrack track) async {
    // The reference client registers its emulated Android device during app
    // bootstrap. Await the shared request here as well so /song/url never races
    // it and falls back to an untrusted random dfid.
    await _api.ensureDeviceRegistered();
    final loggedIn = _api.sessionState.isLoggedIn;
    final candidates = loggedIn
        ? await _privilegedCandidates(track)
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
        if (uri != null && !_isMp4Response(response.body)) return uri;
      } on Object catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) throw lastError;
    throw StateError('酷狗没有返回可播放地址，可能需要切换音源或检查会员权限');
  }

  Future<List<_PlaybackCandidate>> _privilegedCandidates(
    MusicTrack track,
  ) async {
    try {
      final response = await _api.songPrivileges(
        KugouSongPrivilegeQuery(hash: track.hash, albumId: track.albumId),
      );
      final candidates = _parsePrivilegeCandidates(
        response.body,
        KugouPlaybackQuality.standard,
      );
      if (candidates.isNotEmpty) return candidates;
    } on Object {
      // The legacy URL endpoint can still succeed when privilege metadata is
      // temporarily unavailable, so retain the original hash as a fallback.
    }
    return <_PlaybackCandidate>[
      _PlaybackCandidate(
        hash: track.hash,
        quality: KugouPlaybackQuality.standard,
      ),
    ];
  }

  Future<void> toggle() async {
    if (_currentTrack == null || _resolving) return;
    await _engine.playOrPause();
  }

  Future<void> previous() async {
    if (!canGoPrevious) return;
    final previousIndex = switch (_playbackMode) {
      PlaybackMode.shuffle =>
        _shuffleHistory.isNotEmpty
            ? _shuffleHistory.removeLast()
            : _randomQueueIndex(),
      PlaybackMode.sequential => _currentIndex - 1,
      PlaybackMode.listLoop || PlaybackMode.singleLoop =>
        (_currentIndex - 1 + _queue.length) % _queue.length,
    };
    await _playQueueIndex(previousIndex, rememberCurrent: false);
  }

  Future<void> next() async {
    if (!canGoNext) return;
    final nextIndex = switch (_playbackMode) {
      PlaybackMode.shuffle => _randomQueueIndex(),
      PlaybackMode.sequential => _currentIndex + 1,
      PlaybackMode.listLoop ||
      PlaybackMode.singleLoop => (_currentIndex + 1) % _queue.length,
    };
    await _playQueueIndex(nextIndex);
  }

  Future<void> setPlaybackMode(PlaybackMode value) async {
    if (_playbackMode == value) return;
    _playbackMode = value;
    _shuffleHistory.clear();
    update();
    await _libraryStore.write(_playbackModeKey, value.name);
  }

  Future<void> seek(Duration value) async {
    final safe = value < Duration.zero
        ? Duration.zero
        : value > _duration
        ? _duration
        : value;
    _position = safe;
    update();
    await _engine.seek(safe);
  }

  Future<void> setVolume(double value) async {
    final safe = value.clamp(0, 100).toDouble();
    _volume = safe;
    update();
    await _engine.setVolume(safe);
  }

  Future<void> _handleCompleted() async {
    if (_handlingCompletion || !_hasCurrentQueueItem) return;
    _handlingCompletion = true;
    try {
      switch (_playbackMode) {
        case PlaybackMode.singleLoop:
          await _replayCurrent();
          break;
        case PlaybackMode.listLoop:
          if (_queue.length == 1) {
            await _replayCurrent();
          } else {
            await _playQueueIndex((_currentIndex + 1) % _queue.length);
          }
          break;
        case PlaybackMode.shuffle:
          if (_queue.length == 1) {
            await _replayCurrent();
          } else {
            await _playQueueIndex(_randomQueueIndex());
          }
          break;
        case PlaybackMode.sequential:
          if (_currentIndex < _queue.length - 1) {
            await _playQueueIndex(_currentIndex + 1);
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

  int _randomQueueIndex() {
    final offset = _random.nextInt(_queue.length - 1) + 1;
    return (_currentIndex + offset) % _queue.length;
  }

  Future<void> _playQueueIndex(int index, {bool rememberCurrent = true}) async {
    if (rememberCurrent && _playbackMode == PlaybackMode.shuffle) {
      _shuffleHistory.add(_currentIndex);
      if (_shuffleHistory.length > 100) _shuffleHistory.removeAt(0);
    }
    final track = _queue[index];
    _currentIndex = index;
    await _startTrack(track);
  }

  Future<void> _remember(MusicTrack track) async {
    final updated = <MusicTrack>[
      track,
      ..._recentTracks.where((item) => item.hash != track.hash),
    ];
    _recentTracks = List<MusicTrack>.unmodifiable(updated.take(50));
    await _libraryStore.write(
      _recentKey,
      jsonEncode(_recentTracks.map((item) => item.toJson()).toList()),
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

  @override
  void onClose() {
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
  const fallbackOrder = <KugouPlaybackQuality>[
    KugouPlaybackQuality.standard,
    KugouPlaybackQuality.high,
    KugouPlaybackQuality.lossless,
    KugouPlaybackQuality.hiRes,
    KugouPlaybackQuality.atmos,
    KugouPlaybackQuality.clear,
    KugouPlaybackQuality.master,
  ];
  final preferredIndex = fallbackOrder.indexOf(preferredQuality);
  final qualities = preferredIndex < 0
      ? const <KugouPlaybackQuality>[KugouPlaybackQuality.standard]
      : fallbackOrder.take(preferredIndex + 1).toList(growable: false).reversed;
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
