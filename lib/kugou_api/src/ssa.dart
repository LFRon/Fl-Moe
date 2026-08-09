import 'dart:math';

import 'crypto.dart';
import 'utilities.dart';

const kugouSsaPublicKey = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoW2+Ylo8ALePSQTP0xBF
lFmEOHvBD9tS+s7DBlfKEu3RzzvZTaX1JtYbX4+AVUqj6ARz8IM+CKByqGFvbHN/
W64XxNI+q7z36ajCL3VTJ2W5G9MCJitc6oGbire4NQfhaEq0nC+hxBWQvCbIFflA
2ItrLUbSU7z1bHA/a+jlQm4OWvY+IKnTryOJTPuT1yNOVjbJ8wBLKy2DgQr9pPqW
PmEQtGpR5IM9V8Kao6PaSdKYOWGbX3i2+RzIKhvZUxxtJwdVbqPlDPlW9h4/xIBc
56Lgvr4aIl8nFtwbj4UJVUTFuGrs0tY9H/tXvZ22dUCKuGxW/gW7ZF+gXz6vHtYa
rQIDAQAB
-----END PUBLIC KEY-----''';

final class KugouSsaResult {
  const KugouSsaResult({required this.sid, required this.edt});

  final String sid;
  final String edt;
}

final class KugouSsaGenerator {
  KugouSsaGenerator({
    required this.crypto,
    Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? Random.secure(),
       _clock = clock ?? DateTime.now;

  final KugouCrypto crypto;
  final Random _random;
  final DateTime Function() _clock;

  KugouSsaResult generate({
    required Object? mid,
    required Object? userId,
    required Object? dfid,
    String? webGlHash,
  }) {
    final sentinel = 0xffffffff - _random.nextInt(20);
    final key = md5Hex(randomString(16, _random)).substring(0, 16);
    final points = _randomInt(30, 60);
    final startX = _randomInt(200, 600);
    final startY = _randomInt(200, 500);
    final endX = _randomInt(500, 700);
    final endY = _randomInt(80, 150);
    final data = _generateData(
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      points: points,
      sentinel: sentinel,
    );
    final timestamp = _clock().millisecondsSinceEpoch;
    final plaintext =
        'mid=${_defaultValue(mid)};userid=${_defaultValue(userId)};'
        'dfid=${_defaultValue(dfid)};'
        'webgl=${webGlHash == null || webGlHash.isEmpty ? generateWebGlHash(_random) : webGlHash};'
        'webdriver=0;ts=$timestamp;data=$data';
    return KugouSsaResult(
      edt: crypto.aesCbcBase64Encrypt(
        plaintext,
        key: key,
        iv: 'kugousecurity123',
      ),
      sid: crypto.rsaOaepSha256Encrypt(key, publicKeyPem: kugouSsaPublicKey),
    );
  }

  Object _defaultValue(Object? value) =>
      value == null || value == '' || value == 0 ? 0 : value;

  String _generateData({
    required int startX,
    required int startY,
    required int endX,
    required int endY,
    required int points,
    required int sentinel,
  }) {
    final entries = <String>[
      '5,0,0',
      '5,$sentinel,0',
      '5,0,0',
      '5,$sentinel,0',
    ];
    var timestamp = _randomInt(5, 20);
    var eventIndex = 0;
    entries
      ..add('6,$timestamp,$eventIndex,750,500')
      ..add('6,$sentinel,$eventIndex,750,500');
    eventIndex++;
    for (var index = 0; index < 3; index++) {
      timestamp += _randomInt(80, 600);
      entries
        ..add('5,$timestamp,$eventIndex')
        ..add('5,$sentinel,$eventIndex');
      eventIndex++;
    }
    final path = _bezier(startX, startY, endX, endY, points);
    var subIndex = 0;
    for (var index = 0; index < path.length; index++) {
      final point = path[index];
      timestamp += _randomInt(8, 50);
      entries
        ..add('3,$timestamp,$subIndex,${point.x.round()},${point.y.round()}')
        ..add('3,$sentinel,$subIndex,${point.x.round()},${point.y.round()}');
      if (index > 0 && index % 12 == 0) {
        timestamp += _randomInt(20, 60);
        entries
          ..add('5,$timestamp,$eventIndex')
          ..add('5,$sentinel,$eventIndex');
        eventIndex++;
      }
      subIndex = (subIndex + 1) % 2;
    }
    timestamp += _randomInt(5, 30);
    entries
      ..add(
        '3,$timestamp,1,${endX + _randomInt(-5, 5)},'
        '${endY + _randomInt(-5, 5)}',
      )
      ..add('3,$sentinel,1,$endX,$endY');
    return entries.join(':');
  }

  List<Point<double>> _bezier(int sx, int sy, int ex, int ey, int count) {
    final c1x = sx + (ex - sx) * .3 + _randomInt(-80, 80);
    final c1y = sy + (ey - sy) * .2 + _randomInt(-60, 60);
    final c2x = sx + (ex - sx) * .7 + _randomInt(-60, 60);
    final c2y = sy + (ey - sy) * .8 + _randomInt(-40, 40);
    return <Point<double>>[
      for (var index = 0; index <= count; index++)
        _bezierPoint(
          sx.toDouble(),
          sy.toDouble(),
          ex.toDouble(),
          ey.toDouble(),
          c1x,
          c1y,
          c2x,
          c2y,
          index / count,
        ),
    ];
  }

  Point<double> _bezierPoint(
    double sx,
    double sy,
    double ex,
    double ey,
    double c1x,
    double c1y,
    double c2x,
    double c2y,
    double t,
  ) {
    final u = 1 - t;
    final jitter = max(.5, 3 - t * 2.5);
    final x =
        u * u * u * sx +
        3 * u * u * t * c1x +
        3 * u * t * t * c2x +
        t * t * t * ex;
    final y =
        u * u * u * sy +
        3 * u * u * t * c1y +
        3 * u * t * t * c2y +
        t * t * t * ey;
    return Point<double>(
      x + (_random.nextDouble() - .5) * jitter,
      y + (_random.nextDouble() - .5) * jitter,
    );
  }

  int _randomInt(int minimum, int maximum) =>
      _random.nextInt(maximum - minimum + 1) + minimum;
}
