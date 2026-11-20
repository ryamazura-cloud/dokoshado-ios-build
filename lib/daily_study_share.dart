import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import 'activity.dart';
import 'dashboard.dart';
import 'skill_character.dart';

DailyActivity todayStudy(
  List<StudyEvent> events,
  DateTime now, {
  StudyEvent? pending,
}) {
  var total = const DailyActivity();
  for (final event in [...events, if (pending != null) pending]) {
    if (dayKey(event.when.toLocal()) == dayKey(now.toLocal()) &&
        !event.when.isAfter(now)) {
      total = total.plus(questions: 1, milliseconds: event.seconds * 1000);
    }
  }
  return total;
}

String dailyStudyShareText(DailyActivity total) =>
    '今日の英語トレーニング\n${total.questions}問・${studyDuration(total.milliseconds)}、練習しました！\n'
    '今日も、ひとつずつ積み重ね。\n\nどこシャドで練習しました。\nhttps://dokoshado.wisemap.biz/';

class DailyStudyShareCard extends StatelessWidget {
  const DailyStudyShareCard({
    super.key,
    required this.total,
    required this.date,
    required this.category,
    required this.level,
  });
  final DailyActivity total;
  final DateTime date;
  final String category;
  final int level;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xff435e90);
    Widget metric(IconData icon, String label, String value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffdce6fa),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: blue),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerRight,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return MediaQuery.withNoTextScaling(
      child: Container(
        width: 360,
        height: 360,
        padding: const EdgeInsets.all(18),
        color: const Color(0xfff8f9ff),
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xff172c49), fontSize: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '今日の英語トレーニング',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              Text(
                dayKey(date),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: blue),
              ),
              const SizedBox(height: 12),
              metric(
                Icons.check_circle_outline,
                '学習問題数',
                '${total.questions}問',
              ),
              const SizedBox(height: 8),
              metric(Icons.schedule, '学習時間', studyDuration(total.milliseconds)),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '今日も、ひとつずつ積み重ね。',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: SkillCharacter(
                        category: category,
                        level: level,
                        title: '',
                        unlocked: true,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 14),
              const Text(
                'どこシャドで練習しました',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: blue),
              ),
              const Text(
                'https://dokoshado.wisemap.biz/',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showDailyStudyShare(
  BuildContext context, {
  required DailyActivity total,
  required DateTime date,
  required String category,
  required int level,
}) async {
  final capture = GlobalKey();
  var sharing = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, refresh) => AlertDialog(
        title: const Text('今日のがんばりをシェア'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 360,
                child: FittedBox(
                  child: RepaintBoundary(
                    key: capture,
                    child: MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.noScaling),
                      child: DailyStudyShareCard(
                        total: total,
                        date: date,
                        category: category,
                        level: level,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                dailyStudyShareText(total),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: sharing ? null : () => Navigator.pop(dialogContext),
            child: const Text('閉じる'),
          ),
          Builder(
            builder: (buttonContext) => FilledButton.icon(
              onPressed: sharing
                  ? null
                  : () async {
                      final box = buttonContext.findRenderObject()! as RenderBox;
                      final shareOrigin = box.localToGlobal(Offset.zero) & box.size;
                      refresh(() => sharing = true);
                      ui.Image? image;
                      try {
                        await precacheImage(
                          AssetImage('assets/characters/$category.webp'),
                          context,
                        );
                        if (!dialogContext.mounted) return;
                        await WidgetsBinding.instance.endOfFrame;
                        final boundary =
                            capture.currentContext!.findRenderObject()!
                                as RenderRepaintBoundary;
                        image = await boundary.toImage(pixelRatio: 3);
                        final bytes = (await image.toByteData(
                          format: ui.ImageByteFormat.png,
                        ))!.buffer.asUint8List();
                        await SharePlus.instance.share(
                          ShareParams(
                            text: dailyStudyShareText(total),
                            title: '今日の英語トレーニング',
                            files: [
                              XFile.fromData(bytes, mimeType: 'image/png'),
                            ],
                            fileNameOverrides: [
                              'dokoshado-${dayKey(date)}.png',
                            ],
                            sharePositionOrigin: shareOrigin,
                          ),
                        );
                      } catch (_) {
                        if (dialogContext.mounted)
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('共有画像を作成できませんでした。もう一度お試しください。'),
                            ),
                          );
                      } finally {
                        image?.dispose();
                        if (dialogContext.mounted)
                          refresh(() => sharing = false);
                      }
                    },
              icon: const Icon(Icons.ios_share),
              label: Text(sharing ? '準備中…' : '共有先を選ぶ'),
            ),
          ),
        ],
      ),
    ),
  );
}
