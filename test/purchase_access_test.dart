import 'package:dokoshado/main.dart';
import 'package:dokoshado/dashboard.dart';
import 'package:dokoshado/purchase_access.dart';
import 'package:dokoshado/ticket_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('initial ownership lookup finishes before ads may be shown', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PurchaseAccess.channel,
      (_) async => {'unlimited': false, 'busy': true},
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PurchaseAccess.channel,
        null,
      ),
    );
    final access = PurchaseAccess();
    addTearDown(access.dispose);
    await access.connect();
    expect(access.initialized, false);
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      PurchaseAccess.channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('changed', {'unlimited': true, 'busy': false}),
      ),
      (_) {},
    );
    expect(access.initialized, true);
    expect(access.unlimited, true);
  });

  testWidgets('buyout price, pending payment, entitlement and refund refresh', (
    tester,
  ) async {
    final channel = PurchaseAccess.channel;
    var owned = false;
    var pending = false;
    final methods = <String>[];
    Map<String, Object?> state() => {
      'unlimited': owned,
      'ready': true,
      'busy': false,
      'pending': pending,
      'price': '￥980',
    };
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      methods.add(call.method);
      if (call.method == 'buy') pending = true;
      return state();
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final access = PurchaseAccess();
    addTearDown(access.dispose);
    await access.connect();
    await tester.pumpWidget(
      MaterialApp(home: PurchasePlanDialog(access: access)),
    );
    expect(find.text('￥980（買い切り）'), findsOneWidget);
    await tester.tap(find.text('￥980で購入する'));
    await tester.pumpAndSettle();
    expect(access.unlimited, false);
    expect(find.textContaining('お支払いの確認後'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    owned = true;
    pending = false;
    await access.refresh();
    await tester.pumpAndSettle();
    expect(find.text('無制限プランをご利用中です。'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    owned = false;
    await access.refresh();
    await tester.pumpAndSettle();
    expect(find.text('￥980で購入する'), findsOneWidget);
    expect(methods, ['refresh', 'buy', 'refresh', 'refresh']);
  });

  testWidgets('paid ownership bypasses an empty balance and hides banners', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PurchaseAccess.channel,
      (_) async => {
        'unlimited': true,
        'ready': true,
        'busy': false,
        'price': '￥980',
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PurchaseAccess.channel,
        null,
      ),
    );
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'tutorial.walkthroughSeen': true,
      'tickets.challengeEvents': List.filled(
        3,
        encodeStudyEvent((
          when: now,
          seconds: 0,
          difficultReview: false,
          rating: null,
          ticket: TicketKind.daily,
        )),
      ),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
    await tester.pumpAndSettle();
    expect(find.byTooltip('無制限プランをご利用中'), findsOneWidget);
    expect(find.byType(TicketBanner), findsNothing);
    await tester.tap(find.byTooltip('無制限プランをご利用中'));
    await tester.pumpAndSettle();
    expect(find.text('チケットと有料プラン'), findsOneWidget);
    expect(find.text('無制限プランをご利用中です。'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('スキルツリーを見る'));
    await tester.tap(find.text('スキルツリーを見る'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('練習 1'));
    await tester.tap(find.text('練習 1'));
    await tester.pumpAndSettle();
    expect(find.text('チケットがありません'), findsNothing);
    expect(find.text('日本語確認へ'), findsOneWidget);
    expect(prefs.getStringList('tickets.challengeEvents'), hasLength(3));
  });

  testWidgets('ticket header opens balance, daily rules and buyout options', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PurchaseAccess.channel,
      (_) async => {
        'unlimited': false,
        'ready': true,
        'busy': false,
        'price': '￥980',
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PurchaseAccess.channel,
        null,
      ),
    );
    SharedPreferences.setMockInitialValues({'tutorial.walkthroughSeen': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('チケットと有料プラン'));
    await tester.pumpAndSettle();
    expect(find.text('今日のチケット 3/3枚・追加チケット 0枚'), findsOneWidget);
    expect(find.textContaining('復習も対象です。'), findsOneWidget);
    expect(find.textContaining('毎日午前0時'), findsOneWidget);
    expect(find.text('￥980（買い切り）'), findsOneWidget);
    await tester.ensureVisible(find.text('購入を復元'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(
      prefs.getKeys().where((key) => key.startsWith('practice.')),
      isEmpty,
    );
  });
}
