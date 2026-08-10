import 'dart:math';

import 'config.dart';
import 'utilities.dart';

/// Mutable session state. Persist [toJson] in the application's own storage.
final class KugouSession {
  KugouSession({
    Map<String, String>? cookies,
    KugouClientVariant variant = KugouClientVariant.standard,
    Random? random,
  }) : _variant = variant,
       _cookies = Map<String, String>.from(cookies ?? const {}),
       _authenticationByVariant = <KugouClientVariant, Map<String, String>>{} {
    _ensureDeviceIdentity(variant, random);
    _captureActiveAuthentication();
  }

  factory KugouSession.fromJson(
    Map<String, Object?> json, {
    KugouClientVariant? variant,
    bool trustLegacyAuthentication = true,
  }) {
    final rawCookies = json['cookies'];
    final cookies = rawCookies is Map<Object?, Object?>
        ? rawCookies.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          )
        : <String, String>{};
    final activeVariant =
        variant ??
        _variantFromName(json[_activeVariantKey]) ??
        KugouClientVariant.standard;
    final rawAuthentication = json[_authenticationKey];
    if (rawAuthentication is Map<Object?, Object?>) {
      return KugouSession._restored(
        cookies: cookies,
        authenticationByVariant: _decodeAuthentication(rawAuthentication),
        variant: activeVariant,
      );
    }
    if (!trustLegacyAuthentication) {
      for (final name in _authenticationCookieNames) {
        cookies.remove(name);
      }
    }
    return KugouSession(cookies: cookies, variant: activeVariant);
  }

  KugouSession._restored({
    required Map<String, String> cookies,
    required Map<KugouClientVariant, Map<String, String>>
    authenticationByVariant,
    required KugouClientVariant variant,
  }) : _variant = variant,
       _cookies = Map<String, String>.from(cookies),
       _authenticationByVariant = <KugouClientVariant, Map<String, String>>{
         for (final entry in authenticationByVariant.entries)
           entry.key: Map<String, String>.from(entry.value),
       } {
    _ensureDeviceIdentity(variant, null);
    _activateAuthentication();
  }

  static const String _activeVariantKey = 'active_variant';
  static const String _authenticationKey = 'authentication_by_variant';
  static const List<String> _authenticationCookieNames = <String>[
    'token',
    'userid',
    'vip_type',
    'vip_token',
    't1',
  ];

  final KugouClientVariant _variant;
  final Map<String, String> _cookies;
  final Map<KugouClientVariant, Map<String, String>> _authenticationByVariant;

  KugouClientVariant get variant => _variant;
  Map<String, String> get cookies => Map.unmodifiable(_cookies);
  String? operator [](String key) => _cookies[key];

  String get mid => _cookies['KUGOU_API_MID']!;
  String get guid => _cookies['KUGOU_API_GUID']!;
  String get deviceId => _cookies['KUGOU_API_DEV']!;
  String get macAddress => _cookies['KUGOU_API_MAC']!;
  String get webGlHash => _cookies['KUGOU_API_WEBGL']!;
  String get dfid => _cookies['dfid'] ?? '';
  String get token => _cookies['token'] ?? '';
  String get userId => _cookies['userid'] ?? '0';
  bool get hasRegisteredDevice => dfid.isNotEmpty && dfid != '-' && dfid != '0';
  bool get isLoggedIn => token.isNotEmpty && userId != '0';

  void setCookie(String key, Object? value) {
    if (value == null) {
      _cookies.remove(key);
    } else {
      _cookies[key] = value.toString();
    }
    if (_authenticationCookieNames.contains(key)) {
      _captureActiveAuthentication();
    }
  }

  void updateCookies(Iterable<String> setCookies) {
    for (final raw in setCookies) {
      final cookie = cleanSetCookie(raw);
      final separator = cookie.indexOf('=');
      if (separator <= 0) continue;
      setCookie(
        cookie.substring(0, separator),
        cookie.substring(separator + 1),
      );
    }
  }

  void clearAuthentication() {
    for (final key in _authenticationCookieNames) {
      _cookies.remove(key);
    }
    _authenticationByVariant.clear();
  }

  Map<String, Object?> toJson() {
    _captureActiveAuthentication();
    return <String, Object?>{
      _activeVariantKey: _variant.name,
      'cookies': Map<String, String>.from(_cookies),
      _authenticationKey: <String, Object?>{
        for (final entry in _authenticationByVariant.entries)
          entry.key.name: Map<String, String>.from(entry.value),
      },
    };
  }

  void _captureActiveAuthentication() {
    final token = _cookies['token'] ?? '';
    final userId = _cookies['userid'] ?? '0';
    if (token.isEmpty || userId.isEmpty || userId == '0') {
      _authenticationByVariant.remove(_variant);
      return;
    }
    _authenticationByVariant[_variant] = <String, String>{
      for (final name in _authenticationCookieNames)
        if (_cookies.containsKey(name)) name: _cookies[name]!,
    };
  }

  void _activateAuthentication() {
    for (final name in _authenticationCookieNames) {
      _cookies.remove(name);
    }
    final authentication = _authenticationByVariant[_variant];
    if (authentication != null) {
      _cookies.addAll(authentication);
    }
  }

  void _ensureDeviceIdentity(KugouClientVariant variant, Random? random) {
    final suppliedGuid = _cookies['KUGOU_API_GUID'];
    final guid = suppliedGuid == null
        ? md5Hex(generateGuid(random))
        : isUuidV4(suppliedGuid)
        ? md5Hex(suppliedGuid)
        : suppliedGuid;
    _cookies
      ..['KUGOU_API_PLATFORM'] = variant == KugouClientVariant.lite
          ? 'lite'
          : 'android'
      ..putIfAbsent('KUGOU_API_GUID', () => guid)
      ..putIfAbsent('KUGOU_API_MID', () => calculateMid(guid))
      ..putIfAbsent(
        'KUGOU_API_DEV',
        () => randomString(10, random).toUpperCase(),
      )
      ..putIfAbsent('KUGOU_API_MAC', () => '02:00:00:00:00:00')
      ..putIfAbsent('KUGOU_API_WEBGL', () => generateWebGlHash(random));
  }

  static Map<KugouClientVariant, Map<String, String>> _decodeAuthentication(
    Map<Object?, Object?> raw,
  ) {
    final result = <KugouClientVariant, Map<String, String>>{};
    for (final variant in KugouClientVariant.values) {
      final value = raw[variant.name];
      if (value is! Map<Object?, Object?>) continue;
      final authentication = <String, String>{
        for (final entry in value.entries)
          if (_authenticationCookieNames.contains(entry.key.toString()))
            entry.key.toString(): entry.value.toString(),
      };
      final token = authentication['token'] ?? '';
      final userId = authentication['userid'] ?? '0';
      if (token.isNotEmpty && userId.isNotEmpty && userId != '0') {
        result[variant] = authentication;
      }
    }
    return result;
  }

  static KugouClientVariant? _variantFromName(Object? value) {
    if (value is! String) return null;
    for (final variant in KugouClientVariant.values) {
      if (variant.name == value) return variant;
    }
    return null;
  }
}
