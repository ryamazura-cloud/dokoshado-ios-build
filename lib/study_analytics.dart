import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity.dart';

class StudyAnalytics {
  StudyAnalytics({
    required this.preferences,
    required this.logEvent,
    required this.setCollectionEnabled,
    this.enabled = false,
  });

  static const _enabledKey = 'dokoshado.analytics.enabled.v1';
  static const _dayStateKey = 'dokoshado.analytics.day.v1';

  final SharedPreferencesAsync preferences;
  final Future<void> Function(String, Map<String, Object>) logEvent;
  final Future<void> Function(bool) setCollectionEnabled;
  bool enabled;
  Future<void> _pending = Future.value();

  static Future<bool> loadEnabled(
    SharedPreferencesAsync preferences, {
    required TargetPlatform platform,
  }) async =>
      await preferences.getBool(_enabledKey) ??
      (platform == TargetPlatform.android);

  static Future<StudyAnalytics?> connect() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS))
      return null;
    try {
      await Firebase.initializeApp();
      final firebase = FirebaseAnalytics.instance;
      final preferences = SharedPreferencesAsync();
      final enabled = await loadEnabled(
        preferences,
        platform: defaultTargetPlatform,
      );
      await firebase.setConsent(
        adStorageConsentGranted: false,
        adUserDataConsentGranted: false,
        adPersonalizationSignalsConsentGranted: false,
      );
      await firebase.setAnalyticsCollectionEnabled(enabled);
      return StudyAnalytics(
        preferences: preferences,
        logEvent: (name, params) =>
            firebase.logEvent(name: name, parameters: params),
        setCollectionEnabled: firebase.setAnalyticsCollectionEnabled,
        enabled: enabled,
      );
    } catch (_) {
      // Offline or unconfigured builds still support all practice features.
      return null;
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _pending.then((_) => action());
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> changeEnabled(bool value) => _enqueue(() async {
    await setCollectionEnabled(value);
    enabled = value;
    try {
      await preferences.setBool(_enabledKey, value);
    } catch (_) {
      enabled = false;
      await setCollectionEnabled(false);
      rethrow;
    }
  });

  Future<void> completed(DateTime now) => _record(now, completion: true);
  Future<void> started(DateTime now) => _record(now, completion: false);

  Future<void> _record(DateTime now, {required bool completion}) =>
      _enqueue(() async {
        if (!enabled) return;
        final date = dayKey(now.toLocal());
        final stored = (await preferences.getString(_dayStateKey))?.split('|');
        final count = stored?.length == 2 && stored!.first == date
            ? int.tryParse(stored.last) ?? 0
            : 0;
        final int next;
        final String? name;
        if (completion && count < 3) {
          next = count + 1;
          name = switch (next) {
            1 => 'normal_study_day',
            3 => 'normal_3_reached',
            _ => null,
          };
        } else if (!completion && count == 3) {
          next = 4;
          name = 'normal_after_3_start';
        } else {
          return;
        }
        await preferences.setString(_dayStateKey, '$date|$next');
        if (name != null) await logEvent(name, {'study_day': date});
      }).catchError((Object _) {
        // Analytics must never block practice.
      });
}
