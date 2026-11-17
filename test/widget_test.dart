import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dokoshado/main.dart'
    show Practice, TutorialStep, reviewAvailableOn;
import 'package:dokoshado/growth.dart';
import 'package:dokoshado/dashboard.dart'
    show
        PracticeRating,
        QuestPage,
        StudyEvent,
        TicketKind,
        encodeStudyEvent,
        questsFor,
        studyEvents;
import 'package:dokoshado/tickets.dart';
import 'package:dokoshado/travel.dart';
import 'package:dokoshado/expanded.dart';
import 'package:dokoshado/challenges.dart';
import 'package:dokoshado/interests.dart';
import 'package:dokoshado/study_analytics.dart';
import 'package:dokoshado/purchase_access.dart';

class _AnalyticsPreferences extends Fake implements SharedPreferencesAsync {
  final values = <String, bool>{};

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          PurchaseAccess.channel,
          (_) async => {'unlimited': false, 'ready': false, 'busy': false},
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PurchaseAccess.channel, null);
  });
  testWidgets(
    'tutorial returns from records to top before ticket and plan guidance',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('学習記録'));
      await tester.pumpAndSettle();
      final dynamic state = tester.state(find.byType(Practice));
      state.showStep(TutorialStep.guide);
      await tester.pumpAndSettle();
      await tester.tap(find.text('案内の次へ'));
      await tester.pumpAndSettle();
      expect(find.text('「トレーニング」を押して、トップ画面に戻りましょう。'), findsOneWidget);
      await tester.tap(find.text('トレーニング'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('チケットと有料プラン'), findsOneWidget);
      expect(find.textContaining('右の「＋」'), findsOneWidget);
      await tester.tap(find.text('案内の次へ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('買い切りの有料プラン'), findsOneWidget);
      await tester.tap(find.text('案内の次へ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('最後にベルを押しましょう'), findsOneWidget);
      await tester.tap(find.text('案内を終了'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets('information dialog owns analytics settings and policy links', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const links = MethodChannel('plugins.flutter.io/url_launcher');
    final opened = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(links, (
      call,
    ) async {
      final arguments = call.arguments as Map;
      opened.add(arguments['url'] as String);
      expect(arguments['useWebView'], false);
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        links,
        null,
      ),
    );
    SharedPreferences.setMockInitialValues({'tutorial.walkthroughSeen': true});
    final prefs = await SharedPreferences.getInstance();
    final choices = <bool>[];
    final analytics = StudyAnalytics(
      preferences: _AnalyticsPreferences(),
      logEvent: (_, _) async {},
      setCollectionEnabled: (enabled) async => choices.add(enabled),
    );
    await tester.pumpWidget(
      MaterialApp(home: Practice(prefs, analytics: analytics)),
    );
    await tester.pumpAndSettle();
    expect(find.text('学習状況の計測に協力する'), findsNothing);
    expect(
      tester.getCenter(find.byTooltip('アプリについて')).dx,
      greaterThan(tester.getCenter(find.text('使い方')).dx),
    );
    await tester.tap(find.byTooltip('アプリについて'));
    await tester.pumpAndSettle();
    expect(find.text('プライバシーポリシー'), findsOneWidget);
    expect(find.text('利用規約'), findsOneWidget);
    await tester.ensureVisible(find.text('プライバシーポリシー'));
    await tester.tap(find.text('プライバシーポリシー'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('利用規約'));
    await tester.tap(find.text('利用規約'));
    await tester.pumpAndSettle();
    expect(opened, [
      'https://dokoshado.wisemap.biz/privacy-policy/',
      'https://dokoshado.wisemap.biz/terms/',
    ]);
    expect(
      find.text('アプリの改善のため、学習した日や練習量に関するデータを送信します。いつでもオフにできます'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(choices, [true]);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      true,
    );
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('アプリについて'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      true,
    );
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(choices, [true, false]);
  });

  testWidgets('available Play update is offered on top and can be deferred', (
    tester,
  ) async {
    const channel = MethodChannel('biz.wisemap.dokoshado/app_update');
    const links = MethodChannel('plugins.flutter.io/url_launcher');
    final opened = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(links, (
      call,
    ) async {
      final url = (call.arguments as Map)['url'] as String;
      opened.add(url);
      return url.startsWith('https:');
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        links,
        null,
      ),
    );
    var checks = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      expect(call.method, 'isUpdateAvailable');
      checks++;
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    SharedPreferences.setMockInitialValues({'tutorial.walkthroughSeen': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
    await tester.pumpAndSettle();
    expect(find.text('新しいバージョンがあります'), findsOneWidget);
    expect(find.text('アプリの更新'), findsOneWidget);
    await tester.tap(find.text('アプリの更新'));
    await tester.pumpAndSettle();
    expect(opened, [
      'market://details?id=biz.wisemap.dokoshado',
      'https://play.google.com/store/apps/details?id=biz.wisemap.dokoshado',
    ]);
    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();
    expect(find.text('新しいバージョンがあります'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('新しいバージョンがあります'), findsNothing);
    expect(checks, 1);
  });

  StudyEvent attempt(DateTime when, TicketKind ticket, {bool review = false}) =>
      (
        when: when,
        seconds: 30,
        difficultReview: review,
        rating: PracticeRating.okay,
        ticket: ticket,
      );

  test('daily tickets reset at midnight and quest and ad bonuses persist', () {
    final monday = DateTime(2026, 11, 9);
    final friday = DateTime(2026, 11, 13, 12);
    final practice = [
      for (var day = 9; day <= 13; day++)
        attempt(DateTime(2026, 11, day, 8), TicketKind.daily),
      attempt(DateTime(2026, 11, 13, 9), TicketKind.daily, review: true),
      attempt(DateTime(2026, 11, 13, 10), TicketKind.daily),
      attempt(DateTime(2026, 11, 13, 11), TicketKind.bonus),
    ];
    TicketBalance balance(DateTime now) => ticketBalance(
      practice: practice,
      challenges: [attempt(DateTime(2026, 11, 13, 11, 30), TicketKind.bonus)],
      activated: monday,
      now: now,
      adRewards: 1,
    );
    expect(balance(friday), (daily: 0, bonus: 2));
    expect(balance(DateTime(2026, 11, 14)), (daily: 3, bonus: 2));
    expect(nextTicket(balance(friday)), TicketKind.bonus);
    expect(nextTicket(balance(DateTime(2026, 11, 14))), TicketKind.daily);
    expect(
      studyEvents(['0', '0', encodeStudyEvent(practice.first)]).single,
      practice.first,
    );
  });

  testWidgets(
    'an empty ticket balance offers optional ads and plan information',
    (tester) async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        'tickets.challengeEvents': List.filled(
          3,
          encodeStudyEvent(attempt(now, TicketKind.daily)),
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      final daily = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('0/3'),
      );
      final bonus = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('+0'),
      );
      expect(daily, findsOneWidget);
      expect(bonus, findsOneWidget);
      expect(tester.getCenter(daily).dx, lessThan(tester.getCenter(bonus).dx));
      expect(
        tester.getCenter(bonus).dx,
        lessThan(tester.getCenter(find.byTooltip('学習リマインダー')).dx),
      );
      await tester.ensureVisible(find.text('スキルツリーを見る'));
      await tester.tap(find.text('スキルツリーを見る'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('練習 1'));
      await tester.tap(find.text('練習 1'));
      await tester.pumpAndSettle();
      expect(find.text('チケットがありません'), findsOneWidget);
      expect(find.text('広告動画で1枚受け取る'), findsOneWidget);
      await tester.tap(find.text('有料プランを見る'));
      await tester.pumpAndSettle();
      expect(find.text('チケットと有料プラン'), findsOneWidget);
      expect(find.textContaining('チケット無制限・広告非表示'), findsOneWidget);
      expect(find.text('購入を復元'), findsOneWidget);
    },
  );
  test(
    'daily training requires the other three goals, independent of claims',
    () {
      final today = DateTime(2026, 11, 10);
      final normal = (
        when: today,
        seconds: 30,
        difficultReview: false,
        rating: PracticeRating.great,
        ticket: null,
      );
      final review = (
        when: today,
        seconds: 30,
        difficultReview: true,
        rating: PracticeRating.okay,
        ticket: null,
      );
      final before = questsFor([normal, normal], {}, today);
      expect(before.singleWhere((q) => q.title == '耳と声の練習').goal, 2);
      expect(before.singleWhere((q) => q.title == 'シャドーイングの特訓').value, 2);
      final after = questsFor([normal, review], {}, today);
      final training = after.singleWhere((q) => q.title == 'シャドーイングの特訓');
      expect(training.value, training.goal);
      expect(training.claimed, isFalse);
      expect(
        questsFor(
          [normal, review],
          {training.key},
          today,
        ).singleWhere((q) => q.key == training.key).claimed,
        isTrue,
      );
    },
  );

  for (final rewardAvailable in [true, false]) {
    testWidgets(
      'quest guidance returns to top after reward available=$rewardAvailable',
      (tester) async {
        final now = DateTime.now();
        final quests = questsFor(
          [
            if (rewardAvailable)
              (
                when: now,
                seconds: 1,
                difficultReview: false,
                rating: null,
                ticket: null,
              ),
          ],
          {},
          now,
        );
        var claims = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => QuestPage(
                        quests: quests,
                        claim: (_) async {
                          claims++;
                          return true;
                        },
                        showTutorial: true,
                      ),
                    ),
                  ),
                  child: const Text('開く'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('開く'));
        await tester.pumpAndSettle();
        if (rewardAvailable) {
          expect(find.textContaining('「報酬を受け取る」を押しましょう'), findsOneWidget);
          await tester.tap(find.text('報酬を受け取る'));
          await tester.pumpAndSettle();
          expect(claims, 1);
          expect(find.textContaining('経験値を受け取りました'), findsOneWidget);
        } else {
          expect(find.textContaining('今は受け取れる報酬がない'), findsOneWidget);
          expect(find.text('報酬を受け取る'), findsNothing);
        }
        expect(find.textContaining('左上の矢印'), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('開く'), findsOneWidget);
      },
    );
  }
  test('all 17 categories contain five lessons and a challenge per level', () {
    final entries = [...clips, ...challengeClips, ...expandedClips];
    expect(entries.length, 510);
    expect(entries.map((q) => q.file).toSet(), hasLength(510));
    expect(entries.map((q) => q.english).toSet(), hasLength(510));
    for (final category in interestCategories) {
      for (var level = 1; level <= 5; level++) {
        final stage = entries.where(
          (q) => q.category == category.id && q.level == level,
        );
        expect(stage.where((q) => q.format == 'dialogue'), hasLength(3));
        expect(stage.where((q) => q.format == 'narration'), hasLength(2));
        expect(stage.where((q) => q.format == 'challenge'), hasLength(1));
        expect(stage.every((q) => q.notes.isNotEmpty && q.seconds > 2), isTrue);
      }
    }
  });
  test(
    'review opens at local midnight three calendar days after completion',
    () {
      expect(
        reviewAvailableOn(DateTime(2026, 12, 30, 23, 59)),
        DateTime(2027, 1, 2),
      );
    },
  );
  test('travel offers five clips per level with a 3:2 mix and four voices', () {
    expect(clips.length, 25);
    expect(clips.map((clip) => clip.voice).toSet().length, 4);
    for (var level = 1; level <= 5; level++) {
      final entries = clips.where((clip) => clip.level == level);
      expect(entries.length, 5);
      expect(entries.where((clip) => clip.format == 'dialogue').length, 3);
      expect(entries.where((clip) => clip.format == 'narration').length, 2);
      for (final clip in entries) {
        expect(clip.notes, hasLength(2));
      }
    }
  });
  test('whole-app titles unlock at EXP thresholds', () {
    expect(Growth(10).level, 1);
    expect(Growth(10).nextTitleLevel, 5);
    expect(Growth(139).title, '音の旅人');
    expect(Growth(140).title, '聞き取りの見習い');
    expect(Growth(200).level, 6);
    expect(Growth(200).title, Growth(140).title);
    expect(Growth(200).nextTitleLevel, 10);
    expect(Growth(5839).level, 99);
    expect(Growth(5840).level, 100);
    expect(Growth(5840).title, '伝説の聞き手');
    expect(Growth(7000).nextTitleLevel, isNull);
    for (final category in interestCategories) {
      expect(Growth(0, category: category.id).titles.toSet(), hasLength(5));
    }
  });

  testWidgets(
    'the first launch shows only the purpose and remembers dismissal',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.pumpAndSettle();

      expect(find.text('聞き取れる英語を、少しずつ増やす'), findsOneWidget);
      expect(find.text('STEP 1 / 1'), findsOneWidget);
      expect(find.text('次へ'), findsNothing);
      await tester.tap(find.text('あとで'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('tutorial.walkthroughSeen'), isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.pumpAndSettle();
      expect(find.text('聞き取れる英語を、少しずつ増やす'), findsNothing);
    },
  );

  testWidgets('guided practice uses the real category and practice controls', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('実際の画面で試す'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('スキルツリーを見る'));
    await tester.pumpAndSettle();
    final travel = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('旅行/観光'),
    );
    await tester.scrollUntilVisible(
      travel,
      180,
      scrollable: find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(travel);
    await tester.tap(travel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('home.categories'), ['travel']);
    await tester.tap(find.text('案内の次へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('練習 1'));
    await tester.pumpAndSettle();
    expect(find.text('英文は非表示です'), findsOneWidget);
    expect(find.text('再生'), findsOneWidget);
    expect(find.text('今の聞き取りを確かめる'), findsOneWidget);
    expect(find.textContaining('今の自分がどこまで聞き取れるか'), findsOneWidget);
  });

  testWidgets(
    'guided practice offers an unlocked level when practice 1 is resting',
    (tester) async {
      final stamp = DateTime.now().millisecondsSinceEpoch.toString();
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        'home.categories': ['travel'],
        'practice.travel-01': [stamp, '1'],
        'passed.travel.1': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.tap(find.text('使い方'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('実際の画面で試す'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('カテゴリーを選ぶ'));
      await tester.pumpAndSettle();
      final travel = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('旅行/観光'),
      );
      await tester.scrollUntilVisible(
        travel,
        180,
        scrollable: find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(travel);
      await tester.tap(travel);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('案内の次へ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lv.1の練習1は復習待ち'), findsOneWidget);
      await tester.tap(find.text('Lv.2 街角の聞き手'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('練習 1'));
      await tester.pumpAndSettle();
      final header = find.byType(AppBar);
      expect(
        find.descendant(of: header, matching: find.text('旅行/観光')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.text('Lv.2 街角の聞き手')),
        findsOneWidget,
      );
      final bar = tester.widget<AppBar>(header);
      expect(
        bar.backgroundColor,
        Theme.of(tester.element(header)).colorScheme.primary,
      );
    },
  );

  testWidgets(
    'the skill tree counts ratings without inventing legacy ratings',
    (tester) async {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final history = <String>[
        '$stamp',
        '5',
        '$stamp|10|0',
        '$stamp|12|0|great',
        '$stamp|14|0|okay',
        '$stamp|16|0|hard',
        '$stamp|18|1|great',
      ];
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        'practice.travel-01': history,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.ensureVisible(find.text('スキルツリーを見る'));
      await tester.tap(find.text('スキルツリーを見る'));
      await tester.pumpAndSettle();
      expect(find.text('ばっちり 2回  ・  まあまあ 1回  ・  難しかった 1回'), findsOneWidget);
      expect(find.text('完了・復習待ち'), findsOneWidget);
      final events = studyEvents(history);
      expect(events.first.rating, isNull);
      expect(events.last.rating, PracticeRating.great);
      expect(events.last.difficultReview, isTrue);
      expect(events.map(encodeStudyEvent), history.skip(2));
    },
  );

  testWidgets('completions count towards both growth records', (tester) async {
    SharedPreferences.setMockInitialValues({
      'tutorial.walkthroughSeen': true,
      'practice.travel-01': [
        DateTime.now().millisecondsSinceEpoch.toString(),
        '1',
      ],
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
    expect(find.text('累計 10 EXP'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('旅行/観光'), 250);
    expect(find.text('旅行/観光'), findsOneWidget);
  });

  testWidgets('skill tree switches categories and shows the available steps', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'tutorial.walkthroughSeen': true,
      'practice.travel-01': [
        DateTime.now().millisecondsSinceEpoch.toString(),
        '1',
      ],
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
    expect(find.text('おすすめ学習'), findsNothing);
    expect(find.text('今日の進捗'), findsNothing);
    await tester.ensureVisible(find.text('スキルツリーを見る'));
    await tester.tap(find.text('スキルツリーを見る'));
    await tester.pumpAndSettle();
    expect(find.text('練習 1'), findsOneWidget);
    expect(find.text('完了・復習待ち'), findsOneWidget);
    await tester.tap(find.text('Lv.5 ？？？'));
    await tester.pumpAndSettle();
    expect(find.text('Lv.5 ？？？ の練習'), findsOneWidget);
    expect(find.text('前のレベルの挑戦に合格すると解放されます。'), findsOneWidget);
    expect(find.text('完了・復習待ち'), findsNothing);
    await tester.tap(find.text('旅行/観光'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('美容/コスメ'));
    await tester.pumpAndSettle();
    expect(find.text('通常問題  0 / 5 問完了'), findsOneWidget);
  });
  testWidgets(
    'five completed problems open the challenge and playback waits for a tap',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        for (var i = 1; i <= 5; i++) 'practice.travel-0$i': ['1', '1'],
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.ensureVisible(find.text('スキルツリーを見る'));
      await tester.tap(find.text('スキルツリーを見る'));
      await tester.pumpAndSettle();
      expect(find.text('通常問題  5 / 5 問完了'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('挑戦問題'), 280);
      await tester.tap(find.text('挑戦問題'));
      await tester.pumpAndSettle();
      expect(find.text('再生'), findsOneWidget);
      expect(find.text('まずは聞いてみよう'), findsOneWidget);
      expect(find.text('日本語確認へ'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('日本語確認へ'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'a recorded challenge pass opens the next level and awards its title',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        'passed.travel.1': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.ensureVisible(find.text('スキルツリーを見る'));
      await tester.tap(find.text('スキルツリーを見る'));
      await tester.pumpAndSettle();
      expect(find.text('Lv.2 街角の聞き手 の練習'), findsOneWidget);
      expect(find.text('Lv.2 街角の聞き手'), findsOneWidget);
    },
  );
  testWidgets(
    'learning record and daily quest reward preserve the saved completion',
    (tester) async {
      final stamp = DateTime.now().millisecondsSinceEpoch.toString();
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        'practice.travel-01': [stamp, '1', '$stamp|63|0'],
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.tap(find.text('学習記録'));
      await tester.pumpAndSettle();
      expect(find.text('学習の推移'), findsOneWidget);
      expect(find.text('日別'), findsOneWidget);
      expect(find.text('月別'), findsOneWidget);
      expect(find.textContaining('1分 3秒'), findsWidgets);
      await tester.tap(find.text('トレーニング'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('クエスト（報酬 1件）'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('報酬を受け取る'));
      await tester.pumpAndSettle();
      expect(find.text('受け取り済み'), findsOneWidget);
      expect(prefs.getStringList('quest.claims'), hasLength(1));
      expect(prefs.getStringList('practice.travel-01'), [
        stamp,
        '1',
        '$stamp|63|0',
      ]);
    },
  );
  testWidgets('training claim saves EXP and ticket together exactly once', (
    tester,
  ) async {
    final now = DateTime.now();
    final first = now
        .subtract(const Duration(minutes: 2))
        .millisecondsSinceEpoch;
    final second = now
        .subtract(const Duration(minutes: 1))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'tutorial.walkthroughSeen': true,
      'tickets.activatedAt': now
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch,
      'tickets.claimRewardsFrom': now
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch,
      'practice.travel-01': [
        '$second',
        '2',
        '$first|30|0|okay',
        '$second|30|1|great',
      ],
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
    final dynamic state = tester.state(find.byType(Practice));
    expect(state.availableTickets(now).bonus, 0);
    await tester.tap(find.text('クエスト（報酬 4件）'));
    await tester.pumpAndSettle();
    final card = find.ancestor(
      of: find.text('シャドーイングの特訓'),
      matching: find.byType(Card),
    );
    final button = find.descendant(of: card, matching: find.text('報酬を受け取る'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(state.availableTickets(DateTime.now()).bonus, 1);
    expect(prefs.getStringList('quest.claims'), hasLength(1));
    expect(state.claims.single.key, endsWith('|ten'));
    expect(
      find.descendant(of: card, matching: find.text('受け取り済み')),
      findsOneWidget,
    );
    expect(
      await state.claimQuest(
        state.quests.singleWhere((dynamic q) => (q.key as String).endsWith('|ten')),
      ),
      isFalse,
    );
    expect(state.availableTickets(DateTime.now()).bonus, 1);
  });
  testWidgets(
    'guide shows the purpose and six screenshot pages with navigation',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.tap(find.text('使い方'));
      await tester.pumpAndSettle();
      const titles = [
        '聞き取れる英語を、少しずつ増やす',
        'カテゴリーの選択',
        'レベル・問題・復習・挑戦',
        '初回リスニング',
        '英文と日本語のすり合わせ',
        '音読',
        'シャドーイング',
      ];
      const highlights = {
        2: '復習は、完了日から3日後',
        3: '今の聞き取りを確かめる',
        5: '意味を追いながら、前へ読む',
        6: '話し方ごと、まねする',
      };
      for (var i = 0; i < titles.length; i++) {
        expect(find.text(titles[i]), findsOneWidget);
        if (highlights[i] case final title?) {
          expect(find.text(title), findsOneWidget);
        }
        expect(find.text('STEP ${i + 1} / 7'), findsOneWidget);
        if (i == titles.length - 1) break;
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('前へ'));
      await tester.pumpAndSettle();
      expect(find.text('音読'), findsOneWidget);
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(find.text('スキルツリーを見る'), findsOneWidget);
    },
  );
}

