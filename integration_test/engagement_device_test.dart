import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dokoshado/main.dart' show Practice;
import 'package:dokoshado/daily_study_share.dart';
import 'package:dokoshado/dashboard.dart';
import 'package:dokoshado/activity.dart';
import 'package:dokoshado/learning_dashboard.dart';
import 'package:dokoshado/purchase_access.dart';

class _DevicePurchase extends PurchaseAccess {
  @override
  Future<void> connect() async {}
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'device UI, share PNG, native share sheet and completion ticket',
    (tester) async {
      final root = GlobalKey();
      final images = <String, String>{};
      binding.reportData = {'images': images};
      Widget app(Widget home) => RepaintBoundary(
        key: root,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xff215caa),
            useMaterial3: true,
          ),
          home: home,
        ),
      );
      Future<void> capture(String name) async {
        await tester.pump();
        final boundary =
            root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.625);
        images[name] = base64Encode(
          (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
              .asUint8List(),
        );
        image.dispose();
      }

      final now = DateTime.now();
      final stamp = now.millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        'home.categories': ['travel', 'beauty'],
        'practice.travel-02': ['$stamp', '1', '$stamp|30|0|great'],
        'tickets.challengeEvents': ['$stamp|60|0||daily'],
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        app(Practice(prefs, purchases: _DevicePurchase())),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('カテゴリー変更'));
      await capture('01-category-button');
      await tester.tap(find.text('カテゴリー変更'));
      await tester.pumpAndSettle();
      expect(find.text('興味のある分野を選ぶ'), findsOneWidget);
      await capture('02-category-selection');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(Practice));
      state.treeOpen = true;
      state.start(0);
      state.round = 4;
      state.played = true;
      await state.advance();
      await tester.pumpAndSettle();
      expect(find.text('今日の練習：3問完了'), findsOneWidget);
      await tester.ensureVisible(find.text('今日のがんばりをシェア'));
      await capture('03-completion-share');
      await tester.tap(find.text('今日のがんばりをシェア'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/characters/travel.webp'),
          tester.element(find.byType(DailyStudyShareCard)),
        ),
      );
      await tester.pumpAndSettle();
      await capture('04-share-preview');
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find
            .ancestor(
              of: find.byType(DailyStudyShareCard),
              matching: find.byType(RepaintBoundary),
            )
            .first,
      );
      final image = await boundary.toImage(pixelRatio: 3);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      binding.reportData!.addAll({
        'sharePng': base64Encode(png),
        'shareWidth': image.width,
        'shareHeight': image.height,
      });
      expect(image.width, 1080);
      expect(image.height, 1080);
      image.dispose();
      await tester.tap(find.text('共有先を選ぶ'));
      debugPrint('DOKOSHADO_NATIVE_SHARE_READY');
      await Future<void>.delayed(const Duration(seconds: 12));
      await tester.pumpAndSettle();
      expect(find.text('準備中…'), findsNothing);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(prefs.getStringList('practice.travel-01'), isNull);
      await tester.ensureVisible(find.text('ばっちり'));
      await tester.tap(find.text('ばっちり'));
      await tester.pumpAndSettle();
      expect(
        studyEvents(prefs.getStringList('practice.travel-01')!).single.ticket,
        TicketKind.daily,
      );
      expect(state.availableTickets(DateTime.now()).daily, 1);

      final events = <StudyEvent>[
        for (var i = 0; i < 2; i++)
          (
            when: now.subtract(Duration(days: i)),
            seconds: 60,
            difficultReview: false,
            rating: PracticeRating.great,
            ticket: null,
          ),
      ];
      await tester.pumpWidget(
        app(
          QuestPage(
            quests: questsFor(events, {}, now),
            events: events,
            commonXp: 20,
            now: now,
            claim: (_) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('小さな一歩が、次のレベルへ。'), findsOneWidget);
      await capture('05-quests');
      final reward = find.text('報酬を受け取る').first;
      await tester.ensureVisible(reward);
      await tester.tap(reward);
      await tester.pumpAndSettle();
      expect(find.text('受け取り済み'), findsWidgets);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: ActivityChart(
                points: chartPeriods(
                  {
                    dayKey(now): const DailyActivity(
                      questions: 3,
                      milliseconds: 90000,
                    ),
                  },
                  now,
                  monthly: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('${now.day}\n${weekdayLabel(now)}'), findsOneWidget);
      await capture('06-daily-chart');
    },
  );
}
