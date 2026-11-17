import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';

import 'config.dart';
import 'js_compat.dart';
import 'utilities.dart';

const standardKugouPublicKey = '''-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDIAG7QOELSYoIJvTFJhMpe1s/gbjDJX51HBNnEl5HXqTW6lQ7LC8jr9fWZTwusknp+sVGzwd40MwP6U5yDE27M/X1+UR4tvOGOqp94TJtQ1EPnWGWXngpeIW5GxoQGao1rmYWAu6oi1z9XkChrsUdC6DJE5E221wf/4WLFxwAtRQIDAQAB
-----END PUBLIC KEY-----''';

const liteKugouPublicKey = '''-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDECi0Np2UR87scwrvTr72L6oO01rBbbBPriSDFPxr3Z5syug0O24QyQO8bg27+0+4kBzTBTBOZ/WWU0WryL1JSXRTXLgFVxtzIY41Pe7lPOgsfTCn5kZcvKhYKJesKnnJDNr5/abvTGf+rHG3YRwsCHcQ08/q6ifSioBszvb3QiwIDAQAB
-----END PUBLIC KEY-----''';

final class KugouAesResult {
  const KugouAesResult({required this.ciphertext, required this.key});

  /// Hex for the login AES helper, Base64 for the playlist AES helper.
  final String ciphertext;

  /// Temporary plaintext key. Empty when an explicit key and IV were supplied.
  final String key;
}

final class KugouCrypto {
  KugouCrypto(this.config);

  final KugouApiConfig config;
  RSAPublicKey? _standardKey;
  RSAPublicKey? _liteKey;

  RSAPublicKey get publicKey {
    if (config.isLite) {
      return _liteKey ??= parsePublicKey(liteKugouPublicKey);
    }
    return _standardKey ??= parsePublicKey(standardKugouPublicKey);
  }

  KugouAesResult aesEncrypt(
    Object data, {
    String? key,
    String? iv,
    String? temporaryKey,
  }) {
    late final String actualKey;
    late final String actualIv;
    var returnedKey = '';
    if (key != null && iv != null) {
      actualKey = key;
      actualIv = iv;
    } else {
      returnedKey = temporaryKey ?? key ?? randomString(16).toLowerCase();
      actualKey = md5Hex(returnedKey).substring(0, 32);
      actualIv = actualKey.substring(actualKey.length - 16);
    }
    final encrypted = _aesCbc(
      true,
      _normalize(data),
      Uint8List.fromList(utf8.encode(actualKey)),
      Uint8List.fromList(utf8.encode(actualIv)),
    );
    return KugouAesResult(ciphertext: hexEncode(encrypted), key: returnedKey);
  }

  Object aesDecrypt(String ciphertext, String key, {String? iv}) {
    var actualKey = key;
    var actualIv = iv;
    if (actualIv == null) {
      actualKey = md5Hex(key).substring(0, 32);
      actualIv = actualKey.substring(actualKey.length - 16);
    }
    final decrypted = _aesCbc(
      false,
      hexDecode(ciphertext),
      Uint8List.fromList(utf8.encode(actualKey)),
      Uint8List.fromList(utf8.encode(actualIv)),
    );
    return _decodeJsonOrText(decrypted);
  }

  /// Reproduces KuGou's unusual raw RSA operation with trailing zero padding.
  String rsaRawEncrypt(Object data, {String? publicKeyPem}) {
    final bytes = _normalize(data);
    final key = publicKeyPem == null ? publicKey : parsePublicKey(publicKeyPem);
    final byteLength = (key.modulus!.bitLength + 7) ~/ 8;
    if (bytes.length > byteLength) {
      throw ArgumentError('Data length exceeds RSA key size');
    }
    final padded = Uint8List(byteLength)..setRange(0, bytes.length, bytes);
    final message = _bytesToBigInt(padded);
    final encrypted = message.modPow(key.exponent!, key.modulus!);
    return hexEncode(_bigIntToBytes(encrypted, byteLength));
  }

  String rsaPkcs1Encrypt(Object data, {String? publicKeyPem}) {
    final bytes = _normalize(data);
    final key = publicKeyPem == null ? publicKey : parsePublicKey(publicKeyPem);
    final cipher = PKCS1Encoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(key));
    final output = Uint8List(cipher.outputBlockSize);
    final length = cipher.processBlock(bytes, 0, bytes.length, output, 0);
    return hexEncode(output.sublist(0, length));
  }

  KugouAesResult playlistAesEncrypt(Object data, {String? temporaryKey}) {
    final key = (temporaryKey ?? randomString(6)).toLowerCase();
    final digest = md5Hex(key);
    final encrypted = _aesCbc(
      true,
      _normalize(data),
      Uint8List.fromList(utf8.encode(digest.substring(0, 16))),
      Uint8List.fromList(utf8.encode(digest.substring(16, 32))),
    );
    return KugouAesResult(ciphertext: base64Encode(encrypted), key: key);
  }

  Object playlistAesDecrypt(String ciphertext, String key) {
    final digest = md5Hex(key);
    final decrypted = _aesCbc(
      false,
      base64Decode(ciphertext),
      Uint8List.fromList(utf8.encode(digest.substring(0, 16))),
      Uint8List.fromList(utf8.encode(digest.substring(16, 32))),
    );
    return _decodeJsonOrText(decrypted);
  }

  String aesCbcBase64Encrypt(
    Object data, {
    required String key,
    required String iv,
  }) => base64Encode(
    _aesCbc(
      true,
      _normalize(data),
      Uint8List.fromList(utf8.encode(key)),
      Uint8List.fromList(utf8.encode(iv)),
    ),
  );

  Uint8List aesCbcEncryptBytes(
    Uint8List data, {
    required Uint8List key,
    required Uint8List iv,
  }) => _aesCbc(true, data, key, iv);

  Uint8List aesCbcDecryptBytes(
    Uint8List data, {
    required Uint8List key,
    required Uint8List iv,
  }) => _aesCbc(false, data, key, iv);

  String rsaOaepSha256Encrypt(Object data, {required String publicKeyPem}) {
    final bytes = _normalize(data);
    final key = parsePublicKey(publicKeyPem);
    final cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(key));
    final output = Uint8List(cipher.outputBlockSize);
    final length = cipher.processBlock(bytes, 0, bytes.length, output, 0);
    return base64Encode(output.sublist(0, length));
  }

  static RSAPublicKey parsePublicKey(String pem) {
    final body = pem
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    final outer = ASN1Parser(base64Decode(body)).nextObject() as ASN1Sequence;
    final bitString = outer.elements[1] as ASN1BitString;
    final inner =
        ASN1Parser(Uint8List.fromList(bitString.contentBytes())).nextObject()
            as ASN1Sequence;
    final modulus = (inner.elements[0] as ASN1Integer).valueAsBigInteger;
    final exponent = (inner.elements[1] as ASN1Integer).valueAsBigInteger;
    return RSAPublicKey(modulus, exponent);
  }

  Uint8List _normalize(Object data) {
    if (data is Uint8List) return data;
    if (data is String) return Uint8List.fromList(utf8.encode(data));
    return Uint8List.fromList(utf8.encode(jsJsonEncode(data)));
  }

  Object _decodeJsonOrText(Uint8List bytes) {
    final text = utf8.decode(bytes);
    try {
      return jsonDecode(text) as Object;
    } on FormatException {
      return text;
    }
  }

  Uint8List _aesCbc(
    bool encrypt,
    Uint8List input,
    Uint8List key,
    Uint8List iv,
  ) {
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        encrypt,
        PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
          ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
          null,
        ),
      );
    return cipher.process(input);
  }
}

String hexEncode(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

Uint8List hexDecode(String value) {
  if (value.length.isOdd) throw const FormatException('Odd-length hex value');
  return Uint8List.fromList([
    for (var index = 0; index < value.length; index += 2)
      int.parse(value.substring(index, index + 2), radix: 16),
  ]);
}

BigInt _bytesToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

Uint8List _bigIntToBytes(BigInt value, int length) {
  final result = Uint8List(length);
  var remaining = value;
  for (var index = length - 1; index >= 0; index--) {
    result[index] = (remaining & BigInt.from(0xff)).toInt();
    remaining >>= 8;
  }
  return result;
}
