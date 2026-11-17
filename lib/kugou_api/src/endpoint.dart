import 'config.dart';
import 'crypto.dart';
import 'models.dart';
import 'request_executor.dart';
import 'session.dart';
import 'signatures.dart';
import 'js_compat.dart';
import 'ssa.dart';

typedef KugouEndpointHandler =
    Future<KugouResponse<Object?>> Function(
      KugouEndpointContext context,
      Map<String, Object?> parameters,
    );

final class KugouEndpointContext {
  const KugouEndpointContext({
    required this.config,
    required this.session,
    required this.executor,
    required this.crypto,
  });

  final KugouApiConfig config;
  final KugouSession session;
  final KugouRequestExecutor executor;
  final KugouCrypto crypto;

  KugouSignatures get signatures => executor.signatures;
  KugouSsaGenerator get ssa => executor.ssa;
  int get nowMilliseconds => DateTime.now().millisecondsSinceEpoch;
  int get nowSeconds => nowMilliseconds ~/ 1000;
  Future<KugouResponse<Object?>> request(KugouRequest request) =>
      executor.execute(request);
}

Object? endpointCookie(
  KugouEndpointContext context,
  Map<String, Object?> parameters,
  String name,
) {
  final suppliedCookies = parameters['cookie'];
  if (suppliedCookies is Map<String, Object?> &&
      suppliedCookies.containsKey(name)) {
    return suppliedCookies[name];
  }
  return context.session[name];
}

bool jsTruthy(Object? value) {
  if (value == null || value == false || value == 0 || value == '') {
    return false;
  }
  if (value is double && value.isNaN) return false;
  return true;
}

Object? jsOr(Object? value, Object? fallback) =>
    jsTruthy(value) ? value : fallback;

Object? jsAnd(Object? left, Object? right) => jsTruthy(left) ? right : left;

num jsNumber(Object? value) {
  if (value == null || value == '') return 0;
  if (value is num) return value;
  if (value is bool) return value ? 1 : 0;
  return num.tryParse(value.toString()) ?? double.nan;
}

Object jsAdd(Object? left, Object? right) {
  if (left is String || right is String) {
    return '${jsString(left)}${jsString(right)}';
  }
  return jsNumber(left) + jsNumber(right);
}

int jsLength(Object? value) => switch (value) {
  final String text => text.length,
  final Iterable<Object?> items => items.length,
  final Map<Object?, Object?> map => map.length,
  _ => 0,
};

Map<String, Object?> stringObjectMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map<Object?, Object?>) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, Object?>{};
}

Map<String, String> stringStringMap(Object? value) => stringObjectMap(
  value,
).map((key, item) => MapEntry(key, item?.toString() ?? ''));

num jsMax(Iterable<Object?> values) =>
    values.map(jsNumber).reduce((left, right) => left > right ? left : right);

String jsTypeOf(Object? value) => switch (value) {
  null => 'undefined',
  String _ => 'string',
  num _ => 'number',
  bool _ => 'boolean',
  _ => 'object',
};

Object? mapValue(Object? value, Object? key) {
  if (value is Map<Object?, Object?>) return value[key];
  if (value is List<Object?>) {
    final index = jsNumber(key).toInt();
    return index >= 0 && index < value.length ? value[index] : null;
  }
  return null;
}

String jsString(Object? value) => jsValueString(value);

String stringParameter(
  Map<String, Object?> parameters,
  String name, [
  String fallback = '',
]) => parameters[name]?.toString() ?? fallback;

int intParameter(
  Map<String, Object?> parameters,
  String name, [
  int fallback = 0,
]) => switch (parameters[name]) {
  final int value => value,
  final num value => value.toInt(),
  final Object value => int.tryParse(value.toString()) ?? fallback,
  null => fallback,
};

bool boolParameter(
  Map<String, Object?> parameters,
  String name, [
  bool fallback = false,
]) {
  final value = parameters[name];
  if (value == null || value == '') return fallback;
  if (value is bool) return value;
  return !const {'0', 'false', 'no'}.contains(value.toString().toLowerCase());
}

/// JavaScript `values.find(v => v !== undefined && v !== null && String(v) !== '')`.
Object? firstValue(Iterable<Object?> values) {
  for (final value in values) {
    if (value != null && value.toString().isNotEmpty) return value;
  }
  return null;
}

/// Removes null/undefined-like entries the way the upstream `compact` helper
/// does for request parameters. Empty strings are retained only when
/// [keepEmptyStrings] is true.
Map<String, Object?> compactObject(
  Map<String, Object?> values, {
  bool keepEmptyStrings = false,
}) => <String, Object?>{
  for (final entry in values.entries)
    if (entry.value != null &&
        (keepEmptyStrings ||
            entry.value is! String ||
            (entry.value! as String).isNotEmpty))
      entry.key: entry.value,
};

KugouResponse<Object?> endpointFailure({
  int status = 502,
  int httpStatus = 0,
  required Map<String, Object?> body,
}) =>
    KugouResponse<Object?>(status: status, httpStatus: httpStatus, body: body);

KugouResponse<Object?> rejectEndpoint(
  KugouEndpointContext context, {
  int status = 502,
  int httpStatus = 0,
  required Map<String, Object?> body,
}) {
  final response = endpointFailure(
    status: status,
    httpStatus: httpStatus,
    body: body,
  );
  if (context.config.throwOnApiError) throw KugouApiException(response);
  return response;
}
