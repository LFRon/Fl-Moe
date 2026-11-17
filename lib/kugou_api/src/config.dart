enum KugouClientVariant { standard, lite }

/// Protocol constants used by the Android KuGou clients emulated by this API.
final class KugouApiConfig {
  const KugouApiConfig({
    this.variant = KugouClientVariant.standard,
    this.gateway = 'https://gateway.kugou.com',
    this.requestTimeout = const Duration(seconds: 20),
    this.throwOnApiError = true,
  });

  final KugouClientVariant variant;
  final String gateway;
  final Duration requestTimeout;

  /// When enabled, normalized KuGou failures are raised as [KugouApiException].
  final bool throwOnApiError;

  bool get isLite => variant == KugouClientVariant.lite;
  Uri get gatewayUri => Uri.parse(gateway);
  int get appId => isLite ? liteAppId : standardAppId;
  int get clientVersion => isLite ? liteClientVersion : standardClientVersion;

  static const int standardAppId = 1005;
  static const int standardClientVersion = 20489;
  static const int liteAppId = 3116;
  static const int liteClientVersion = 11440;
  static const int sourceAppId = 2919;
  static const int apiVersion = 20;

  static const String wxAppId = 'wx79f2c4418704b4f8';
  static const String wxLiteAppId = 'wx72b795aca60ad321';
  static const String wxSecret = '4efcab88b700769e376e3f6087b8abc9';
  static const String wxLiteSecret = '33e486041e5e25729a4e3d2da7502f9a';
  static const String qqAppId = '205141';
  static const String qqLiteAppId = '101706348';
  static const int liteGradeClientVersion = 10597;
}
