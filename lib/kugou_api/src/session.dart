import 'dart:math';

import 'config.dart';
import 'utilities.dart';

/// Mutable session state. Persist [toJson] in the application's own storage.
final class KugouSession {
  KugouSession({
    Map<String, String>? cookies,
    KugouClientVariant variant = KugouClientVariant.standard,
    Random? random,
  }) : _cookies = Map<String, String>.from(cookies ?? const {}) {
    _ensureDeviceIdentity(variant, random);
  }

  factory KugouSession.fromJson(
    Map<String, Object?> json, {
    KugouClientVariant variant = KugouClientVariant.standard,
  }) {
    final rawCookies = json['cookies'];
    return KugouSession(
      variant: variant,
      cookies: rawCookies is Map<Object?, Object?>
          ? rawCookies.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : null,
    );
  }

  final Map<String, String> _cookies;

  Map<String, String> get cookies => Map.unmodifiable(_cookies);
  String? operator [](String key) => _cookies[key];

  String get mid => _cookies['KUGOU_API_MID']!;
  String get guid => _cookies['KUGOU_API_GUID']!;
  String get deviceId => _cookies['KUGOU_API_DEV']!;
  String get macAddress => _cookies['KUGOU_API_MAC']!;
  String get webGlHash => _cookies['KUGOU_API_WEBGL']!;
  String get token => _cookies['token'] ?? '';
  String get userId => _cookies['userid'] ?? '0';
  bool get isLoggedIn => token.isNotEmpty && userId != '0';

  void setCookie(String key, Object? value) {
    if (value == null) {
      _cookies.remove(key);
    } else {
      _cookies[key] = value.toString();
    }
  }

  void updateCookies(Iterable<String> setCookies) {
    for (final raw in setCookies) {
      final cookie = cleanSetCookie(raw);
      final separator = cookie.indexOf('=');
      if (separator <= 0) continue;
      _cookies[cookie.substring(0, separator)] = cookie.substring(
        separator + 1,
      );
    }
  }

  void clearAuthentication() {
    for (final key in const [
      'token',
      'userid',
      'vip_type',
      'vip_token',
      't1',
    ]) {
      _cookies.remove(key);
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{'cookies': _cookies};

  void _ensureDeviceIdentity(KugouClientVariant variant, Random? random) {
    final suppliedGuid = _cookies['KUGOU_API_GUID'];
    final guid = suppliedGuid == null
        ? md5Hex(generateGuid(random))
        : isUuidV4(suppliedGuid)
        ? md5Hex(suppliedGuid)
        : suppliedGuid;
    _cookies
      ..putIfAbsent(
        'KUGOU_API_PLATFORM',
        () => variant == KugouClientVariant.lite ? 'lite' : 'android',
      )
      ..putIfAbsent('KUGOU_API_GUID', () => guid)
      ..putIfAbsent('KUGOU_API_MID', () => calculateMid(guid))
      ..putIfAbsent(
        'KUGOU_API_DEV',
        () => randomString(10, random).toUpperCase(),
      )
      ..putIfAbsent('KUGOU_API_MAC', () => '02:00:00:00:00:00')
      ..putIfAbsent('KUGOU_API_WEBGL', () => generateWebGlHash(random));
  }
}
