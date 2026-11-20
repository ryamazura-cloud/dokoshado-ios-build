import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity.dart';
import 'dashboard.dart';

bool reviewIsDue(List<StudyEvent> events, DateTime now, String? previous) {
  final completed = events.where((e) => !e.when.isAfter(now)).toList();
  if (completed.length < 5 ||
      completed.map((e) => dayKey(e.when.toLocal())).toSet().length < 2) {
    return false;
  }
  if (previous == null) return true;
  final parts = previous.split('|');
  if (parts.length != 2) return false;
  final stamp = int.tryParse(parts[0]);
  final count = int.tryParse(parts[1]);
  if (stamp == null || count == null) return false;
  return now.difference(DateTime.fromMillisecondsSinceEpoch(stamp)) >=
          const Duration(days: 90) &&
      completed.length >= count + 10;
}

class ReviewPrompt {
  static const channel = MethodChannel('biz.wisemap.dokoshado/review');
  static const historyKey = 'review.lastRequest.v1';
  static bool _requesting = false;

  static Future<void> requestIfDue(
    SharedPreferences prefs,
    List<StudyEvent> events,
    DateTime now,
  ) async {
    if (_requesting ||
        kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS) ||
        !reviewIsDue(events, now, prefs.getString(historyKey)))
      return;
    _requesting = true;
    try {
      // Record an attempt, not a posted review: stores can silently suppress UI.
      final count = events.where((e) => !e.when.isAfter(now)).length;
      if (!await prefs.setString(
        historyKey,
        '${now.millisecondsSinceEpoch}|$count',
      ))
        return;
      await channel.invokeMethod<void>('requestReview');
    } catch (_) {
      // A missing store or unavailable review service must not block learning.
    } finally {
      _requesting = false;
    }
  }
}
