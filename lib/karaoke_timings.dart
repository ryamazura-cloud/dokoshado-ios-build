import 'dart:convert';

import 'package:flutter/services.dart';

class KaraokeTrack {
  const KaraokeTrack(this.text, this.durationMs, this.windows);
  final String text;
  final int durationMs;
  final List<(int, int)> windows;

  int wordAt(Duration position) {
    final time = position.inMilliseconds;
    var low = 0, high = windows.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (windows[middle].$1 <= time) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final index = low - 1;
    return index >= 0 && time < windows[index].$2 ? index : -1;
  }
}

class KaraokeCatalog {
  const KaraokeCatalog.empty() : tracks = const {};
  KaraokeCatalog._(this.tracks);
  final Map<String, KaraokeTrack> tracks;

  factory KaraokeCatalog.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    if (json['schema'] != 1) {
      throw const FormatException('Unknown timing schema');
    }
    final tracks = <String, KaraokeTrack>{};
    for (final entry in (json['clips'] as Map<String, dynamic>).entries) {
      final clip = entry.value as Map<String, dynamic>;
      final text = clip['text'] as String;
      final duration = clip['durationMs'] as int;
      final windows = <(int, int)>[];
      var previousEnd = 0;
      for (final pair in clip['words'] as List) {
        final start = pair[0] as int, end = pair[1] as int;
        if (start < previousEnd || end <= start || end > duration) {
          throw FormatException('Invalid word timing: ${entry.key}');
        }
        windows.add((start, end));
        previousEnd = end;
      }
      if (duration <= 0 || windows.length != text.split(' ').length) {
        throw FormatException('Timing/transcript mismatch: ${entry.key}');
      }
      tracks[entry.key] = KaraokeTrack(
        text,
        duration,
        List.unmodifiable(windows),
      );
    }
    return KaraokeCatalog._(Map.unmodifiable(tracks));
  }

  static Future<KaraokeCatalog> load() async => KaraokeCatalog.decode(
    await rootBundle.loadString('assets/timings/word_timings.json'),
  );

  int wordAt(String file, String text, Duration position) {
    final track = tracks[file];
    // Never use timing data that belongs to another revision of the text.
    return track != null && track.text == text ? track.wordAt(position) : -1;
  }
}
