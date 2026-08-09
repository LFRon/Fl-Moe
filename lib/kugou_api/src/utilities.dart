import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

const _lettersAndNumbers = '1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _numbers = '1234567890';

String randomString([int length = 16, Random? random]) =>
    _randomFrom(_lettersAndNumbers, length, random);

String randomNumber([int length = 16, Random? random]) =>
    _randomFrom(_numbers, length, random);

String _randomFrom(String alphabet, int length, Random? suppliedRandom) {
  if (length < 0) throw RangeError.value(length, 'length');
  final random = suppliedRandom ?? Random.secure();
  // The reference uses ceil(random * (length - 1)), which practically never
  // selects index zero. Preserve that quirk because these values are sent to
  // KuGou as device identifiers.
  return List<String>.generate(
    length,
    (_) => alphabet[random.nextInt(alphabet.length - 1) + 1],
    growable: false,
  ).join();
}

String md5Hex(Object data) {
  final input = data is List<int>
      ? data
      : utf8.encode(data is String ? data : jsonEncode(data));
  return md5.convert(input).toString();
}

String sha1Hex(Object data) {
  final input = data is List<int>
      ? data
      : utf8.encode(data is String ? data : jsonEncode(data));
  return sha1.convert(input).toString();
}

String calculateMid(String value) =>
    BigInt.parse(md5Hex(value), radix: 16).toString();

String generateGuid([Random? suppliedRandom]) {
  final random = suppliedRandom ?? Random.secure();
  String segment() => random.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
  return '${segment()}${segment()}-${segment()}-${segment()}-'
      '${segment()}-${segment()}${segment()}${segment()}';
}

String generateWebGlHash([Random? suppliedRandom]) {
  final random = suppliedRandom ?? Random.secure();
  final high = random.nextInt(0x100000000);
  final low = random.nextInt(0x100000000);
  return ((BigInt.from(high) << 32) | BigInt.from(low)).toString();
}

bool isUuidV4(String value) => RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
).hasMatch(value);

String cleanSetCookie(String value) => value.split(';').first.trim();

Map<String, String> cookieStringToMap(String? value) {
  if (value == null || value.trim().isEmpty) return <String, String>{};
  return <String, String>{
    for (final part in value.split(';'))
      if (part.trim().contains('='))
        part.trim().substring(0, part.trim().indexOf('=')): part
            .trim()
            .substring(part.trim().indexOf('=') + 1),
  };
}

String decodeKrcLyrics(Object value) {
  Uint8List bytes;
  if (value is String) {
    try {
      bytes = base64Decode(value);
    } on FormatException {
      return '';
    }
  } else if (value is Uint8List) {
    bytes = Uint8List.fromList(value);
  } else if (value is List<int>) {
    bytes = Uint8List.fromList(value);
  } else {
    return '';
  }
  if (bytes.length < 4) return '';

  const key = <int>[
    64,
    71,
    97,
    119,
    94,
    50,
    116,
    71,
    81,
    54,
    49,
    45,
    206,
    210,
    110,
    105,
  ];
  final encrypted = Uint8List.fromList(bytes.sublist(4));
  for (var index = 0; index < encrypted.length; index++) {
    encrypted[index] ^= key[index % key.length];
  }
  try {
    return utf8.decode(const ZLibDecoder().decodeBytes(encrypted));
  } on Object {
    return '';
  }
}
