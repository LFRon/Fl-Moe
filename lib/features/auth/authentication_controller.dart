import 'dart:convert';

import 'package:get/get.dart';

import '../../core/backend/music_backend.dart';
import '../../core/storage/key_value_store.dart';
import '../../kugou_api.dart';
import '../music/music_models.dart';

enum QrLoginState { waiting, scanned, authorized, expired }

final class QrLoginChallenge {
  const QrLoginChallenge({required this.key, required this.content});

  final String key;
  final Uri content;
}

final class QrLoginResult {
  const QrLoginResult({required this.state, this.nickname = ''});

  final QrLoginState state;
  final String nickname;
}

final class KugouSessionRepository {
  const KugouSessionRepository(this._store);

  static const String _stateKey = 'state';
  final KeyValueStore _store;

  KugouSession load({
    KugouClientVariant variant = KugouClientVariant.standard,
  }) {
    final raw = _store.read(_stateKey);
    Object? decoded = raw;
    if (raw is String) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        decoded = null;
      }
    }
    final object = asJsonObject(decoded);
    return object == null
        ? KugouSession(variant: variant)
        : KugouSession.fromJson(
            object,
            variant: variant,
            // Versions before platform-scoped sessions did not record which
            // appid issued a token. Reusing it can make the UI look logged in
            // while KuGou rejects every authenticated request with 20018.
            trustLegacyAuthentication: false,
          );
  }

  Future<void> save(KugouSession session) =>
      _store.write(_stateKey, jsonEncode(session.toJson()));

  Future<void> saveJson(Map<String, Object?> session) =>
      _store.write(_stateKey, jsonEncode(session));
}

final class AuthenticationController extends GetxController {
  AuthenticationController(this._backend);

  final MusicBackend _backend;

  bool get isLoggedIn => _backend.sessionState.isLoggedIn;
  String get userId => _backend.sessionState.userId;

  Future<QrLoginChallenge> createQrChallenge() async {
    final registered = await _backend.ensureDeviceRegistered();
    if (!registered) {
      throw StateError('酷狗设备注册失败，请检查网络后重试');
    }
    final response = await _backend.loginQrKey();
    final data = asJsonObject(response.body['data']);
    final key = data == null
        ? ''
        : readString(data, const <String>['qrcode', 'key']);
    if (key.isEmpty) {
      throw const KugouUnexpectedBodyException(
        route: '/login/qr/key',
        actualType: Null,
      );
    }
    return QrLoginChallenge(
      key: key,
      content: await _backend.loginQrContent(key),
    );
  }

  Future<QrLoginResult> checkQrChallenge(QrLoginChallenge challenge) async {
    final response = await _backend.checkLoginQr(challenge.key);
    final data = asJsonObject(response.body['data']);
    if (data == null) {
      throw KugouUnexpectedBodyException(
        route: '/login/qr/check',
        actualType: response.body['data'].runtimeType,
      );
    }
    final wireStatus = readInt(data, const <String>['status']);
    final state = switch (wireStatus) {
      0 => QrLoginState.expired,
      2 => QrLoginState.scanned,
      4 => QrLoginState.authorized,
      _ => QrLoginState.waiting,
    };
    if (state == QrLoginState.authorized) {
      await _backend.flushSession();
      update();
    }
    return QrLoginResult(
      state: state,
      nickname: readString(data, const <String>['nickname', 'username']),
    );
  }

  Future<void> signOut() async {
    await _backend.clearAuthentication();
    update();
  }

  /// Rebuilds account-dependent UI after the backend activates another
  /// platform-scoped session.
  void refreshSessionState() => update();
}
