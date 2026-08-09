import 'package:fl_moe/kugou_api/src/config.dart';
import 'package:fl_moe/kugou_api/src/crypto.dart';
import 'package:fl_moe/kugou_api/src/utilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AES-CBC matches OpenSSL vectors and round-trips JSON', () {
    final crypto = KugouCrypto(const KugouApiConfig());
    const input = <String, Object?>{'mobile': '13800138000', 'code': '1234'};
    final explicit = crypto.aesEncrypt(
      input,
      key: '0123456789abcdef0123456789abcdef',
      iv: '0123456789abcdef',
    );
    expect(
      explicit.ciphertext,
      '58e3217c0566efcfd4545a51963ec91251d6c608bebd0ae174493c5a6ddd0b7'
      '6e56a2dea66badb6d8cb6e7d5531982a3',
    );
    expect(
      crypto.aesDecrypt(
        explicit.ciphertext,
        '0123456789abcdef0123456789abcdef',
        iv: '0123456789abcdef',
      ),
      input,
    );

    final temporary = crypto.aesEncrypt(
      'hello酷狗',
      temporaryKey: 'abcdefabcdefabcd',
    );
    expect(temporary.key, 'abcdefabcdefabcd');
    expect(temporary.ciphertext, '8aa7bc9d65f801ca394c881674cf5e3d');
    expect(crypto.aesDecrypt(temporary.ciphertext, temporary.key), 'hello酷狗');
  });

  test('raw RSA matches OpenSSL with KuGou trailing-zero padding', () {
    final standard = KugouCrypto(const KugouApiConfig());
    const input = <String, Object?>{
      'clienttime_ms': 1700000000000,
      'key': 'abcdef',
    };
    expect(
      standard.rsaRawEncrypt(input),
      '975ceb235b0a0c7b91b2a1eaedec02f97d4cb7e6dd46cc777acf0a037d5bd616'
      '0b78faf7592a04a38ca1e85be58b1f9c517e78b67dd3815dd0e979323bc78d1d'
      'b369fa40c17c9d863d6661efd896b9d672b5af72ba8b552401939a6f8843ef67'
      '8d221eb8d275602337be17a4b3be01ff00310dab2c2e6e35094a4bb785649972',
    );

    final lite = KugouCrypto(
      const KugouApiConfig(variant: KugouClientVariant.lite),
    );
    expect(
      lite.rsaRawEncrypt(input),
      '0f0f978b506262410935ac897d43865f93482e90a87bfe20f1bb8c7fe62291d2'
      'f0e65139955e797982a1e947d54e3651839e4a917145fa821050876bc18d15551'
      '1178c20a1009768989dbf4f82900a2b36a0e28f16fd91775acbeb50f55fd5e24'
      '9e748b127ca63a6089a6488317fd7dd21d58c381eec9b3ff0d244ca1467039e',
    );
  });

  test('playlist AES matches OpenSSL and round-trips', () {
    final crypto = KugouCrypto(const KugouApiConfig());
    const input = <String, Object?>{
      'list_ver': 0,
      'data': <Object?>[
        <String, Object?>{'name': 'x.mp3', 'size': 123},
      ],
    };
    final result = crypto.playlistAesEncrypt(input, temporaryKey: 'IIIIII');
    expect(result.key, 'iiiiii');
    expect(
      result.ciphertext,
      'qlMPaFBN5/ulxCplKOKPk9Luwvj/qKIARhHs09SUk7rYwPAhSzRkhOnAllaxh/Ko'
      'NmDkWv9/XHMZeDTtIPJgHQ==',
    );
    expect(crypto.playlistAesDecrypt(result.ciphertext, result.key), input);
  });

  test('MID and KRC decoding match reference algorithms', () {
    expect(
      calculateMid('550e8400-e29b-41d4-a716-446655440000'),
      '308741372901437977228425563242293240765',
    );
    expect(
      decodeKrcLyrics(
        'a3JjMTjb6rkSg74J3tO7G/5iXFmUdFH/I4ADhoKTSvIhOxfbI52S3mMyo2te4A==',
      ),
      '[id:kg]\n[00:01.00]你好，世界',
    );
  });
}
