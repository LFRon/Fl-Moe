import 'dart:convert';

import '../../core/storage/key_value_store.dart';
import '../../kugou_api.dart';
import '../music/music_models.dart';

/// Public account data that is safe for the Flutter UI to retain and render.
final class KugouUserProfile {
  const KugouUserProfile({
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
  });

  static KugouUserProfile? fromApiData(
    JsonObject json, {
    required String fallbackUserId,
  }) {
    final candidates = <JsonObject>[json];
    for (final key in const <String>[
      'user_info',
      'userinfo',
      'info',
      'profile',
    ]) {
      final nested = asJsonObject(json[key]);
      if (nested != null) candidates.add(nested);
    }

    final apiUserId = _readFrom(candidates, const <String>[
      'userid',
      'user_id',
      'uid',
    ]);
    final userId = apiUserId.isEmpty ? fallbackUserId : apiUserId;
    if (userId.isEmpty || userId == '0') return null;

    final rawAvatar = _readFrom(candidates, const <String>[
      'pic',
      'avatar',
      'avatar_url',
      'headimg',
      'headimgurl',
      'userpic',
    ]);
    final profile = KugouUserProfile(
      userId: userId,
      nickname: _readFrom(candidates, const <String>[
        'nickname',
        'username',
        'user_name',
      ]),
      avatarUrl: _normalizeAvatarUrl(rawAvatar),
    );
    return profile.hasDisplayData ? profile : null;
  }

  static KugouUserProfile? fromJson(JsonObject json) {
    final userId = readString(json, const <String>['userId']);
    if (userId.isEmpty || userId == '0') return null;
    final profile = KugouUserProfile(
      userId: userId,
      nickname: readString(json, const <String>['nickname']),
      avatarUrl: _normalizeAvatarUrl(
        readString(json, const <String>['avatarUrl']),
      ),
    );
    return profile.hasDisplayData ? profile : null;
  }

  final String userId;
  final String nickname;
  final String avatarUrl;

  bool get hasDisplayData => nickname.isNotEmpty || avatarUrl.isNotEmpty;

  KugouUserProfile merge(KugouUserProfile newer) {
    if (newer.userId != userId) return newer;
    return KugouUserProfile(
      userId: userId,
      nickname: newer.nickname.isEmpty ? nickname : newer.nickname,
      avatarUrl: newer.avatarUrl.isEmpty ? avatarUrl : newer.avatarUrl,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'userId': userId,
    'nickname': nickname,
    'avatarUrl': avatarUrl,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KugouUserProfile &&
          other.userId == userId &&
          other.nickname == nickname &&
          other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(userId, nickname, avatarUrl);
}

/// Keeps the last public profile per KuGou client and account so the local
/// fallback is replaced immediately on later launches, before the refresh.
final class KugouUserProfileRepository {
  const KugouUserProfileRepository(this._store);

  final KeyValueStore _store;

  KugouUserProfile? load({
    required KugouClientVariant variant,
    required String userId,
  }) {
    if (userId.isEmpty || userId == '0') return null;
    final raw = _store.read(_key(variant, userId));
    Object? decoded = raw;
    if (raw is String) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        return null;
      }
    }
    final json = asJsonObject(decoded);
    final profile = json == null ? null : KugouUserProfile.fromJson(json);
    return profile?.userId == userId ? profile : null;
  }

  Future<void> save(
    KugouUserProfile profile, {
    required KugouClientVariant variant,
  }) =>
      _store.write(_key(variant, profile.userId), jsonEncode(profile.toJson()));

  Future<void> delete({
    required KugouClientVariant variant,
    required String userId,
  }) {
    if (userId.isEmpty || userId == '0') return Future<void>.value();
    return _store.delete(_key(variant, userId));
  }

  String _key(KugouClientVariant variant, String userId) =>
      'user_profile.${variant.name}.$userId';
}

String _readFrom(List<JsonObject> candidates, List<String> keys) {
  for (final candidate in candidates) {
    final value = readString(candidate, keys);
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _normalizeAvatarUrl(String value) {
  final normalized = normalizeImageUrl(value, size: 240);
  final uri = Uri.tryParse(normalized);
  if (uri == null || !uri.hasAuthority) return '';
  return switch (uri.scheme.toLowerCase()) {
    'http' || 'https' => normalized,
    _ => '',
  };
}
