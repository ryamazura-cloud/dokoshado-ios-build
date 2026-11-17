import 'dart:convert';

import 'package:dokoshado/karaoke_timings.dart';
import 'package:dokoshado/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('word windows follow unequal speech durations and clear in silence', () {
    final track = KaraokeTrack('A longer phrase.', 2000, [
      (100, 180),
      (260, 1100),
      (1300, 1800),
    ]);
    expect(track.wordAt(const Duration(milliseconds: 99)), -1);
    expect(track.wordAt(const Duration(milliseconds: 100)), 0);
    expect(track.wordAt(const Duration(milliseconds: 180)), -1);
    expect(track.wordAt(const Duration(milliseconds: 1000)), 1);
    expect(track.wordAt(const Duration(milliseconds: 1400)), 2);
    expect(track.wordAt(const Duration(milliseconds: 1900)), -1);
    // A resumed/changed-speed player reports media time, so no wall-clock offset is accumulated.
    expect(track.wordAt(const Duration(milliseconds: 1400)), 2);
    expect(track.wordAt(const Duration(milliseconds: 260)), 1);
  });

  test(
    'mismatched text is never highlighted with another revision of timings',
    () {
      final catalog = KaraokeCatalog.decode(
        jsonEncode({
          'schema': 1,
          'clips': {
            'sample': {
              'text': 'Hello there',
              'durationMs': 900,
              'words': [
                [0, 200],
                [300, 800],
              ],
            },
          },
        }),
      );
      expect(
        catalog.wordAt(
          'sample',
          'Hello there',
          const Duration(milliseconds: 400),
        ),
        1,
      );
      expect(
        catalog.wordAt(
          'sample',
          'Different text',
          const Duration(milliseconds: 400),
        ),
        -1,
      );
      expect(
        catalog.wordAt(
          'missing',
          'Hello there',
          const Duration(milliseconds: 400),
        ),
        -1,
      );
    },
  );

  test('packaged timings cover all 510 current audio transcripts', () async {
    final catalog = await KaraokeCatalog.load();
    expect(catalog.tracks.length, 510);
    for (final clip in app.clips) {
      final track = catalog.tracks[clip.file]!;
      expect(track.text, clip.english, reason: clip.file);
      expect(
        track.windows.length,
        clip.english.split(' ').length,
        reason: clip.file,
      );
      expect(
        track.windows.every(
          (window) => window.$1 < window.$2 && window.$2 <= track.durationMs,
        ),
        isTrue,
      );
    }
  });
}
