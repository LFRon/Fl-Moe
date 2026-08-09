import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'config.dart';
import 'js_compat.dart';
import 'utilities.dart';

enum KugouSignatureType { android, web, register }

final class KugouSignatures {
  const KugouSignatures(this.config);

  final KugouApiConfig config;

  String web(Map<String, Object?> parameters) {
    const salt = 'NVPh5oo715z5DIWAeQlhMDsWXXQV4hwt';
    final parts =
        parameters.entries
            .map((entry) => '${entry.key}=${jsValueString(entry.value)}')
            .toList()
          ..sort();
    return md5Hex('$salt${parts.join()}$salt');
  }

  String android(Map<String, Object?> parameters, [Object? data]) {
    final salt = config.isLite
        ? 'LnT6xpN3khm36zse0QzvmgTZ3waWdRSA'
        : 'OIlwieks28dk2k092lksi2UIkp';
    final keys = parameters.keys.toList()..sort();
    final parameterString = keys.map((key) {
      final value = parameters[key];
      final encoded =
          value is Map<Object?, Object?> || value is Iterable<Object?>
          ? jsJsonEncode(value)
          : jsValueString(value);
      return '$key=$encoded';
    }).join();

    if (data is Uint8List || data is List<int>) {
      final bytes = data is Uint8List
          ? data
          : Uint8List.fromList(data! as List<int>);
      final input = BytesBuilder(copy: false)
        ..add(utf8.encode('$salt$parameterString'))
        ..add(bytes)
        ..add(utf8.encode(salt));
      return md5.convert(input.takeBytes()).toString();
    }
    return md5Hex('$salt$parameterString${data ?? ''}$salt');
  }

  String register(Map<String, Object?> parameters) {
    final values = parameters.values.map(jsValueString).toList()..sort();
    return md5Hex('1014${values.join()}1014');
  }

  String generic(Map<String, Object?> parameters, [Object? data]) {
    const salt = 'R6snCXJgbCaj9WFRJKefTMIFp0ey6Gza';
    final keys = parameters.keys.toList()..sort();
    final values = keys.map((key) => '$key${jsValueString(parameters[key])}');
    return md5Hex('${values.join()}${data ?? ''}$salt');
  }

  String key(Object? hash, Object? mid, [Object? userId, Object? appId]) {
    final salt = config.isLite
        ? '185672dd44712f60bb1736df5a377e82'
        : '57ae12eb6890223e355ccfcb74edf70d';
    final effectiveUserId = userId == null || userId == 0 ? 0 : userId;
    final effectiveAppId = appId == null || appId == 0 ? config.appId : appId;
    return md5Hex(
      '${jsValueString(hash)}$salt$effectiveAppId${jsValueString(mid)}$effectiveUserId',
    );
  }

  String cloudKey(String hash, Object processId) => md5Hex(
    'musicclound$hash$processId'
    'ebd1ac3134c880bda6a2194537843caa0162e2e7',
  );

  String parametersKey(Object data, [Object? appId, Object? clientVersion]) {
    final salt = config.isLite
        ? 'LnT6xpN3khm36zse0QzvmgTZ3waWdRSA'
        : 'OIlwieks28dk2k092lksi2UIkp';
    final effectiveAppId = appId == null || appId == 0 ? config.appId : appId;
    final effectiveVersion = clientVersion == null || clientVersion == 0
        ? config.clientVersion
        : clientVersion;
    return md5Hex('$effectiveAppId$salt$effectiveVersion$data');
  }
}
