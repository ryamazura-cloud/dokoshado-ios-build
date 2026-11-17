import 'package:dokoshado/purchase_access.dart';
import 'package:dokoshado/ticket_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS ads select the supplied units and Android units stay unchanged',
    () {
      expect(
        TicketAdPlacement.home.adUnitFor(TargetPlatform.iOS),
        'ca-app-pub-2142000020431433/3943219550',
      );
      expect(
        TicketAdPlacement.history.adUnitFor(TargetPlatform.iOS),
        'ca-app-pub-2142000020431433/5310086209',
      );
      expect(
        TicketAdPlacement.completion.adUnitFor(TargetPlatform.iOS),
        'ca-app-pub-2142000020431433/4380322923',
      );
      expect(
        rewardedTicketUnitFor(TargetPlatform.iOS),
        'ca-app-pub-2142000020431433/5122558959',
      );
      expect(
        TicketAdPlacement.home.adUnitFor(TargetPlatform.android),
        'ca-app-pub-2142000020431433/1593242017',
      );
      expect(
        rewardedTicketUnitFor(TargetPlatform.android),
        'ca-app-pub-2142000020431433/1723949004',
      );
      expect(
        TicketAdPlacement.home.adUnitFor(TargetPlatform.iOS, test: true),
        'ca-app-pub-3940256099942544/2934735716',
      );
      expect(
        rewardedTicketUnitFor(TargetPlatform.iOS, test: true),
        'ca-app-pub-3940256099942544/1712485313',
      );
    },
  );

  testWidgets(
    'iOS buyout uses StoreKit channel, store price and explicit restore',
    (tester) async {
      final calls = <String>[];
      var owned = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PurchaseAccess.channel,
        (call) async {
          calls.add(call.method);
          if (call.method == 'restore') owned = true;
          return {
            'unlimited': owned,
            'ready': true,
            'busy': false,
            'price': '￥900',
          };
        },
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
      expect(access.storeName, 'App Store');
      await tester.pumpWidget(
        MaterialApp(home: PurchasePlanDialog(access: access)),
      );
      expect(find.text('￥900（買い切り）'), findsOneWidget);
      await tester.tap(find.text('￥900で購入する'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('購入を復元'));
      await tester.pumpAndSettle();
      expect(calls, ['refresh', 'buy', 'restore']);
      expect(access.unlimited, true);
      expect(find.text('無制限プランをご利用中です。'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('iOS store errors mention App Store', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PurchaseAccess.channel,
      (_) async => throw PlatformException(code: 'offline'),
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
    expect(access.message, startsWith('App Store'));
    expect(access.unlimited, false);
    expect(access.initialized, true);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
