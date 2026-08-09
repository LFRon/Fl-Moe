import 'package:fl_moe/kugou_api/src/config.dart';
import 'package:fl_moe/kugou_api/src/signatures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parameters = <String, Object?>{
    'z': '中文',
    'a': 1,
    'nested': <String, Object?>{
      'b': true,
      'a': <Object?>[1, 'x'],
    },
    'flag': false,
  };

  test('standard signatures match independently calculated vectors', () {
    final signatures = KugouSignatures(const KugouApiConfig());

    expect(signatures.web(parameters), 'e07a2b38c7d8d8cfcb1fcae99877f76d');
    expect(
      signatures.android(parameters, '{"body":1}'),
      '61eff4fea8d6d2ccb597c0f51b224cbe',
    );
    expect(signatures.register(parameters), '02d64f1957fb60d7d3b37195c03632d5');
    expect(
      signatures.generic(parameters, 'payload'),
      '756a4090dcb3af10870729f9b1b2bf1a',
    );
    expect(
      signatures.key('ABCDEF', '123456789', 42),
      '45856bf8e1da2fa9ba77105468fd0fb2',
    );
    expect(
      signatures.cloudKey('abcdef', '100'),
      '93d2ce36bba4db813f5b5f3497a34b28',
    );
    expect(
      signatures.parametersKey(1700000000),
      'a1f65b6a8fe7e191521406ce8661ae02',
    );
  });

  test('lite signatures use the lite salts and client identity', () {
    final signatures = KugouSignatures(
      const KugouApiConfig(variant: KugouClientVariant.lite),
    );

    expect(
      signatures.android(parameters, '{"body":1}'),
      '9ecebe4233a122146f399dad172c724f',
    );
    expect(
      signatures.key('ABCDEF', '123456789', 42),
      'b80afa112972aea0f99ef0f3f3fd6fef',
    );
    expect(
      signatures.parametersKey(1700000000),
      'bad0ee207bf429bd91402b77fc8f7a5b',
    );
  });
}
