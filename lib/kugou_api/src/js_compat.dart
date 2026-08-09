import 'dart:convert';
import 'dart:typed_data';

/// The small set of JavaScript coercions that participate in KuGou signing.
///
/// This is deliberately not a JavaScript runtime. It only makes Dart produce
/// the same byte strings as the reference Node implementation.
String jsValueString(Object? value) {
  if (value == null) return 'null';
  if (value is bool) return value ? 'true' : 'false';
  if (value is String || value is int || value is BigInt) return '$value';
  if (value is double) {
    if (value.isNaN) return 'NaN';
    if (value.isInfinite) return value.isNegative ? '-Infinity' : 'Infinity';
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toString();
  }
  if (value is Uint8List) return value.join(',');
  if (value is Iterable<Object?>) {
    return value
        .map((item) => item == null ? '' : jsValueString(item))
        .join(',');
  }
  return '[object Object]';
}

String jsJsonEncode(Object? value) => jsonEncode(_normalizeJson(value));

Object? _normalizeJson(Object? value) {
  if (value is double && (!value.isFinite)) return null;
  if (value is double && value == value.truncateToDouble()) {
    return value.toInt();
  }
  if (value is Map<Object?, Object?>) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): _normalizeJson(entry.value),
    };
  }
  if (value is Iterable<Object?>) return value.map(_normalizeJson).toList();
  return value;
}
