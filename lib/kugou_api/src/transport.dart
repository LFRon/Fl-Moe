import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'models.dart';

final class KugouHttpRequest {
  const KugouHttpRequest({
    required this.uri,
    required this.method,
    required this.parameters,
    required this.headers,
    required this.responseType,
    this.body,
  });

  final Uri uri;
  final String method;
  final Map<String, Object?> parameters;
  final Map<String, Object?> headers;
  final Object? body;
  final KugouResponseType responseType;
}

final class KugouRawResponse {
  const KugouRawResponse({
    required this.statusCode,
    required this.body,
    this.headers = const <String, List<String>>{},
  });

  final int statusCode;
  final Object? body;
  final Map<String, List<String>> headers;
}

abstract interface class KugouHttpTransport {
  Future<KugouRawResponse> send(KugouHttpRequest request);
  void close();
}

/// Default desktop transport. Endpoint code never depends on this class.
final class DioKugouTransport implements KugouHttpTransport {
  DioKugouTransport({Dio? dio, Duration timeout = const Duration(seconds: 20)})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: timeout,
              sendTimeout: timeout,
              receiveTimeout: timeout,
              validateStatus: (_) => true,
            ),
          ),
      _ownsDio = dio == null;

  final Dio _dio;
  final bool _ownsDio;

  @override
  Future<KugouRawResponse> send(KugouHttpRequest request) async {
    try {
      final response = await _dio.request<Object?>(
        request.uri.toString(),
        data: request.body,
        queryParameters: request.parameters,
        options: Options(
          method: request.method,
          headers: request.headers,
          responseType: switch (request.responseType) {
            KugouResponseType.json => ResponseType.json,
            KugouResponseType.bytes => ResponseType.bytes,
            KugouResponseType.text => ResponseType.plain,
          },
        ),
      );
      return KugouRawResponse(
        statusCode: response.statusCode ?? 0,
        body: _normalizeBytes(response.data),
        headers: response.headers.map,
      );
    } on DioException catch (error) {
      throw KugouTransportException(
        error.message ?? 'Dio request failed',
        error,
      );
    }
  }

  Object? _normalizeBytes(Object? value) {
    if (value is List<int> && value is! Uint8List) {
      return Uint8List.fromList(value);
    }
    return value;
  }

  @override
  void close() {
    if (_ownsDio) _dio.close(force: true);
  }
}
