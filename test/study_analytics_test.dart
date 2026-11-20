import 'package:dokoshado/study_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Preferences extends Fake implements SharedPreferencesAsync {
  final values = <String, Object>{};

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
}

void main() {
  test(
    'Android defaults on, iOS remains off, saved choices survive restart',
    () async {
      final prefs = _Preferences();
      Future<bool> load(TargetPlatform platform) =>
          StudyAnalytics.loadEnabled(prefs, platform: platform);
      expect(await load(TargetPlatform.android), isTrue);
      expect(await load(TargetPlatform.iOS), isFalse);
      final sent = <String>[];
      final analytics = StudyAnalytics(
        preferences: prefs,
        logEvent: (name, _) async => sent.add(name),
        setCollectionEnabled: (_) async {},
        enabled: await load(TargetPlatform.android),
      );
      await analytics.completed(DateTime(2026, 11, 19));
      expect(sent, ['normal_study_day']);
      await analytics.changeEnabled(false);
      expect(await load(TargetPlatform.android), isFalse);
      await analytics.completed(DateTime(2026, 11, 20));
      expect(sent, ['normal_study_day']);
      await analytics.changeEnabled(true);
      expect(await load(TargetPlatform.android), isTrue);
      expect(await load(TargetPlatform.iOS), isTrue);
    },
  );

  test(
    'normal practice milestones are opt-in and recorded once per local day',
    () async {
      final sent = <(String, Map<String, Object>)>[];
      final choices = <bool>[];
      final prefs = _Preferences();
      StudyAnalytics tracker({bool enabled = false}) => StudyAnalytics(
        preferences: prefs,
        logEvent: (name, params) async => sent.add((name, params)),
        setCollectionEnabled: (value) async => choices.add(value),
        enabled: enabled,
      );
      final today = DateTime(2026, 11, 10, 23);
      final nextDay = DateTime(2026, 11, 11);
      final analytics = tracker();
      await analytics.completed(today);
      expect(sent, isEmpty);
      await analytics.changeEnabled(true);
      await Future.wait([
        analytics.started(today),
        analytics.completed(today),
        analytics.completed(today),
        analytics.started(today),
        analytics.completed(today),
      ]);
      final restarted = tracker(enabled: true);
      await restarted.started(today);
      await restarted.started(today);
      await restarted.completed(today);
      await restarted.started(nextDay);
      await restarted.completed(nextDay);
      await restarted.changeEnabled(false);
      await restarted.completed(nextDay);
      expect(choices, [true, false]);
      expect(sent.map((event) => [event.$1, event.$2]), [
        [
          'normal_study_day',
          {'study_day': '2026-11-10'},
        ],
        [
          'normal_3_reached',
          {'study_day': '2026-11-10'},
        ],
        [
          'normal_after_3_start',
          {'study_day': '2026-11-10'},
        ],
        [
          'normal_study_day',
          {'study_day': '2026-11-11'},
        ],
      ]);
    },
  );
}
