import 'package:flutter/material.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dokoshado/activity.dart';
import 'package:dokoshado/dashboard.dart';
import 'package:dokoshado/daily_study_share.dart';
import 'package:dokoshado/review_prompt.dart';
import 'package:dokoshado/main.dart' show Practice;
import 'package:dokoshado/purchase_access.dart';
import 'package:dokoshado/learning_dashboard.dart';

StudyEvent event(
  DateTime date, {
  int seconds = 30,
  bool review = false,
  TicketKind? ticket,
}) => (
  when: date,
  seconds: seconds,
  difficultReview: review,
  rating: PracticeRating.hard,
  ticket: ticket,
);

class _Audio extends Fake implements AudioplayersPlatformInterface {
  @override
  Future<void> create(String id) async {}
  @override
  Future<void> stop(String id) async {}
  @override
  Future<void> pause(String id) async {}
  @override
  Future<void> release(String id) async {}
  @override
  Future<void> dispose(String id) async {}
  @override
  Future<int?> getCurrentPosition(String id) async => 0;
  @override
  Stream<AudioEvent> getEventStream(String id) => const Stream.empty();
}

class _GlobalAudio extends Fake implements GlobalAudioplayersPlatformInterface {
  @override
  Future<void> init() async {}
  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    AudioplayersPlatformInterface.instance = _Audio();
    GlobalAudioplayersPlatformInterface.instance = _GlobalAudio();
    for (final name in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel(name),
            (call) async => call.method == 'getCurrentPosition' ? 0 : null,
          );
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          PurchaseAccess.channel,
          (_) async => {'unlimited': false, 'busy': false, 'ready': false},
        );
  });
  tearDown(() {
    for (final name in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), null);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PurchaseAccess.channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ReviewPrompt.channel, null);
  });

  test('review needs five practices across two days, then both cooldown and ten more', () {
    final now = DateTime(2026, 11, 20, 12);
    final first = [
      event(now.subtract(const Duration(days: 1))),
      ...List.generate(4, (_) => event(now)),
    ];
    expect(reviewIsDue(first.take(4).toList(), now, null), isFalse);
    expect(
      reviewIsDue(List.generate(5, (_) => event(now)), now, null),
      isFalse,
    );
    expect(
      reviewIsDue(first, now, null),
      isTrue,
    ); // all hard ratings still eligible
    final history = '${now.millisecondsSinceEpoch}|5';
    final later = now.add(const Duration(days: 90));
    final more = [
      ...first,
      ...List.generate(10, (_) => event(now.add(const Duration(days: 2)))),
    ];
    expect(
      reviewIsDue(more, later.subtract(const Duration(seconds: 1)), history),
      isFalse,
    );
    expect(reviewIsDue(more.take(14).toList(), later, history), isFalse);
    expect(reviewIsDue(more, later, history), isTrue);
    expect(reviewIsDue(more, later, 'corrupt'), isFalse);
  });

  test(
    'review records request once and does not claim a rating was posted',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 11, 20, 12);
      final events = [
        event(now.subtract(const Duration(days: 1))),
        ...List.generate(4, (_) => event(now)),
      ];
      var requests = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ReviewPrompt.channel, (_) async {
            requests++;
            return null;
          });
      await ReviewPrompt.requestIfDue(prefs, events, now);
      await ReviewPrompt.requestIfDue(prefs, events, now);
      expect(requests, 1);
      expect(
        prefs.getString(ReviewPrompt.historyKey),
        '${now.millisecondsSinceEpoch}|5',
      );
    },
  );

  test('daily share aggregates practice review and challenge, with unsaved final attempt once', () {
    final now = DateTime(2026, 11, 20, 12);
    final pending = event(now, seconds: 45);
    final completed = [
      event(now, seconds: 30),
      event(now, seconds: 60, review: true),
      event(now.subtract(const Duration(days: 1)), seconds: 900),
    ];
    final total = todayStudy(completed, now, pending: pending);
    expect(total.questions, 3);
    expect(total.milliseconds, 135000);
    final text = dailyStudyShareText(total);
    expect(text, contains('3問・2分 15秒'));
    expect(text, endsWith('https://dokoshado.wisemap.biz/'));
    expect(todayStudy([...completed, pending], now).questions, 3);
    expect(todayStudy(completed, DateTime(2026, 11, 21)).questions, 0);
  });

  test('daily and monthly chart labels use two lines', () {
    final points = chartPeriods({}, DateTime(2026, 12, 1), monthly: false);
    expect(points.last.label, '1\n火');
    expect(points[points.length - 2].label, '30\n月');
    expect(
      chartPeriods({}, DateTime(2026, 12, 1), monthly: true).last.label,
      '12\n月',
    );
  });

  testWidgets('share image fits square with large system text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: DailyStudyShareCard(
              total: const DailyActivity(
                questions: 123,
                milliseconds: 12345678,
              ),
              date: DateTime(2026, 11, 20),
              category: 'travel',
              level: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('123問'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'category change is visible and saves multiple categories on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        'home.categories': ['travel'],
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('カテゴリー変更'));
      await tester.tap(find.text('カテゴリー変更'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('美容/コスメ').last);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(
        prefs.getStringList('home.categories'),
        containsAll(['travel', 'beauty']),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'third completion including a challenge shows share and preserves pending rating',
    (tester) async {
      final now = DateTime.now();
      final stamp = now.millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        'practice.travel-02': ['$stamp', '1', '$stamp|30|0|great'],
        'tickets.challengeEvents': ['$stamp|60|0||daily'],
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.pumpAndSettle();
      final dynamic state = tester.state(find.byType(Practice));
      state.treeOpen = true;
      state.start(0);
      state.round = 4;
      state.played = true;
      await state.advance();
      await tester.pumpAndSettle();
      expect(state.complete, isTrue);
      expect(state.events.length, 1);
      expect(state.completedChallenges.length, 1);
      expect(state.pendingCompletion, isNotNull);
      expect(
        todayStudy(
          <StudyEvent>[...state.events, ...state.completedChallenges],
          DateTime.now(),
          pending: state.pendingCompletion.event,
        ).questions,
        3,
      );
      await tester.scrollUntilVisible(find.text('今日の練習：3問完了'), 180);
      expect(find.text('今日の練習：3問完了'), findsOneWidget);
      await tester.ensureVisible(find.text('今日のがんばりをシェア'));
      await tester.tap(find.text('今日のがんばりをシェア'));
      await tester.pumpAndSettle();
      expect(find.byType(DailyStudyShareCard), findsOneWidget);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(prefs.getStringList('practice.travel-01'), isNull);
      expect(state.pendingCompletion, isNotNull);
      await tester.ensureVisible(find.text('まあまあ'));
      await tester.tap(find.text('まあまあ'));
      await tester.pumpAndSettle();
      expect(state.index, isNull);
      expect(
        studyEvents(prefs.getStringList('practice.travel-01')!).single.ticket,
        TicketKind.daily,
      );
      expect(state.availableTickets(DateTime.now()).daily, 1);
      await state.back();
      await tester.pumpAndSettle();
      await tester.tap(find.text('学習記録'));
      await tester.pumpAndSettle();
      final dashboard = tester.widget<LearningDashboard>(
        find.byType(LearningDashboard),
      );
      expect(dashboard.days[dayKey(DateTime.now())]!.questions, 3);
      expect(
        dashboard.days[dayKey(DateTime.now())]!.milliseconds,
        greaterThanOrEqualTo(90000),
      );
    },
  );

  testWidgets(
    'review charges daily then bonus, zero balance blocks, unlimited is exempt',
    (tester) async {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 4)).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        'practice.travel-01': ['$old', '1', '$old|20|0|hard'],
        'tickets.adRewards': 1,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.pumpAndSettle();
      final dynamic state = tester.state(find.byType(Practice));
      state.treeOpen = true;
      Future<void> finish() async {
        state.start(0);
        state.round = 4;
        state.played = true;
        await state.advance();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('ばっちり'));
        await tester.tap(find.text('ばっちり'));
        await tester.pumpAndSettle();
        expect(state.index, isNull);
      }

      await finish();
      expect(
        studyEvents(prefs.getStringList('practice.travel-01')!).last.ticket,
        TicketKind.daily,
      );
      expect(
        state.availableTickets(now.add(const Duration(minutes: 1))).daily,
        2,
      );
      await finish();
      await finish();
      await finish();
      expect(
        studyEvents(prefs.getStringList('practice.travel-01')!).last.ticket,
        TicketKind.bonus,
      );
      expect(state.availableTickets(DateTime.now()).daily, 0);
      expect(state.availableTickets(DateTime.now()).bonus, 0);
      state.start(0);
      await tester.pumpAndSettle();
      expect(find.text('チケットがありません'), findsOneWidget);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      state.plan.unlimited = true;
      await finish();
      expect(
        studyEvents(prefs.getStringList('practice.travel-01')!).last.ticket,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.pumpAndSettle();
      final dynamic restarted = tester.state(find.byType(Practice));
      expect(restarted.availableTickets(DateTime.now()).daily, 0);
      expect(restarted.availableTickets(DateTime.now()).bonus, 0);
    },
  );
}
