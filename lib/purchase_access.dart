import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tickets.dart';

class PurchaseAccess extends ChangeNotifier {
  static const channel = MethodChannel('biz.wisemap.dokoshado/purchases');
  static const _preview = bool.fromEnvironment('DOKOSHADO_PREVIEW');

  bool unlimited = false;
  bool initialized = false;
  bool ready = false;
  bool busy = false;
  bool pending = false;
  String? price;
  String? message;
  bool _disposed = false;
  String get storeName =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'App Store' : 'Google Play';

  Future<void> connect() async {
    if (_preview) {
      await refresh();
      return;
    }
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      initialized = true;
      notifyListeners();
      return;
    }
    channel.setMethodCallHandler((call) async {
      if (call.method == 'changed' && !_disposed) _apply(call.arguments);
    });
    await refresh();
  }

  void _apply(dynamic value) {
    if (_disposed || value is! Map) return;
    unlimited = value['unlimited'] == true;
    ready = value['ready'] == true;
    busy = value['busy'] == true;
    pending = value['pending'] == true;
    price = value['price'] as String?;
    message = value['message'] as String?;
    // Wait for the first ownership check before requesting any ads.
    initialized = initialized || !busy;
    notifyListeners();
  }

  Future<void> refresh() => _invoke('refresh');
  Future<void> buy() => _invoke('buy');
  Future<void> restore() => _invoke(
    defaultTargetPlatform == TargetPlatform.iOS ? 'restore' : 'refresh',
  );

  Future<void> _invoke(String method) async {
    if (_preview && !_disposed) {
      _apply({
        'unlimited': false,
        'ready': false,
        'busy': false,
        'price': '￥980',
        'message': 'この確認版では購入できません。購入・復元は通常のどこシャドでご利用ください。',
      });
      return;
    }
    if (_disposed || busy) return;
    busy = true;
    notifyListeners();
    try {
      final result = await channel.invokeMethod<Map<dynamic, dynamic>>(method);
      if (result is! Map) throw const FormatException('Invalid purchase state');
      _apply(result);
    } catch (_) {
      if (!_disposed) {
        busy = false;
        initialized = true;
        message = '$storeNameで購入情報を確認できませんでした。時間をおいて再度お試しください。';
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    channel.setMethodCallHandler(null);
    super.dispose();
  }
}

class PurchasePlanDialog extends StatelessWidget {
  const PurchasePlanDialog({super.key, required this.access, this.balance});

  final PurchaseAccess access;
  final TicketBalance? balance;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: access,
    builder: (context, _) => AlertDialog(
      scrollable: true,
      title: const Text('チケットと有料プラン'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (balance case final remaining?) ...[
            Text(
              access.unlimited
                  ? '現在、チケット無制限でご利用いただけます。'
                  : '今日のチケット ${remaining.daily}/3枚・追加チケット ${remaining.bonus}枚',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 20),
            const Text(
              '無料プランでは、1問につきチケットを1枚使います。復習も対象です。毎日午前0時にデイリーチケットが3枚に回復します。',
            ),
            const SizedBox(height: 12),
            const Text('追加チケットは、対象クエストの報酬や、チケットがなくなったときの動画広告で受け取れます。'),
            const SizedBox(height: 20),
          ],
          const Text('買い切りで、チケット無制限・広告非表示で練習できます。'),
          const SizedBox(height: 12),
          Text(
            access.unlimited
                ? '無制限プランをご利用中です。'
                : access.price == null
                ? '価格は${access.storeName}で確認できます。'
                : '${access.price}（買い切り）',
          ),
          if (access.busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (access.pending) ...[
            const SizedBox(height: 12),
            const Text('お支払いの確認後に、無制限プランが有効になります。'),
          ],
          if (access.message case final message?) ...[
            const SizedBox(height: 12),
            Text(message),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
        TextButton(
          onPressed: access.busy ? null : access.restore,
          child: const Text('購入を復元'),
        ),
        if (!access.unlimited)
          FilledButton(
            onPressed:
                access.ready &&
                    !access.busy &&
                    !access.pending &&
                    access.price != null
                ? access.buy
                : null,
            child: Text('${access.price ?? access.storeName}で購入する'),
          ),
      ],
    ),
  );
}
