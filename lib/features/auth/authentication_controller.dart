import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../../core/backend/music_backend.dart';
import '../../core/storage/key_value_store.dart';
import '../../kugou_api.dart';
import '../music/music_models.dart';
import 'kugou_user_profile.dart';

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
  AuthenticationController(
    this._backend, {
    KugouUserProfileRepository? profileRepository,
  }) : _profileRepository = profileRepository,
       _profile = profileRepository?.load(
         variant: _backend.clientVariant,
         userId: _backend.sessionState.userId,
       );

  final MusicBackend _backend;
  final KugouUserProfileRepository? _profileRepository;
  KugouUserProfile? _profile;
  Future<bool>? _profileRequest;
  ({KugouClientVariant variant, String userId})? _profileRequestIdentity;

  bool get isLoggedIn => _backend.sessionState.isLoggedIn;
  String get userId => _backend.sessionState.userId;
  String get nickname => _profile?.nickname ?? '';
  String get avatarUrl => _profile?.avatarUrl ?? '';

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
      final loginProfile = KugouUserProfile.fromApiData(
        data,
        fallbackUserId: userId,
      );
      if (loginProfile != null) {
        await _setProfile(loginProfile, variant: _backend.clientVariant);
      }
      update();
      unawaited(refreshUserProfile());
    }
    return QrLoginResult(
      state: state,
      nickname: readString(data, const <String>['nickname', 'username']),
    );
  }

  Future<void> signOut() async {
    final previousVariant = _backend.clientVariant;
    final previousUserId = userId;
    await _backend.clearAuthentication();
    _profile = null;
    update();
    try {
      await _profileRepository?.delete(
        variant: previousVariant,
        userId: previousUserId,
      );
    } on Object {
      // The authentication state is already cleared; stale presentation data
      // must never make logout fail.
    }
  }

  /// Refreshes public profile data through the embedded backend isolate.
  /// Failures deliberately retain the cached profile/local mascot.
  Future<bool> refreshUserProfile() {
    if (!isLoggedIn) return Future<bool>.value(false);
    final identity = (variant: _backend.clientVariant, userId: userId);
    final inFlight = _profileRequest;
    if (inFlight != null && _profileRequestIdentity == identity) {
      return inFlight;
    }

    late final Future<bool> operation;
    operation = _fetchUserProfile(identity).whenComplete(() {
      if (identical(_profileRequest, operation)) {
        _profileRequest = null;
        _profileRequestIdentity = null;
      }
    });
    _profileRequestIdentity = identity;
    _profileRequest = operation;
    return operation;
  }

  /// Rebuilds account-dependent UI after the backend activates another
  /// platform-scoped session.
  void refreshSessionState() {
    _profile = _profileRepository?.load(
      variant: _backend.clientVariant,
      userId: userId,
    );
    update();
    if (isLoggedIn) unawaited(refreshUserProfile());
  }

  Future<bool> _fetchUserProfile(
    ({KugouClientVariant variant, String userId}) identity,
  ) async {
    try {
      if (!_backend.sessionState.hasRegisteredDevice &&
          !await _backend.ensureDeviceRegistered()) {
        return false;
      }
      final response = await _backend.userDetail();
      final data = asJsonObject(response.body['data']);
      final profile = data == null
          ? null
          : KugouUserProfile.fromApiData(data, fallbackUserId: identity.userId);
      if (profile == null ||
          _backend.clientVariant != identity.variant ||
          userId != identity.userId) {
        return false;
      }
      await _setProfile(profile, variant: identity.variant);
      return avatarUrl.isNotEmpty;
    } on Object {
      return false;
    }
  }

  Future<void> _setProfile(
    KugouUserProfile incoming, {
    required KugouClientVariant variant,
  }) async {
    final current = _profile;
    final next = current == null ? incoming : current.merge(incoming);
    if (next != current) {
      _profile = next;
      update();
    }
    try {
      await _profileRepository?.save(next, variant: variant);
    } on Object {
      // Rendering the freshly fetched profile is still useful when storage is
      // temporarily unavailable.
    }
  }
}
