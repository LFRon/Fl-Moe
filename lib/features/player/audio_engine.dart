import 'dart:async';

import 'package:media_kit/media_kit.dart';

typedef AudioEngineFactory = AudioEngine Function();

abstract interface class AudioEngine {
  Stream<bool> get playing;
  Stream<bool> get buffering;
  Stream<bool> get completed;
  Stream<Duration> get position;
  Stream<Duration> get duration;
  Stream<double> get volume;
  Stream<String> get errors;

  Future<void> open(Uri uri);
  Future<void> playOrPause();
  Future<void> replay();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}

/// Defers construction of a potentially expensive native audio backend until
/// [open] is called for the first time.
///
/// Volume changes are remembered before activation. Other transport commands
/// are harmless no-ops until a media source has been opened.
base class LazyAudioEngine implements AudioEngine {
  LazyAudioEngine(this._factory);

  final AudioEngineFactory _factory;
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast(sync: true);
  final StreamController<bool> _bufferingController =
      StreamController<bool>.broadcast(sync: true);
  final StreamController<bool> _completedController =
      StreamController<bool>.broadcast(sync: true);
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast(sync: true);
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast(sync: true);
  final StreamController<double> _volumeController =
      StreamController<double>.broadcast(sync: true);
  final StreamController<String> _errorsController =
      StreamController<String>.broadcast(sync: true);

  AudioEngine? _delegate;
  Future<AudioEngine>? _initializing;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<String>? _errorsSubscription;
  double _desiredVolume = 100;
  bool _disposed = false;

  @override
  Stream<bool> get playing => _playingController.stream;

  @override
  Stream<bool> get buffering => _bufferingController.stream;

  @override
  Stream<bool> get completed => _completedController.stream;

  @override
  Stream<Duration> get position => _positionController.stream;

  @override
  Stream<Duration> get duration => _durationController.stream;

  @override
  Stream<double> get volume => _volumeController.stream;

  @override
  Stream<String> get errors => _errorsController.stream;

  @override
  Future<void> open(Uri uri) async {
    final delegate = await _ensureDelegate();
    await delegate.open(uri);
  }

  @override
  Future<void> playOrPause() async {
    final delegate = await _readyDelegate();
    if (delegate != null) await delegate.playOrPause();
  }

  @override
  Future<void> replay() async {
    final delegate = await _readyDelegate();
    if (delegate != null) await delegate.replay();
  }

  @override
  Future<void> seek(Duration position) async {
    final delegate = await _readyDelegate();
    if (delegate != null) await delegate.seek(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _throwIfDisposed();
    _desiredVolume = volume;
    final delegate = _delegate;
    if (delegate != null) {
      await delegate.setVolume(volume);
      return;
    }
    // Initialization applies the latest desired value before completing. Wait
    // for it when activation is already in progress without starting it here.
    final initializing = _initializing;
    if (initializing != null) await initializing;
  }

  @override
  Future<void> stop() async {
    final delegate = await _readyDelegate();
    if (delegate != null) await delegate.stop();
  }

  Future<AudioEngine> _ensureDelegate() {
    if (_disposed) {
      return Future<AudioEngine>.error(
        StateError('Audio engine has already been disposed.'),
      );
    }
    final delegate = _delegate;
    if (delegate != null) return Future<AudioEngine>.value(delegate);
    final initializing = _initializing;
    if (initializing != null) return initializing;
    final future = _initializeDelegate();
    _initializing = future;
    return future;
  }

  Future<AudioEngine?> _readyDelegate() async {
    _throwIfDisposed();
    final delegate = _delegate;
    if (delegate != null) return delegate;
    final initializing = _initializing;
    if (initializing == null) return null;
    return initializing;
  }

  Future<AudioEngine> _initializeDelegate() async {
    AudioEngine? candidate;
    try {
      candidate = _factory();
      _bind(candidate);
      while (true) {
        final desiredVolume = _desiredVolume;
        await candidate.setVolume(desiredVolume);
        if (desiredVolume == _desiredVolume) break;
      }
      if (_disposed) {
        throw StateError('Audio engine was disposed while initializing.');
      }
      _delegate = candidate;
      _initializing = null;
      return candidate;
    } on Object catch (error, stackTrace) {
      await _cancelSubscriptions();
      if (candidate != null) {
        try {
          await candidate.dispose();
        } on Object {
          // Preserve the initialization failure as the actionable error.
        }
      }
      _initializing = null;
      if (!_disposed && !_errorsController.isClosed) {
        _errorsController.add(error.toString());
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _bind(AudioEngine delegate) {
    _playingSubscription = delegate.playing.listen(_playingController.add);
    _bufferingSubscription = delegate.buffering.listen(
      _bufferingController.add,
    );
    _completedSubscription = delegate.completed.listen(
      _completedController.add,
    );
    _positionSubscription = delegate.position.listen(_positionController.add);
    _durationSubscription = delegate.duration.listen(_durationController.add);
    _volumeSubscription = delegate.volume.listen(_volumeController.add);
    _errorsSubscription = delegate.errors.listen(_errorsController.add);
  }

  Future<void> _cancelSubscriptions() async {
    final futures = <Future<void>>[
      if (_playingSubscription != null) _playingSubscription!.cancel(),
      if (_bufferingSubscription != null) _bufferingSubscription!.cancel(),
      if (_completedSubscription != null) _completedSubscription!.cancel(),
      if (_positionSubscription != null) _positionSubscription!.cancel(),
      if (_durationSubscription != null) _durationSubscription!.cancel(),
      if (_volumeSubscription != null) _volumeSubscription!.cancel(),
      if (_errorsSubscription != null) _errorsSubscription!.cancel(),
    ];
    await Future.wait<void>(futures);
    _playingSubscription = null;
    _bufferingSubscription = null;
    _completedSubscription = null;
    _positionSubscription = null;
    _durationSubscription = null;
    _volumeSubscription = null;
    _errorsSubscription = null;
  }

  void _throwIfDisposed() {
    if (_disposed) throw StateError('Audio engine has already been disposed.');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final initializing = _initializing;
    if (_delegate == null && initializing != null) {
      try {
        await initializing;
      } on Object {
        // Initialization owns cleanup of a partially constructed delegate.
      }
    }
    await _cancelSubscriptions();
    final delegate = _delegate;
    _delegate = null;
    if (delegate != null) await delegate.dispose();
    await Future.wait<void>(<Future<void>>[
      _playingController.close(),
      _bufferingController.close(),
      _completedController.close(),
      _positionController.close(),
      _durationController.close(),
      _volumeController.close(),
      _errorsController.close(),
    ]);
  }
}

/// MediaKit-backed engine whose native player is created on first playback.
final class MediaKitAudioEngine extends LazyAudioEngine {
  MediaKitAudioEngine() : super(_createMediaKitDelegate);

  static AudioEngine _createMediaKitDelegate() {
    MediaKit.ensureInitialized();
    return _MediaKitAudioEngineDelegate();
  }
}

final class _MediaKitAudioEngineDelegate implements AudioEngine {
  _MediaKitAudioEngineDelegate() : _player = Player();

  final Player _player;

  @override
  Stream<bool> get playing => _player.stream.playing;

  @override
  Stream<bool> get buffering => _player.stream.buffering;

  @override
  Stream<bool> get completed => _player.stream.completed;

  @override
  Stream<Duration> get position => _player.stream.position;

  @override
  Stream<Duration> get duration => _player.stream.duration;

  @override
  Stream<double> get volume => _player.stream.volume;

  @override
  Stream<String> get errors => _player.stream.error;

  @override
  Future<void> open(Uri uri) => _player.open(Media(uri.toString()));

  @override
  Future<void> playOrPause() => _player.playOrPause();

  @override
  Future<void> replay() async {
    await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

final class NoopAudioEngine implements AudioEngine {
  NoopAudioEngine();

  @override
  Stream<bool> get playing => const Stream<bool>.empty();

  @override
  Stream<bool> get buffering => const Stream<bool>.empty();

  @override
  Stream<bool> get completed => const Stream<bool>.empty();

  @override
  Stream<Duration> get position => const Stream<Duration>.empty();

  @override
  Stream<Duration> get duration => const Stream<Duration>.empty();

  @override
  Stream<double> get volume => const Stream<double>.empty();

  @override
  Stream<String> get errors => const Stream<String>.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> open(Uri uri) async {}

  @override
  Future<void> playOrPause() async {}

  @override
  Future<void> replay() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> stop() async {}
}
