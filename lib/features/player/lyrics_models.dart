import 'dart:convert';

import '../music/music_models.dart';

final class TimedLyricLine {
  const TimedLyricLine({
    required this.start,
    required this.end,
    required this.text,
    this.translation = '',
    this.romanization = '',
  });

  final Duration start;
  final Duration end;
  final String text;
  final String translation;
  final String romanization;
}

List<TimedLyricLine> parseKugouLyrics(String source) {
  if (source.trim().isEmpty) return const <TimedLyricLine>[];
  final auxiliary = _parseAuxiliaryLyrics(source);
  final parsed = <_MutableLyricLine>[];
  final krcLine = RegExp(r'^\[(\d+),(\d+)\](.*)$');
  final timedText = RegExp(r'<\d+,\d+,\d+>');

  for (final rawLine in const LineSplitter().convert(source)) {
    final match = krcLine.firstMatch(rawLine.trim());
    if (match == null) continue;
    final startMs = int.tryParse(match.group(1) ?? '');
    final durationMs = int.tryParse(match.group(2) ?? '');
    final content = (match.group(3) ?? '').replaceAll(timedText, '').trim();
    if (startMs == null || durationMs == null || content.isEmpty) continue;
    parsed.add(
      _MutableLyricLine(
        startMs: startMs,
        endMs: startMs + durationMs,
        text: content,
      ),
    );
  }

  if (parsed.isEmpty) return _parseLrcLyrics(source);
  parsed.sort((left, right) => left.startMs.compareTo(right.startMs));
  return List<TimedLyricLine>.generate(parsed.length, (index) {
    final line = parsed[index];
    return TimedLyricLine(
      start: Duration(milliseconds: line.startMs),
      end: Duration(milliseconds: line.endMs),
      text: line.text,
      translation: index < auxiliary.translations.length
          ? auxiliary.translations[index]
          : '',
      romanization: index < auxiliary.romanizations.length
          ? auxiliary.romanizations[index]
          : '',
    );
  }, growable: false);
}

int activeLyricLineIndex(List<TimedLyricLine> lines, Duration position) {
  if (lines.isEmpty || position < lines.first.start) return -1;
  var low = 0;
  var high = lines.length - 1;
  var result = 0;
  while (low <= high) {
    final middle = (low + high) >> 1;
    if (lines[middle].start <= position) {
      result = middle;
      low = middle + 1;
    } else {
      high = middle - 1;
    }
  }
  return result;
}

List<TimedLyricLine> _parseLrcLyrics(String source) {
  final parsed = <_MutableLyricLine>[];
  final pattern = RegExp(r'^\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\](.*)$');
  for (final rawLine in const LineSplitter().convert(source)) {
    final match = pattern.firstMatch(rawLine.trim());
    if (match == null) continue;
    final minutes = int.tryParse(match.group(1) ?? '');
    final seconds = int.tryParse(match.group(2) ?? '');
    final fractionText = match.group(3) ?? '';
    final text = (match.group(4) ?? '').trim();
    if (minutes == null || seconds == null || text.isEmpty) continue;
    final fraction = int.tryParse(fractionText) ?? 0;
    final fractionMs = switch (fractionText.length) {
      1 => fraction * 100,
      2 => fraction * 10,
      _ => fraction,
    };
    final startMs = (minutes * 60 + seconds) * 1000 + fractionMs;
    parsed.add(_MutableLyricLine(startMs: startMs, endMs: startMs, text: text));
  }
  parsed.sort((left, right) => left.startMs.compareTo(right.startMs));
  return List<TimedLyricLine>.generate(parsed.length, (index) {
    final line = parsed[index];
    final endMs = index + 1 < parsed.length
        ? parsed[index + 1].startMs
        : line.startMs + 5000;
    return TimedLyricLine(
      start: Duration(milliseconds: line.startMs),
      end: Duration(milliseconds: endMs),
      text: line.text,
    );
  }, growable: false);
}

_AuxiliaryLyrics _parseAuxiliaryLyrics(String source) {
  final match = RegExp(r'\[language:([^\]]+)\]').firstMatch(source);
  if (match == null) return const _AuxiliaryLyrics();
  try {
    final encoded = base64.normalize(match.group(1) ?? '');
    final Object? decoded = jsonDecode(utf8.decode(base64Decode(encoded)));
    final root = asJsonObject(decoded);
    final sections = asJsonList(root?['content']);
    var translations = const <String>[];
    var romanizations = const <String>[];
    for (final rawSection in sections) {
      final section = asJsonObject(rawSection);
      if (section == null) continue;
      final lines = _readAuxiliaryLines(section['lyricContent']);
      switch (readInt(section, const <String>['type'])) {
        case 0:
          romanizations = lines;
        case 1:
          translations = lines;
      }
    }
    return _AuxiliaryLyrics(
      translations: translations,
      romanizations: romanizations,
    );
  } on Object {
    return const _AuxiliaryLyrics();
  }
}

List<String> _readAuxiliaryLines(Object? value) => asJsonList(value)
    .map((rawLine) {
      if (rawLine is String) return rawLine.trim();
      return asJsonList(rawLine).whereType<String>().join().trim();
    })
    .toList(growable: false);

final class _MutableLyricLine {
  const _MutableLyricLine({
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  final int startMs;
  final int endMs;
  final String text;
}

final class _AuxiliaryLyrics {
  const _AuxiliaryLyrics({
    this.translations = const <String>[],
    this.romanizations = const <String>[],
  });

  final List<String> translations;
  final List<String> romanizations;
}
