import 'dart:async';

import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/features/music/music_models.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves a KuGou URL, opens it, and stores recent history', () async {
    final transport = _SongUrlTransport();
    final api = KugouApi(
      session: KugouSession(
        cookies: const <String, String>{'dfid': 'registered-device'},
      ),
      transport: transport,
    );
    final backend = LocalMusicBackend(api);
    final engine = _RecordingAudioEngine();
    final store = MemoryKeyValueStore();
    final controller = PlaybackController(backend, engine, store);
    addTearDown(() {
      controller.onClose();
      unawaited(backend.close());
    });
    const track = MusicTrack(
      id: '1',
      hash: 'ABCDEF',
      title: 'Test Song',
      artist: 'Test Singer',
    );

    await controller.playTrack(track);

    expect(engine.opened, Uri.parse('https://audio.example/song.mp3'));
    expect(controller.currentTrack, same(track));
    expect(controller.recentTracks, <MusicTrack>[track]);
    expect(store.read('recent_tracks'), isA<String>());
    expect(transport.requests.single.uri.path, '/v5/url');
  });

  test('advances to the next queued track when playback completes', () async {
    final transport = _SongUrlTransport();
    final api = KugouApi(
      session: KugouSession(
        cookies: const <String, String>{'dfid': 'registered-device'},
      ),
      transport: transport,
    );
    final backend = LocalMusicBackend(api);
    final engine = _RecordingAudioEngine();
    final controller = PlaybackController(
      backend,
      engine,
      MemoryKeyValueStore(),
    );
    addTearDown(() {
      controller.onClose();
      unawaited(backend.close());
    });
    const first = MusicTrack(
      id: '1',
      hash: 'FIRST',
      title: 'First Song',
      artist: 'Test Singer',
    );
    const second = MusicTrack(
      id: '2',
      hash: 'SECOND',
      title: 'Second Song',
      artist: 'Test Singer',
    );

    await controller.playTrack(first, queue: const <MusicTrack>[first, second]);
    engine.emitCompleted();
    await Future<void>.delayed(Duration.zero);

    expect(controller.currentTrack, same(second));
    expect(transport.requests, hasLength(2));
    expect(engine.openCount, 2);
  });

  test('list loop wraps from the last queued track to the first', () async {
    final fixture = _PlaybackFixture();
    addTearDown(fixture.dispose);
    const first = MusicTrack(
      id: '1',
      hash: 'FIRST',
      title: 'First Song',
      artist: 'Test Singer',
    );
    const second = MusicTrack(
      id: '2',
      hash: 'SECOND',
      title: 'Second Song',
      artist: 'Test Singer',
    );

    await fixture.controller.playTrack(
      second,
      queue: const <MusicTrack>[first, second],
    );
    fixture.engine.emitCompleted();
    await Future<void>.delayed(Duration.zero);

    expect(fixture.controller.playbackMode, PlaybackMode.listLoop);
    expect(fixture.controller.currentTrack, same(first));
    expect(fixture.engine.openCount, 2);
  });

  test('single loop replays without resolving the song URL again', () async {
    final fixture = _PlaybackFixture();
    addTearDown(fixture.dispose);
    const first = MusicTrack(
      id: '1',
      hash: 'FIRST',
      title: 'First Song',
      artist: 'Test Singer',
    );
    const second = MusicTrack(
      id: '2',
      hash: 'SECOND',
      title: 'Second Song',
      artist: 'Test Singer',
    );

    await fixture.controller.playTrack(
      first,
      queue: const <MusicTrack>[first, second],
    );
    await fixture.controller.setPlaybackMode(PlaybackMode.singleLoop);
    fixture.engine.emitCompleted();
    await Future<void>.delayed(Duration.zero);

    expect(fixture.controller.currentTrack, same(first));
    expect(fixture.engine.openCount, 1);
    expect(fixture.engine.replayCount, 1);
  });

  test('shuffle advances to another song and keeps previous history', () async {
    final fixture = _PlaybackFixture();
    addTearDown(fixture.dispose);
    const first = MusicTrack(
      id: '1',
      hash: 'FIRST',
      title: 'First Song',
      artist: 'Test Singer',
    );
    const second = MusicTrack(
      id: '2',
      hash: 'SECOND',
      title: 'Second Song',
      artist: 'Test Singer',
    );

    await fixture.controller.playTrack(
      first,
      queue: const <MusicTrack>[first, second],
    );
    await fixture.controller.setPlaybackMode(PlaybackMode.shuffle);
    await fixture.controller.next();
    expect(fixture.controller.currentTrack, same(second));

    await fixture.controller.previous();
    expect(fixture.controller.currentTrack, same(first));
  });

  test('sequential playback stops after the final queued track', () async {
    final fixture = _PlaybackFixture();
    addTearDown(fixture.dispose);
    const first = MusicTrack(
      id: '1',
      hash: 'FIRST',
      title: 'First Song',
      artist: 'Test Singer',
    );
    const second = MusicTrack(
      id: '2',
      hash: 'SECOND',
      title: 'Second Song',
      artist: 'Test Singer',
    );

    await fixture.controller.playTrack(
      second,
      queue: const <MusicTrack>[first, second],
    );
    await fixture.controller.setPlaybackMode(PlaybackMode.sequential);
    fixture.engine.emitCompleted();
    await Future<void>.delayed(Duration.zero);

    expect(fixture.controller.currentTrack, same(second));
    expect(fixture.controller.canGoNext, isFalse);
    expect(fixture.engine.openCount, 1);
    expect(fixture.engine.replayCount, 0);
  });

  test('persists the selected playback mode by enum wire name', () async {
    final store = MemoryKeyValueStore();
    final first = _PlaybackFixture(store: store);
    await first.controller.setPlaybackMode(PlaybackMode.singleLoop);
    first.dispose();

    final restored = _PlaybackFixture(store: store);
    addTearDown(restored.dispose);
    expect(restored.controller.playbackMode, PlaybackMode.singleLoop);
  });

  test('uses the logged-in privilege hash before resolving a URL', () async {
    final transport = _VipSongUrlTransport();
    final session = KugouSession(
      variant: KugouClientVariant.lite,
      cookies: const <String, String>{
        'dfid': 'registered-device',
        'token': 'token',
        'userid': '42',
      },
    );
    final api = KugouApi(
      config: const KugouApiConfig(variant: KugouClientVariant.lite),
      session: session,
      transport: transport,
    );
    final backend = LocalMusicBackend(api);
    final engine = _RecordingAudioEngine();
    final controller = PlaybackController(
      backend,
      engine,
      MemoryKeyValueStore(),
    );
    addTearDown(() {
      controller.onClose();
      unawaited(backend.close());
    });
    const track = MusicTrack(
      id: '1',
      hash: 'ORIGINAL',
      title: 'VIP Song',
      artist: 'Test Singer',
      albumId: 7,
    );

    await controller.playTrack(track);

    expect(transport.requests, hasLength(2));
    expect(transport.requests[0].uri.path, '/v2/get_res_privilege/lite');
    expect(transport.requests[1].uri.path, '/v5/url');
    expect(transport.requests[1].parameters['hash'], 'vip128');
    expect(engine.opened, Uri.parse('https://audio.example/vip.mp3'));
    expect(controller.error, isNull);
  });

  test('explains a platform-incompatible login response', () async {
    final api = KugouApi(
      config: const KugouApiConfig(variant: KugouClientVariant.lite),
      session: KugouSession(
        variant: KugouClientVariant.lite,
        cookies: const <String, String>{
          'dfid': 'registered-device',
          'token': 'token',
          'userid': '42',
        },
      ),
      transport: _RejectedVipSongUrlTransport(),
    );
    final backend = LocalMusicBackend(api);
    final engine = _RecordingAudioEngine();
    final controller = PlaybackController(
      backend,
      engine,
      MemoryKeyValueStore(),
    );
    addTearDown(() {
      controller.onClose();
      unawaited(backend.close());
    });

    await controller.playTrack(
      const MusicTrack(
        id: '1',
        hash: 'VIP128',
        title: 'VIP Song',
        artist: 'Test Singer',
      ),
    );

    expect(controller.error, contains('与所选客户端不匹配（20018）'));
    expect(engine.opened, isNull);
  });
}

final class _PlaybackFixture {
  _PlaybackFixture({MemoryKeyValueStore? store}) {
    final api = KugouApi(
      session: KugouSession(
        cookies: const <String, String>{'dfid': 'registered-device'},
      ),
      transport: _SongUrlTransport(),
    );
    backend = LocalMusicBackend(api);
    engine = _RecordingAudioEngine();
    controller = PlaybackController(
      backend,
      engine,
      store ?? MemoryKeyValueStore(),
    );
  }

  late final LocalMusicBackend backend;
  late final _RecordingAudioEngine engine;
  late final PlaybackController controller;

  void dispose() {
    controller.onClose();
    unawaited(backend.close());
  }
}

final class _SongUrlTransport implements KugouHttpTransport {
  final List<KugouHttpRequest> requests = <KugouHttpRequest>[];

  @override
  Future<KugouRawResponse> send(KugouHttpRequest request) async {
    requests.add(request);
    return const KugouRawResponse(
      statusCode: 200,
      body: <String, Object?>{
        'status': 1,
        'url': <Object?>['https://audio.example/song.mp3'],
      },
    );
  }

  @override
  void close() {}
}

final class _VipSongUrlTransport implements KugouHttpTransport {
  final List<KugouHttpRequest> requests = <KugouHttpRequest>[];

  @override
  Future<KugouRawResponse> send(KugouHttpRequest request) async {
    requests.add(request);
    if (request.uri.path == '/v2/get_res_privilege/lite') {
      return const KugouRawResponse(
        statusCode: 200,
        body: <String, Object?>{
          'status': 1,
          'data': <Object?>[
            <String, Object?>{
              'hash': 'ORIGINAL',
              'quality': '128',
              'level': 0,
              'relate_goods': <Object?>[
                <String, Object?>{
                  'hash': 'VIP128',
                  'quality': '128',
                  'level': 1,
                },
              ],
            },
          ],
        },
      );
    }
    return const KugouRawResponse(
      statusCode: 200,
      body: <String, Object?>{
        'status': 1,
        'url': <Object?>['https://audio.example/vip.mp3'],
      },
    );
  }

  @override
  void close() {}
}

final class _RejectedVipSongUrlTransport implements KugouHttpTransport {
  @override
  Future<KugouRawResponse> send(KugouHttpRequest request) async {
    if (request.uri.path == '/v2/get_res_privilege/lite') {
      return const KugouRawResponse(
        statusCode: 200,
        body: <String, Object?>{
          'status': 1,
          'data': <Object?>[
            <String, Object?>{'hash': 'VIP128', 'quality': '128', 'level': 1},
          ],
        },
      );
    }
    return const KugouRawResponse(
      statusCode: 200,
      body: <String, Object?>{'status': 2, 'error_code': 20018},
    );
  }

  @override
  void close() {}
}

final class _RecordingAudioEngine implements AudioEngine {
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

  Uri? opened;
  int openCount = 0;
  int replayCount = 0;

  void emitCompleted() => _completed.add(true);

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
    opened = uri;
    openCount += 1;
    _playing.add(true);
  }

  @override
  Future<void> playOrPause() async {}

  @override
  Future<void> replay() async {
    replayCount += 1;
    _playing.add(true);
  }

  @override
  Future<void> seek(Duration position) async {
    _position.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume.add(volume);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
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
