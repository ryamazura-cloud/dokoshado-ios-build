import 'dart:math' as math;

import 'activity.dart';
import 'dashboard.dart';

const dailyTicketLimit = 3;

typedef TicketBalance = ({int daily, int bonus});

TicketBalance ticketBalance({
  required List<StudyEvent> practice,
  required List<StudyEvent> challenges,
  required DateTime activated,
  required DateTime now,
  required int adRewards,
  List<QuestClaim> claims = const [],
  DateTime? claimRewardsFrom,
}) {
  final today = dayKey(now);
  final days = <String, List<StudyEvent>>{};
  final weeks = <String, Map<String, DateTime>>{};
  var dailySpent = 0;
  var bonusSpent = 0;
  for (final event in [...practice, ...challenges]) {
    if (event.when.isAfter(now)) continue;
    switch (event.ticket) {
      case TicketKind.daily:
        if (dayKey(event.when) == today) dailySpent++;
      case TicketKind.bonus:
        bonusSpent++;
      case null:
        break;
    }
  }

  final ordered = practice.where((event) => !event.when.isAfter(now)).toList()
    ..sort((a, b) => a.when.compareTo(b.when));
  for (final event in ordered) {
    final day = dayKey(event.when);
    final date = event.when;
    final monday = DateTime(date.year, date.month, date.day - date.weekday + 1);
    days.putIfAbsent(day, () => []).add(event);
    weeks.putIfAbsent(dayKey(monday), () => {}).putIfAbsent(day, () => date);
  }

  final rewardedQuests = <String>{};
  bool wasAutomatic(DateTime reached) =>
      !reached.isBefore(activated) &&
      (claimRewardsFrom == null || reached.isBefore(claimRewardsFrom));
  for (final entry in days.entries) {
    final day = entry.value;
    if (day.length < 2) continue;
    final review = day.where((event) => event.difficultReview).firstOrNull;
    if (review == null) continue;
    final second = day[1].when;
    final reached = second.isAfter(review.when) ? second : review.when;
    if (wasAutomatic(reached)) {
      rewardedQuests.add('${dayLabel(reached)}|ten');
    }
  }
  for (final entry in weeks.entries) {
    final week = entry.value;
    final studied = week.values.toList();
    for (final goal in [3, 5]) {
      if (studied.length >= goal && wasAutomatic(studied[goal - 1])) {
        final date = studied[goal - 1];
        final monday = DateTime(
          date.year,
          date.month,
          date.day - date.weekday + 1,
        );
        rewardedQuests.add(
          '${dayLabel(monday)}|${goal == 3 ? 'three-days' : 'five-days'}',
        );
      }
    }
  }
  if (claimRewardsFrom != null) {
    for (final claim in claims) {
      if (!claim.when.isBefore(claimRewardsFrom) &&
          !claim.when.isBefore(activated) &&
          !claim.when.isAfter(now) &&
          ticketRewardForQuest(claim.key) > 0) {
        rewardedQuests.add(claim.key);
      }
    }
  }
  return (
    daily: math.max(0, dailyTicketLimit - dailySpent),
    bonus: math.max(0, adRewards + rewardedQuests.length - bonusSpent),
  );
}

TicketKind? nextTicket(TicketBalance balance) => balance.daily > 0
    ? TicketKind.daily
    : balance.bonus > 0
    ? TicketKind.bonus
    : null;
