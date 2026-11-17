import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'study_analytics.dart';

Future<bool> openExternalLink(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

class AppInformationDialog extends StatefulWidget {
  const AppInformationDialog({super.key, this.analytics, this.onPlan});

  final StudyAnalytics? analytics;
  final VoidCallback? onPlan;

  @override
  State<AppInformationDialog> createState() => _AppInformationDialogState();
}

class _AppInformationDialogState extends State<AppInformationDialog> {
  bool saving = false;
  String? error;

  Future<void> changeAnalytics(bool enabled) async {
    final analytics = widget.analytics;
    if (analytics == null || saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await analytics.changeEnabled(enabled);
    } catch (_) {
      if (mounted) setState(() => error = '計測設定を保存できませんでした。もう一度お試しください。');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> openPolicy(String path) async {
    final opened = await openExternalLink(
      Uri.https('dokoshado.wisemap.biz', path),
    );
    if (!opened && mounted) {
      setState(() => error = 'ページを開けませんでした。もう一度お試しください。');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('どこシャド'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('聞いて、声に出して、聞き慣れた英語を少しずつ増やすシャドーイングアプリです。'),
        const SizedBox(height: 16),
        const Text('学習記録はこの端末に保存されます。アプリの削除や機種変更で失われることがあります。'),
        const SizedBox(height: 16),
        if (widget.onPlan != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('無制限プラン（買い切り）'),
            subtitle: const Text('チケット無制限・広告非表示'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onPlan,
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('プライバシーポリシー'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => openPolicy('/privacy-policy/'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('利用規約'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => openPolicy('/terms/'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('学習状況の計測に協力する'),
          subtitle: const Text('アプリの改善のため、学習した日や練習量に関するデータを送信します。いつでもオフにできます'),
          value: widget.analytics?.enabled ?? false,
          onChanged: saving || widget.analytics == null
              ? null
              : changeAnalytics,
        ),
        if (error case final message?)
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('閉じる'),
      ),
    ],
  );
}
