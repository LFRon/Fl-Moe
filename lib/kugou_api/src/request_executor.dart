import 'dart:convert';
import 'dart:typed_data';

import 'config.dart';
import 'crypto.dart';
import 'js_compat.dart';
import 'models.dart';
import 'session.dart';
import 'signatures.dart';
import 'ssa.dart';
import 'transport.dart';
import 'utilities.dart';

typedef KugouClock = DateTime Function();

final class KugouRequestExecutor {
  KugouRequestExecutor({
    required this.config,
    required this.session,
    required this.transport,
    KugouClock? clock,
  }) : _clock = clock ?? DateTime.now,
       signatures = KugouSignatures(config);

  final KugouApiConfig config;
  final KugouSession session;
  final KugouHttpTransport transport;
  final KugouClock _clock;
  final KugouSignatures signatures;
  late final KugouSsaGenerator ssa = KugouSsaGenerator(
    crypto: KugouCrypto(config),
    clock: _clock,
  );

  Future<KugouResponse<Object?>> execute(KugouRequest request) async {
    final cookies = <String, String>{...session.cookies, ...request.cookies};
    final dfid = cookies['dfid'] ?? '-';
    final mid = cookies['KUGOU_API_MID'] ?? '';
    final token = cookies['token'] ?? '';
    final userId = cookies['userid'] ?? '0';
    final clientTime = _clock().millisecondsSinceEpoch ~/ 1000;

    final defaultParameters = <String, Object?>{
      'dfid': dfid,
      'mid': mid,
      'uuid': '-',
      'appid': config.appId,
      'clientver': config.clientVersion,
      'clienttime': clientTime,
      if (token.isNotEmpty) 'token': token,
      if (userId != '0' && userId.isNotEmpty) 'userid': userId,
    };
    final parameters = <String, Object?>{
      if (!request.clearDefaultParameters) ...defaultParameters,
      ...request.parameters,
    };

    if (request.encryptKey) {
      parameters['key'] = signatures.key(
        parameters['hash']?.toString() ?? '',
        parameters['mid']?.toString() ?? '',
        parameters['userid'],
        parameters['appid'],
      );
    }

    final signatureData = _signatureData(request.data);
    if (!parameters.containsKey('signature') && !request.skipSignature) {
      parameters['signature'] = switch (request.signatureType) {
        KugouSignatureType.android => signatures.android(
          parameters,
          signatureData,
        ),
        KugouSignatureType.web => signatures.web(parameters, signatureData),
        KugouSignatureType.register => signatures.register(parameters),
      };
    }

    final forwardedIp = request.realIp;
    final headers = request.clearDefaultHeaders
        ? <String, Object?>{...request.headers}
        : <String, Object?>{
            'User-Agent':
                'Android15-1070-11083-46-0-DiscoveryDRADProtocol-wifi',
            ...request.headers,
            'dfid': dfid,
            if (parameters['clienttime'] != null)
              'clienttime': parameters['clienttime'],
            'mid': mid,
            'kg-rc': '1',
            'kg-thash': '5d816a0',
            'kg-rec': 1,
            'kg-rf': 'B9EDA08A64250DEFFBCADDEE00F8F25F',
            if (forwardedIp != null && forwardedIp.isNotEmpty) ...{
              'X-Real-IP': forwardedIp,
              'X-Forwarded-For': forwardedIp,
            },
          };

    var uri = (request.baseUri ?? config.gatewayUri).resolve(request.path);
    var queryParameters = parameters;
    if (uri.host.contains('openapicdn')) {
      final rawQuery = parameters.entries
          .map((entry) => '${entry.key}=${jsValueString(entry.value)}')
          .join('&');
      uri = Uri.parse('$uri?$rawQuery');
      queryParameters = <String, Object?>{};
    }

    try {
      final raw = await transport.send(
        KugouHttpRequest(
          uri: uri,
          method: request.method.toUpperCase(),
          parameters: queryParameters,
          headers: headers,
          body: request.data,
          responseType: request.responseType,
          formFields: request.formFields,
          formFileBytes: request.formFileBytes,
          formFileField: request.formFileField,
          formFileName: request.formFileName,
        ),
      );
      final setCookies = _headerValues(
        raw.headers,
        'set-cookie',
      ).map(cleanSetCookie).toList(growable: false);
      session.updateCookies(setCookies);

      var body = _decodeBody(raw.body);
      final ssaCode = _firstHeader(raw.headers, 'ssa-code');
      if (ssaCode != null && body is Map<String, Object?>) {
        body = Map<String, Object?>.from(body);
        final generated = ssa.generate(
          mid: mid,
          userId: userId,
          dfid: dfid,
          webGlHash: cookies['KUGOU_API_WEBGL'],
        );
        body
          ..['edt'] = generated.edt
          ..['sid'] = generated.sid
          ..['ssaCode'] = ssaCode;
      }
      final apiFailed =
          raw.statusCode < 200 ||
          raw.statusCode >= 300 ||
          (body is Map<String, Object?> &&
              (body['status'] == 0 ||
                  (body['error_code'] != null && body['error_code'] != 0)));
      final responseHeaders = <String, String>{
        for (final entry in raw.headers.entries)
          if (entry.value.isNotEmpty)
            entry.key.toLowerCase(): entry.value.first,
        'ssa-code': ?ssaCode,
      };
      final response = KugouResponse<Object?>(
        status: apiFailed ? 502 : 200,
        httpStatus: raw.statusCode,
        body: body,
        cookies: setCookies,
        headers: responseHeaders,
      );
      if (apiFailed && config.throwOnApiError) {
        throw KugouApiException(response);
      }
      return response;
    } on KugouApiException {
      rethrow;
    } on Object catch (error) {
      final response = KugouResponse<Object?>(
        status: 502,
        httpStatus: 0,
        body: <String, Object?>{'status': 0, 'msg': error.toString()},
      );
      if (config.throwOnApiError) throw KugouApiException(response, error);
      return response;
    }
  }

  Object _signatureData(Object? data) {
    if (data == null) return '';
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    if (data is Map<Object?, Object?> || data is Iterable<Object?>) {
      return jsJsonEncode(data);
    }
    return data.toString();
  }

  Object? _decodeBody(Object? body) {
    if (body is! String) return body;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  Iterable<String> _headerValues(
    Map<String, List<String>> headers,
    String name,
  ) sync* {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name) yield* entry.value;
    }
  }

  String? _firstHeader(Map<String, List<String>> headers, String name) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name && entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }
}
