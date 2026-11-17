import 'package:dokoshado/study_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Preferences extends Fake implements SharedPreferencesAsync {
  final values = <String, Object>{};

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
}

void main() {
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
        ['normal_study_day', {'study_day': '2026-11-10'}],
        ['normal_3_reached', {'study_day': '2026-11-10'}],
        ['normal_after_3_start', {'study_day': '2026-11-10'}],
        ['normal_study_day', {'study_day': '2026-11-11'}],
      ]);
    },
  );
}
