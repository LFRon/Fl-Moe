import 'dart:async';

import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not create the delegate before the first open', () async {
    final delegate = _RecordingAudioEngine();
    var creationCount = 0;
    final engine = LazyAudioEngine(() {
      creationCount += 1;
      return delegate;
    });
    addTearDown(engine.dispose);

    await engine.setVolume(72);
    await engine.playOrPause();
    await engine.replay();
    await engine.seek(const Duration(seconds: 12));
    await engine.stop();

    expect(creationCount, 0);
    expect(delegate.operations, isEmpty);

    final firstUri = Uri.parse('https://audio.example/first.mp3');
    await engine.open(firstUri);
    await engine.open(Uri.parse('https://audio.example/second.mp3'));

    expect(creationCount, 1);
    expect(delegate.operations, <String>[
      'volume:72.0',
      'open:$firstUri',
      'open:https://audio.example/second.mp3',
    ]);
  });

  test('shares one initialization across concurrent open calls', () async {
    final volumeGate = Completer<void>();
    final delegate = _RecordingAudioEngine(volumeGate: volumeGate);
    var creationCount = 0;
    final engine = LazyAudioEngine(() {
      creationCount += 1;
      return delegate;
    });
    addTearDown(engine.dispose);

    await engine.setVolume(40);
    final firstOpen = engine.open(Uri.parse('https://audio.example/one.mp3'));
    await Future<void>.delayed(Duration.zero);
    final secondOpen = engine.open(Uri.parse('https://audio.example/two.mp3'));
    final latestVolume = engine.setVolume(55);

    expect(creationCount, 1);
    volumeGate.complete();
    await Future.wait<void>(<Future<void>>[
      firstOpen,
      secondOpen,
      latestVolume,
    ]);

    expect(creationCount, 1);
    expect(delegate.operations, <String>[
      'volume:40.0',
      'volume:55.0',
      'open:https://audio.example/one.mp3',
      'open:https://audio.example/two.mp3',
    ]);
  });

  test(
    'forwards delegate events to listeners registered before open',
    () async {
      final delegate = _RecordingAudioEngine();
      final engine = LazyAudioEngine(() => delegate);
      addTearDown(engine.dispose);

      final playing = expectLater(engine.playing, emits(true));
      final buffering = expectLater(engine.buffering, emits(true));
      final completed = expectLater(engine.completed, emits(true));
      final position = expectLater(
        engine.position,
        emits(const Duration(seconds: 3)),
      );
      final duration = expectLater(
        engine.duration,
        emits(const Duration(minutes: 4)),
      );
      final volume = expectLater(engine.volume, emits(64.0));
      final error = expectLater(engine.errors, emits('decoder failed'));

      await engine.open(Uri.parse('https://audio.example/song.flac'));
      delegate.emitEvents();

      await Future.wait<void>(<Future<void>>[
        playing,
        buffering,
        completed,
        position,
        duration,
        volume,
        error,
      ]);
    },
  );

  test('disposing an unused engine never creates its delegate', () async {
    var creationCount = 0;
    final engine = LazyAudioEngine(() {
      creationCount += 1;
      return _RecordingAudioEngine();
    });

    await engine.dispose();

    expect(creationCount, 0);
    await expectLater(
      engine.open(Uri.parse('https://audio.example/song.mp3')),
      throwsStateError,
    );
  });
}

final class _RecordingAudioEngine implements AudioEngine {
  _RecordingAudioEngine({this.volumeGate});

  final Completer<void>? volumeGate;
  final List<String> operations = <String>[];
  final StreamController<bool> _playing = StreamController<bool>.broadcast(
    sync: true,
  );
  final StreamController<bool> _buffering = StreamController<bool>.broadcast(
    sync: true,
  );
  final StreamController<bool> _completed = StreamController<bool>.broadcast(
    sync: true,
  );
  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast(sync: true);
  final StreamController<Duration> _duration =
      StreamController<Duration>.broadcast(sync: true);
  final StreamController<double> _volume = StreamController<double>.broadcast(
    sync: true,
  );
  final StreamController<String> _errors = StreamController<String>.broadcast(
    sync: true,
  );
  bool _disposed = false;

  void emitEvents() {
    _playing.add(true);
    _buffering.add(true);
    _completed.add(true);
    _position.add(const Duration(seconds: 3));
    _duration.add(const Duration(minutes: 4));
    _volume.add(64);
    _errors.add('decoder failed');
  }

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<bool> get buffering => _buffering.stream;

  @override
  Stream<bool> get completed => _completed.stream;

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<Duration> get duration => _duration.stream;

  @override
  Stream<double> get volume => _volume.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  Future<void> open(Uri uri) async {
    operations.add('open:$uri');
  }

  @override
  Future<void> playOrPause() async {
    operations.add('playOrPause');
  }

  @override
  Future<void> replay() async {
    operations.add('replay');
  }

  @override
  Future<void> seek(Duration position) async {
    operations.add('seek:${position.inMilliseconds}');
  }

  @override
  Future<void> setVolume(double volume) async {
    operations.add('volume:$volume');
    final gate = volumeGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> stop() async {
    operations.add('stop');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await Future.wait<void>(<Future<void>>[
      _playing.close(),
      _buffering.close(),
      _completed.close(),
      _position.close(),
      _duration.close(),
      _volume.close(),
      _errors.close(),
    ]);
  }
}
