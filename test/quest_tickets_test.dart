import 'package:dokoshado/dashboard.dart';
import 'package:dokoshado/tickets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StudyEvent event(int day, {bool review = false, TicketKind? spent}) => (
    when: DateTime(2026, 11, day, review ? 10 : 9),
    seconds: 30,
    difficultReview: review,
    rating: PracticeRating.okay,
    ticket: spent,
  );

  test(
    'each target quest grants one ticket once and balances survive spending',
    () {
      final practice = <StudyEvent>[];
      final claims = <QuestClaim>[];
      void claim(String key, int day) =>
          claims.add((key: key, when: DateTime(2026, 11, day, 11)));
      TicketBalance balance(int day) => ticketBalance(
        practice: practice,
        challenges: [],
        activated: DateTime(2026, 11, 9),
        now: DateTime(2026, 11, day, 12),
        adRewards: 0,
        claims: claims,
        claimRewardsFrom: DateTime(2026, 11, 9),
      );
      practice.add(event(9));
      expect(balance(9).bonus, 0);
      practice.add(event(9, review: true));
      expect(balance(9).bonus, 0); // 達成だけでは付与しない
      claim('2026/11/9|ten', 9);
      expect(balance(9).bonus, 1);
      claim('2026/11/9|ten', 9);
      expect(balance(9).bonus, 1); // 重複受取を数えない
      practice.add(event(9));
      expect(balance(9).bonus, 1); // 達成後の追加学習で重複しない
      practice.add(event(10));
      expect(balance(10).bonus, 1);
      practice.add(event(11));
      expect(balance(11).bonus, 1);
      claim('2026/11/9|three-days', 11);
      expect(balance(11).bonus, 2);
      practice.add(event(12));
      practice.add(event(13));
      expect(balance(13).bonus, 2);
      claim('2026/11/9|five-days', 13);
      expect(balance(13).bonus, 3);
      expect(balance(14).bonus, 3); // 日をまたいでも保持
      practice.add(event(14, spent: TicketKind.bonus));
      expect(balance(14).bonus, 2);
      expect(balance(16).bonus, 2); // 週をまたいでも保持
    },
  );

  test(
    'previous achievements before ticket activation are not credited again',
    () {
      expect(
        ticketBalance(
          practice: [event(9), event(9, review: true), event(10), event(11)],
          challenges: [],
          activated: DateTime(2026, 11, 12),
          now: DateTime(2026, 11, 13),
          adRewards: 0,
        ).bonus,
        0,
      );
    },
  );

  test(
    'migration preserves automatic rewards without double credit on claim',
    () {
      final practice = [event(9), event(9, review: true), event(10), event(11)];
      TicketBalance balance(List<QuestClaim> claims) => ticketBalance(
        practice: practice,
        challenges: [],
        activated: DateTime(2026, 11, 9),
        claimRewardsFrom: DateTime(2026, 11, 12),
        now: DateTime(2026, 11, 13, 12),
        adRewards: 0,
        claims: claims,
      );
      expect(balance([]).bonus, 2);
      expect(
        balance([
          (key: '2026/11/9|ten', when: DateTime(2026, 11, 12)),
          (key: '2026/11/9|three-days', when: DateTime(2026, 11, 12)),
        ]).bonus,
        2,
      );
      practice.add(event(12));
      practice.add(event(13));
      expect(balance([]).bonus, 2); // 移行後の達成は受取待ち
      expect(
        balance([
          (key: '2026/11/9|five-days', when: DateTime(2026, 11, 13, 11)),
        ]).bonus,
        3,
      );
    },
  );

  for (final title in ['シャドーイングの特訓', '今週の冒険', '今週の大冒険']) {
    testWidgets('$title displays EXP and its additional ticket', (
      tester,
    ) async {
      final quest = questsFor(
        [],
        {},
        DateTime(2026, 11, 17),
      ).singleWhere((q) => q.title == title);
      await tester.pumpWidget(
        MaterialApp(
          home: QuestPage(quests: [quest], claim: (_) async => true),
        ),
      );
      expect(
        find.textContaining('報酬 ${quest.reward} EXP ＋ 追加チケット1枚'),
        findsOneWidget,
      );
      expect(find.text('「報酬を受け取る」でEXPと追加チケットを受け取れます。'), findsOneWidget);
    });
  }
}
