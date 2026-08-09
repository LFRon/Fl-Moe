import 'dart:typed_data';

import 'signatures.dart';

enum KugouResponseType { json, bytes, text }

final class KugouRequest {
  KugouRequest({
    required this.path,
    this.method = 'GET',
    this.baseUri,
    Map<String, Object?>? parameters,
    this.data,
    Map<String, Object?>? headers,
    Map<String, String>? cookies,
    this.signatureType = KugouSignatureType.android,
    this.encryptKey = false,
    this.clearDefaultParameters = false,
    this.skipSignature = false,
    this.responseType = KugouResponseType.json,
    this.realIp,
  }) : parameters = parameters ?? <String, Object?>{},
       headers = headers ?? <String, Object?>{},
       cookies = cookies ?? <String, String>{};

  final String path;
  final String method;
  final Uri? baseUri;
  final Map<String, Object?> parameters;
  final Object? data;
  final Map<String, Object?> headers;
  final Map<String, String> cookies;
  final KugouSignatureType signatureType;
  final bool encryptKey;
  final bool clearDefaultParameters;
  final bool skipSignature;
  final KugouResponseType responseType;
  final String? realIp;
}

final class KugouResponse<T> {
  const KugouResponse({
    required this.status,
    required this.httpStatus,
    required this.body,
    this.cookies = const <String>[],
    this.headers = const <String, String>{},
  });

  /// Compatibility status used by the reference API: 200 or 502.
  final int status;
  final int httpStatus;
  final T body;
  final List<String> cookies;
  final Map<String, String> headers;

  bool get isSuccess => status == 200;
}

final class KugouApiException implements Exception {
  const KugouApiException(this.response, [this.cause]);

  final KugouResponse<Object?> response;
  final Object? cause;

  @override
  String toString() =>
      'KugouApiException(status: ${response.status}, '
      'httpStatus: ${response.httpStatus}, body: ${response.body})';
}

final class KugouTransportException implements Exception {
  const KugouTransportException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'KugouTransportException: $message';
}

bool isBinaryBody(Object? value) => value is Uint8List || value is List<int>;
