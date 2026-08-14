import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../../kugou_api.dart';

typedef SessionPersistCallback =
    Future<void> Function(Map<String, Object?> session);
typedef KugouApiVariantFactory =
    KugouApi Function(KugouClientVariant variant, KugouSession session);

final class BackendSessionState {
  const BackendSessionState({
    required this.isLoggedIn,
    required this.userId,
    required this.hasRegisteredDevice,
  });

  factory BackendSessionState.fromJson(Map<String, Object?> json) {
    final session = KugouSession.fromJson(json);
    return BackendSessionState(
      isLoggedIn: session.isLoggedIn,
      userId: session.userId,
      hasRegisteredDevice: session.hasRegisteredDevice,
    );
  }

  final bool isLoggedIn;
  final String userId;
  final bool hasRegisteredDevice;
}

abstract interface class MusicBackend {
  BackendSessionState get sessionState;
  KugouClientVariant get clientVariant;

  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  });

  Future<void> clearAuthentication();

  /// Registers the emulated Android device once and persists its `dfid`.
  /// Concurrent callers share one request.
  Future<bool> ensureDeviceRegistered();

  Future<void> setClientVariant(KugouClientVariant variant);

  Future<void> flushSession();

  Future<void> close();
}

extension MusicBackendOperations on MusicBackend {
  Future<KugouResponse<KugouJsonObject>> search(KugouSearchQuery query) =>
      callJson('/search', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> hotSearch() => callJson('/search/hot');

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

  Future<KugouResponse<KugouJsonObject>> searchLyrics(
    KugouLyricSearchQuery query,
  ) => callJson('/search/lyric', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> lyrics(KugouLyricsQuery query) =>
      callJson('/lyric', parameters: query.toParameters());

  Future<KugouResponse<KugouJsonObject>> userDetail() =>
      callJson('/user/detail');

  Future<KugouResponse<KugouJsonObject>> loginQrKey({bool web = false}) =>
      callJson(
        '/login/qr/key',
        parameters: <String, Object?>{if (web) 'type': 'web'},
      );

  Future<Uri> loginQrContent(String key) async {
    if (key.isEmpty) throw ArgumentError.value(key, 'key', 'Must not be empty');
    final response = await callJson(
      '/login/qr/create',
      parameters: <String, Object?>{'key': key},
    );
    final data = _stringObjectMap(response.body['data']);
    final content = data?['content'] ?? data?['url'];
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
}

/// Direct adapter retained for deterministic tests and environments without
/// isolate support. Production uses [IsolatedMusicBackend].
final class LocalMusicBackend implements MusicBackend {
  LocalMusicBackend(KugouApi api, {this._onSessionChanged, this._apiFactory})
    : _api = api,
      _sessionState = BackendSessionState.fromJson(api.session.toJson());

  KugouApi _api;
  final SessionPersistCallback? _onSessionChanged;
  final KugouApiVariantFactory? _apiFactory;
  BackendSessionState _sessionState;
  Future<void> _persisting = Future<void>.value();
  Future<bool>? _deviceRegistration;

  @override
  BackendSessionState get sessionState => _sessionState;

  @override
  KugouClientVariant get clientVariant => _api.config.variant;

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) async {
    try {
      return await _api.callJson(route, parameters: parameters);
    } finally {
      _syncSession();
    }
  }

  @override
  Future<void> clearAuthentication() async {
    _api.session.clearAuthentication();
    _syncSession();
    await flushSession();
  }

  @override
  Future<bool> ensureDeviceRegistered() {
    if (_api.session.hasRegisteredDevice) return Future<bool>.value(true);
    final inFlight = _deviceRegistration;
    if (inFlight != null) return inFlight;
    late final Future<bool> operation;
    operation = _registerDevice().whenComplete(() {
      if (identical(_deviceRegistration, operation)) {
        _deviceRegistration = null;
      }
    });
    _deviceRegistration = operation;
    return operation;
  }

  Future<bool> _registerDevice() async {
    try {
      final response = await _api.callJson('/register/dev');
      return _isSuccessfulDeviceRegistration(response.body) &&
          _api.session.hasRegisteredDevice;
    } finally {
      _syncSession();
    }
  }

  @override
  Future<void> setClientVariant(KugouClientVariant variant) async {
    if (variant == clientVariant) return;
    final session = KugouSession.fromJson(
      _api.session.toJson(),
      variant: variant,
    );
    final replacement =
        _apiFactory?.call(variant, session) ??
        KugouApi(
          config: KugouApiConfig(variant: variant),
          session: session,
        );
    _api.close();
    _api = replacement;
    _syncSession();
    await flushSession();
  }

  void _syncSession() {
    final json = _api.session.toJson();
    _sessionState = BackendSessionState.fromJson(json);
    final callback = _onSessionChanged;
    if (callback != null) {
      _persisting = _persisting.then((_) => callback(json));
    }
  }

  @override
  Future<void> flushSession() => _persisting;

  @override
  Future<void> close() async {
    await flushSession();
    _api.close();
  }
}

/// Starts the production backend isolate without making the application shell
/// wait for it. API calls are queued on the strongly typed future and still run
/// entirely inside [IsolatedMusicBackend] once that actor is ready.
final class DeferredMusicBackend implements MusicBackend {
  DeferredMusicBackend._({
    required Future<IsolatedMusicBackend> startup,
    required Map<String, Object?> initialSession,
    required this._initialVariant,
  }) : _initialSession = BackendSessionState.fromJson(initialSession) {
    _ready = startup.then<MusicBackend>((backend) {
      _backend = backend;
      return backend;
    });
    // Observe startup failures immediately so they do not become uncaught
    // asynchronous errors. Queued API calls still receive the same failure.
    unawaited(_observeStartup(_ready));
  }

  factory DeferredMusicBackend.start({
    required Map<String, Object?> initialSession,
    required KugouClientVariant clientVariant,
    SessionPersistCallback? onSessionChanged,
  }) => DeferredMusicBackend._(
    startup: IsolatedMusicBackend.start(
      initialSession: initialSession,
      clientVariant: clientVariant,
      onSessionChanged: onSessionChanged,
    ),
    initialSession: initialSession,
    initialVariant: clientVariant,
  );

  final BackendSessionState _initialSession;
  final KugouClientVariant _initialVariant;
  late final Future<MusicBackend> _ready;
  MusicBackend? _backend;

  @override
  BackendSessionState get sessionState =>
      _backend?.sessionState ?? _initialSession;

  @override
  KugouClientVariant get clientVariant =>
      _backend?.clientVariant ?? _initialVariant;

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) async {
    final backend = await _ready;
    return backend.callJson(route, parameters: parameters);
  }

  @override
  Future<void> clearAuthentication() async {
    final backend = await _ready;
    await backend.clearAuthentication();
  }

  @override
  Future<bool> ensureDeviceRegistered() async {
    final backend = await _ready;
    return backend.ensureDeviceRegistered();
  }

  @override
  Future<void> setClientVariant(KugouClientVariant variant) async {
    final backend = await _ready;
    await backend.setClientVariant(variant);
  }

  @override
  Future<void> flushSession() async {
    final backend = await _ready;
    await backend.flushSession();
  }

  @override
  Future<void> close() async {
    try {
      final backend = await _ready;
      await backend.close();
    } on Object {
      // There is no actor to close when isolate startup itself failed.
    }
  }
}

Future<void> _observeStartup(Future<MusicBackend> startup) async {
  try {
    await startup;
  } on Object {
    // The error remains available on [startup] for every queued operation.
  }
}

/// Actor-style gateway. The complete KuGou API, Dio client, cookies, signing,
/// cryptography and JSON work live in one long-running background isolate.
final class IsolatedMusicBackend implements MusicBackend {
  IsolatedMusicBackend._(
    this._receivePort,
    this._onSessionChanged,
    Map<String, Object?> initialSession,
    this._clientVariant,
  ) : _sessionState = BackendSessionState.fromJson(initialSession);

  static Future<IsolatedMusicBackend> start({
    required Map<String, Object?> initialSession,
    KugouClientVariant clientVariant = KugouClientVariant.standard,
    SessionPersistCallback? onSessionChanged,
  }) async {
    final receivePort = ReceivePort('Fl-Moe KuGou backend responses');
    final backend = IsolatedMusicBackend._(
      receivePort,
      onSessionChanged,
      initialSession,
      clientVariant,
    );
    backend._subscription = receivePort.cast<Object?>().listen(backend._handle);
    backend._isolate = await Isolate.spawn<List<Object?>>(
      _kugouBackendIsolateMain,
      <Object?>[receivePort.sendPort, initialSession, clientVariant.name],
      debugName: 'Fl-Moe KuGou backend',
      onError: receivePort.sendPort,
      onExit: receivePort.sendPort,
      errorsAreFatal: true,
    );
    await backend._ready.future.timeout(const Duration(seconds: 10));
    return backend;
  }

  final ReceivePort _receivePort;
  final SessionPersistCallback? _onSessionChanged;
  final Completer<void> _ready = Completer<void>();
  final Map<int, Completer<KugouResponse<KugouJsonObject>>> _pending =
      <int, Completer<KugouResponse<KugouJsonObject>>>{};
  late final StreamSubscription<Object?> _subscription;
  late final Isolate _isolate;
  SendPort? _commandPort;
  BackendSessionState _sessionState;
  KugouClientVariant _clientVariant;
  Future<void> _persisting = Future<void>.value();
  Future<bool>? _deviceRegistration;
  int _nextRequestId = 1;
  bool _closed = false;

  @override
  BackendSessionState get sessionState => _sessionState;

  @override
  KugouClientVariant get clientVariant => _clientVariant;

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) => _send(kind: 'call', route: route, parameters: parameters);

  @override
  Future<void> clearAuthentication() async {
    await _send(kind: 'clearAuthentication');
    await flushSession();
  }

  @override
  Future<bool> ensureDeviceRegistered() {
    if (_sessionState.hasRegisteredDevice) return Future<bool>.value(true);
    final inFlight = _deviceRegistration;
    if (inFlight != null) return inFlight;
    late final Future<bool> operation;
    operation = _registerDevice().whenComplete(() {
      if (identical(_deviceRegistration, operation)) {
        _deviceRegistration = null;
      }
    });
    _deviceRegistration = operation;
    return operation;
  }

  Future<bool> _registerDevice() async {
    final response = await _send(kind: 'call', route: '/register/dev');
    return _isSuccessfulDeviceRegistration(response.body) &&
        _sessionState.hasRegisteredDevice;
  }

  @override
  Future<void> setClientVariant(KugouClientVariant variant) async {
    if (variant == _clientVariant) return;
    await _send(
      kind: 'setClientVariant',
      parameters: <String, Object?>{'clientVariant': variant.name},
    );
    await flushSession();
  }

  Future<KugouResponse<KugouJsonObject>> _send({
    required String kind,
    String? route,
    KugouJsonObject parameters = const <String, Object?>{},
  }) {
    if (_closed) throw StateError('The KuGou backend isolate is closed.');
    final port = _commandPort;
    if (port == null) {
      throw StateError('The KuGou backend isolate is not ready.');
    }
    final id = _nextRequestId++;
    final completer = Completer<KugouResponse<KugouJsonObject>>();
    _pending[id] = completer;
    port.send(<String, Object?>{
      'id': id,
      'kind': kind,
      'route': ?route,
      'parameters': _encodeTransferables(parameters),
    });
    return completer.future;
  }

  void _handle(Object? message) {
    if (message == null) {
      if (!_closed) {
        _failAll(StateError('The KuGou backend isolate exited unexpectedly.'));
      }
      return;
    }
    final isolateError = message is List<Object?> && message.length == 2
        ? message
        : null;
    if (isolateError != null && isolateError.first is String) {
      _failAll(
        StateError(
          'The KuGou backend isolate failed: ${isolateError.first}\n'
          '${isolateError.last}',
        ),
      );
      return;
    }
    if (message is SendPort) {
      _commandPort = message;
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    final envelope = _stringObjectMap(message);
    if (envelope == null) return;
    final id = envelope['id'];
    if (id is! int) return;
    final completer = _pending.remove(id);
    if (completer == null) return;
    final clientVariant = _clientVariantFromWire(envelope['clientVariant']);
    if (clientVariant != null) _clientVariant = clientVariant;
    final session = _stringObjectMap(envelope['session']);
    if (session != null) _syncSession(session);
    if (envelope['ok'] == true) {
      final body = _stringObjectMap(envelope['body']);
      if (body == null) {
        completer.completeError(
          const KugouUnexpectedBodyException(
            route: 'background-isolate',
            actualType: Null,
          ),
        );
        return;
      }
      completer.complete(
        KugouResponse<KugouJsonObject>(
          status: _intValue(envelope['status'], fallback: 200),
          httpStatus: _intValue(envelope['httpStatus'], fallback: 200),
          body: body,
          cookies: _stringList(envelope['cookies']),
          headers: _stringMap(envelope['headers']),
        ),
      );
      return;
    }
    completer.completeError(_remoteError(envelope));
  }

  void _failAll(Object error) {
    if (!_ready.isCompleted) _ready.completeError(error);
    for (final completer in _pending.values) {
      completer.completeError(error);
    }
    _pending.clear();
  }

  void _syncSession(Map<String, Object?> session) {
    _sessionState = BackendSessionState.fromJson(session);
    final callback = _onSessionChanged;
    if (callback != null) {
      _persisting = _persisting.then((_) => callback(session));
    }
  }

  @override
  Future<void> flushSession() => _persisting;

  @override
  Future<void> close() async {
    if (_closed) return;
    try {
      await _send(kind: 'close');
    } finally {
      _closed = true;
      await flushSession();
      for (final completer in _pending.values) {
        completer.completeError(StateError('The KuGou backend was closed.'));
      }
      _pending.clear();
      await _subscription.cancel();
      _receivePort.close();
      _isolate.kill(priority: Isolate.immediate);
    }
  }
}

@pragma('vm:entry-point')
Future<void> _kugouBackendIsolateMain(List<Object?> bootstrap) async {
  if (bootstrap.length != 3 || bootstrap[0] is! SendPort) return;
  final parent = bootstrap[0]! as SendPort;
  final initialSession = _stringObjectMap(bootstrap[1]);
  final initialVariant = _clientVariantFromWire(bootstrap[2]);
  if (initialSession == null || initialVariant == null) return;
  final commands = ReceivePort('Fl-Moe KuGou backend commands');
  var api = KugouApi(
    config: KugouApiConfig(variant: initialVariant),
    session: KugouSession.fromJson(initialSession, variant: initialVariant),
  );
  final inFlight = <Future<void>>{};
  parent.send(commands.sendPort);
  await for (final message in commands.cast<Object?>()) {
    final command = _stringObjectMap(message);
    if (command == null) continue;
    final id = command['id'];
    final kind = command['kind'];
    if (id is! int || kind is! String) continue;
    if (kind == 'clearAuthentication') {
      await Future.wait<void>(inFlight);
      api.session.clearAuthentication();
      parent.send(_successEnvelope(id, api, const <String, Object?>{}));
      continue;
    }
    if (kind == 'setClientVariant') {
      await Future.wait<void>(inFlight);
      final parameters = _stringObjectMap(command['parameters']);
      final target = _clientVariantFromWire(parameters?['clientVariant']);
      if (target == null) {
        parent.send(
          _errorEnvelope(
            id,
            api,
            ArgumentError('Unknown KuGou client variant.'),
            StackTrace.current,
          ),
        );
        continue;
      }
      if (target != api.config.variant) {
        final previous = api;
        final session = KugouSession.fromJson(
          previous.session.toJson(),
          variant: target,
        );
        api = KugouApi(
          config: KugouApiConfig(variant: target),
          session: session,
        );
        previous.close();
      }
      parent.send(_successEnvelope(id, api, const <String, Object?>{}));
      continue;
    }
    if (kind == 'close') {
      await Future.wait<void>(inFlight);
      parent.send(_successEnvelope(id, api, const <String, Object?>{}));
      api.close();
      commands.close();
      return;
    }
    late final Future<void> operation;
    operation = _processBackendCall(
      parent,
      api,
      id,
      kind,
      command,
    ).whenComplete(() => inFlight.remove(operation));
    inFlight.add(operation);
    unawaited(operation);
  }
  await Future.wait<void>(inFlight);
  api.close();
}

Future<void> _processBackendCall(
  SendPort parent,
  KugouApi api,
  int id,
  String kind,
  Map<String, Object?> command,
) async {
  try {
    final route = command['route'];
    final parameters = _stringObjectMap(
      _decodeTransferables(command['parameters']),
    );
    if (kind != 'call' || route is! String || parameters == null) {
      throw ArgumentError('Invalid backend command.');
    }
    final response = await api.callJson(route, parameters: parameters);
    parent.send(<String, Object?>{
      'id': id,
      'ok': true,
      'status': response.status,
      'httpStatus': response.httpStatus,
      'body': response.body,
      'cookies': response.cookies,
      'headers': response.headers,
      'session': api.session.toJson(),
      'clientVariant': api.config.variant.name,
    });
  } on Object catch (error, stackTrace) {
    parent.send(_errorEnvelope(id, api, error, stackTrace));
  }
}

Map<String, Object?> _successEnvelope(
  int id,
  KugouApi api,
  KugouJsonObject body,
) => <String, Object?>{
  'id': id,
  'ok': true,
  'status': 200,
  'httpStatus': 200,
  'body': body,
  'cookies': const <String>[],
  'headers': const <String, String>{},
  'session': api.session.toJson(),
  'clientVariant': api.config.variant.name,
};

Map<String, Object?> _errorEnvelope(
  int id,
  KugouApi api,
  Object error,
  StackTrace stackTrace,
) {
  if (error is KugouApiException) {
    return <String, Object?>{
      'id': id,
      'ok': false,
      'errorKind': 'api',
      'message': error.toString(),
      'status': error.response.status,
      'httpStatus': error.response.httpStatus,
      'body': _safeSendable(error.response.body),
      'cookies': error.response.cookies,
      'headers': error.response.headers,
      'session': api.session.toJson(),
      'clientVariant': api.config.variant.name,
      'stack': stackTrace.toString(),
    };
  }
  return <String, Object?>{
    'id': id,
    'ok': false,
    'errorKind': error is KugouTransportException ? 'transport' : 'other',
    'message': error.toString(),
    'session': api.session.toJson(),
    'clientVariant': api.config.variant.name,
    'stack': stackTrace.toString(),
  };
}

Object _remoteError(Map<String, Object?> envelope) {
  final message = envelope['message']?.toString() ?? 'Unknown backend error';
  if (envelope['errorKind'] == 'api') {
    return KugouApiException(
      KugouResponse<Object?>(
        status: _intValue(envelope['status'], fallback: 502),
        httpStatus: _intValue(envelope['httpStatus'], fallback: 502),
        body: envelope['body'],
        cookies: _stringList(envelope['cookies']),
        headers: _stringMap(envelope['headers']),
      ),
      message,
    );
  }
  if (envelope['errorKind'] == 'transport') {
    return KugouTransportException(message);
  }
  return StateError(message);
}

Object? _encodeTransferables(Object? value) {
  if (value is Uint8List) {
    return TransferableTypedData.fromList(<Uint8List>[value]);
  }
  if (value is Map<Object?, Object?>) {
    return <Object?, Object?>{
      for (final entry in value.entries)
        entry.key: _encodeTransferables(entry.value),
    };
  }
  if (value is Iterable<Object?>) {
    return value.map(_encodeTransferables).toList(growable: false);
  }
  return value;
}

Object? _decodeTransferables(Object? value) {
  if (value is TransferableTypedData) return value.materialize().asUint8List();
  if (value is Map<Object?, Object?>) {
    return <Object?, Object?>{
      for (final entry in value.entries)
        entry.key: _decodeTransferables(entry.value),
    };
  }
  if (value is Iterable<Object?>) {
    return value.map(_decodeTransferables).toList(growable: false);
  }
  return value;
}

Object? _safeSendable(Object? value) {
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }
  if (value is Uint8List) return value;
  if (value is Map<Object?, Object?>) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): _safeSendable(entry.value),
    };
  }
  if (value is Iterable<Object?>) {
    return value.map(_safeSendable).toList(growable: false);
  }
  return value.toString();
}

Map<String, Object?>? _stringObjectMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is! Map<Object?, Object?>) return null;
  return <String, Object?>{
    for (final entry in value.entries)
      if (entry.key is String) entry.key! as String: entry.value,
  };
}

Map<String, String> _stringMap(Object? value) {
  final source = _stringObjectMap(value);
  if (source == null) return const <String, String>{};
  return <String, String>{
    for (final entry in source.entries) entry.key: entry.value.toString(),
  };
}

List<String> _stringList(Object? value) {
  if (value is! Iterable<Object?>) return const <String>[];
  return value.map((item) => item.toString()).toList(growable: false);
}

int _intValue(Object? value, {required int fallback}) => switch (value) {
  final int integer => integer,
  final num number => number.toInt(),
  _ => fallback,
};

KugouClientVariant? _clientVariantFromWire(Object? value) {
  if (value is! String) return null;
  for (final variant in KugouClientVariant.values) {
    if (variant.name == value) return variant;
  }
  return null;
}

bool _isSuccessfulDeviceRegistration(KugouJsonObject body) {
  final status = body['status'];
  if (status != 1 && status != '1') return false;
  final data = _stringObjectMap(body['data']);
  final dfid = data?['dfid']?.toString() ?? '';
  return dfid.isNotEmpty && dfid != '-' && dfid != '0';
}
