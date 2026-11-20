import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'growth.dart';
import 'expanded.dart';
import 'activity.dart';
import 'achievements.dart';
import 'learning_dashboard.dart';
import 'dashboard.dart';
import 'usage_guide.dart';
import 'reminders.dart';
import 'reminder_notifications.dart';
import 'reminder_settings_page.dart';
import 'interests.dart';
import 'tickets.dart';
import 'ticket_ads.dart';
import 'study_analytics.dart';
import 'app_information.dart';
import 'skill_character.dart';
import 'purchase_access.dart';
import 'practice_finished.dart';
import 'karaoke_timings.dart';
import 'tutorial_layout.dart';
import 'daily_study_share.dart';
import 'review_prompt.dart';

import 'challenges.dart';
import 'scenes.dart';
import 'travel.dart' as travel;
import 'travel.dart' show Clip;

class _TutorialShade extends CustomPainter {
  const _TutorialShade(this.target);

  final Rect target;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(target, const Radius.circular(12)));
    canvas.drawPath(shade, Paint()..color = const Color(0x550f172a));
    canvas.drawRRect(
      RRect.fromRectAndRadius(target.deflate(1.5), const Radius.circular(10.5)),
      Paint()
        ..color = const Color(0xff2684e8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_TutorialShade oldDelegate) =>
      target != oldDelegate.target;
}

class _TutorialBubbleLayout extends SingleChildLayoutDelegate {
  const _TutorialBubbleLayout(this.target);

  final Rect? target;
  static const gap = 10.0;

  double spaceAbove(Size size) =>
      ((target?.top ?? size.height) - 2 * gap).clamp(0.0, size.height);

  double spaceBelow(Size size) =>
      (size.height - (target?.bottom ?? size.height) - 2 * gap).clamp(
        0.0,
        size.height,
      );

  bool placeBelow(Size size) =>
      spaceBelow(size) >= 150 || spaceBelow(size) >= spaceAbove(size);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final size = constraints.biggest;
    final room = placeBelow(size) ? spaceBelow(size) : spaceAbove(size);
    return BoxConstraints(
      maxWidth: (size.width - 2 * gap).clamp(0.0, 340.0),
      maxHeight: room.clamp(size.height * 0.24, size.height),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final anchor = target;
    final x = ((anchor?.center.dx ?? size.width / 2) - childSize.width / 2)
        .clamp(
          gap,
          (size.width - childSize.width - gap).clamp(gap, size.width),
        );
    final y = placeBelow(size)
        ? (anchor?.bottom ?? 0) + gap
        : (anchor?.top ?? size.height) - childSize.height - gap;
    return Offset(
      x,
      y.clamp(
        gap,
        (size.height - childSize.height - gap).clamp(gap, size.height),
      ),
    );
  }

  @override
  bool shouldRelayout(_TutorialBubbleLayout oldDelegate) =>
      target != oldDelegate.target;
}

enum TutorialStep {
  tree,
  categories,
  levels,
  alternativeLevel,
  alternativeCategory,
  question,
  listen,
  japanese,
  meaning,
  notes,
  readButton,
  read,
  shadowButton,
  shadowOne,
  shadowTwo,
  shadowThree,
  shadowFour,
  ratePractice,
  review,
  returnHome,
  growth,
  quest,
  history,
  graph,
  totals,
  badges,
  guide,
  returnTraining,
  tickets,
  ticketPlan,
  reminder,
}

const meaningStep = -1;
const readAloudStep = -2;
const isPreviewBuild = bool.fromEnvironment('DOKOSHADO_PREVIEW');

DateTime reviewAvailableOn(DateTime completed) {
  final local = completed.toLocal();
  return DateTime(local.year, local.month, local.day + 3);
}

const clips = [...travel.clips, ...challengeClips, ...expandedClips];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  if (!preferences.containsKey('tickets.activatedAt')) {
    await preferences.setInt(
      'tickets.activatedAt',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
  if (!preferences.containsKey('tickets.claimRewardsFrom')) {
    await preferences.setInt(
      'tickets.claimRewardsFrom',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
  final reminders = ReminderManager(
    store: LocalReminderStore(),
    backend: LocalReminderBackend(),
  );
  unawaited(reminders.restore().catchError((Object _) {}));
  var karaoke = const KaraokeCatalog.empty();
  try {
    karaoke = await KaraokeCatalog.load();
  } catch (_) {
    debugPrint('Word timing data could not be loaded.');
  }
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: isPreviewBuild ? 'どこシャド確認版' : 'どこシャド',
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xff215caa),
        useMaterial3: true,
      ),
      home: Practice(
        preferences,
        reminders: reminders,
        refreshAtMidnight: true,
        analytics: isPreviewBuild ? null : await StudyAnalytics.connect(),
        karaoke: karaoke,
      ),
    ),
  );
}

class Practice extends StatefulWidget {
  const Practice(
    this.preferences, {
    super.key,
    this.reminders,
    this.refreshAtMidnight = false,
    this.analytics,
    this.purchases,
    this.karaoke = const KaraokeCatalog.empty(),
  });

  final bool refreshAtMidnight;
  final StudyAnalytics? analytics;
  final PurchaseAccess? purchases;
  final KaraokeCatalog karaoke;

  final SharedPreferences preferences;
  final ReminderManager? reminders;

  @override
  State<Practice> createState() => _PracticeState();
}

class _PracticeState extends State<Practice> with WidgetsBindingObserver {
  late final plan = widget.purchases ?? PurchaseAccess();
  final player = AudioPlayer();
  final subscriptions = <StreamSubscription<dynamic>>[];
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  int? index;
  int round = 0;
  bool playing = false;
  bool played = false;
  bool complete = false;
  bool reveal = false;
  bool paused = false;
  bool busy = false;
  bool treeOpen = false;
  String category = 'travel';
  int practiceLevel = 1;
  bool foreground = true;
  bool get usesAudio => round >= 0;
  bool get canAdvance => !busy && !playing && (!usesAudio || played);
  String? error;
  double speed = 1;

  SharedPreferences get prefs => widget.preferences;
  ({StudyEvent event, List<String> history})? pendingCompletion;
  final studyClock = Stopwatch();
  bool sharedThisPractice = false;
  bool historyOpen = false;
  bool claimSaving = false;
  bool ticketPromptOpen = false;
  bool showUpdateNotice = false;
  bool updateDismissed = false;
  bool checkingForUpdate = false;
  Timer? midnightRefresh;
  late final ticketActivated = DateTime.fromMillisecondsSinceEpoch(
    prefs.getInt('tickets.activatedAt') ??
        DateTime.now().millisecondsSinceEpoch,
  );
  late final ticketClaimRewardsFrom = DateTime.fromMillisecondsSinceEpoch(
    prefs.getInt('tickets.claimRewardsFrom') ??
        DateTime.now().millisecondsSinceEpoch,
  );

  TicketBalance availableTickets(DateTime now) => ticketBalance(
    practice: events,
    challenges: studyEvents([
      '0',
      '0',
      ...?prefs.getStringList('tickets.challengeEvents'),
    ]),
    activated: ticketActivated,
    now: now,
    adRewards: prefs.getInt('tickets.adRewards') ?? 0,
    claims: claims,
    claimRewardsFrom: ticketClaimRewardsFrom,
  );

  void scheduleMidnightRefresh() {
    midnightRefresh?.cancel();
    if (!widget.refreshAtMidnight) return;
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    midnightRefresh = Timer(nextDay.difference(now), () {
      if (!mounted) return;
      setState(() {});
      scheduleMidnightRefresh();
    });
  }

  List<QuestClaim> get claims => [
    for (final value in prefs.getStringList('quest.claims') ?? const [])
      if (value.split(';') case [final stamp, final key])
        (when: DateTime.fromMillisecondsSinceEpoch(int.parse(stamp)), key: key),
  ];

  List<StudyEvent> get events => [
    for (final clip in clips.where((clip) => clip.format != 'challenge'))
      if (prefs.getStringList('practice.${clip.file}') case final values?)
        ...studyEvents(values),
  ];
  List<StudyEvent> get completedChallenges {
    final attempts =
        prefs.getStringList('tickets.challengeEvents') ?? const <String>[];
    return attempts.isEmpty ? const [] : studyEvents(['0', '0', ...attempts]);
  }

  String? challengeResult;

  List<StudyEvent> questionEvents(int question) {
    final values = prefs.getStringList('practice.${clips[question].file}');
    return values == null ? const [] : studyEvents(values);
  }

  bool lastPracticeNeedsReview(int question) {
    final rating = questionEvents(question).lastOrNull?.rating;
    return rating == null
        ? prefs.getBool('hard.${clips[question].file}') ?? false
        : rating == PracticeRating.okay || rating == PracticeRating.hard;
  }

  String ratingSummary(int question) {
    final counts = <PracticeRating, int>{};
    for (final event in questionEvents(question)) {
      if (event.rating case final rating?) {
        counts.update(rating, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return PracticeRating.values
        .map((rating) => '${rating.label} ${counts[rating] ?? 0}回')
        .join('  ・  ');
  }

  Completion? recorded(int i) {
    final values = prefs.getStringList('practice.${clips[i].file}');
    if (values != null) {
      return (stamp: int.parse(values[0]), count: int.parse(values[1]));
    }
    return null;
  }

  DateTime? last(int i) {
    final entry = recorded(i);
    return entry == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(entry.stamp);
  }

  Growth growth({String? category}) {
    var total = 0;
    for (var i = 0; i < clips.length; i++) {
      if (category == null || clips[i].category == category) {
        total += recorded(i)?.count ?? 0;
      }
    }
    final rewards = category == null
        ? claims.fold<int>(0, (sum, claim) => sum + rewardForClaim(claim))
        : 0;
    return Growth(total * practiceXp + rewards, category: category);
  }

  bool eligible(int i) {
    final time = last(i);
    return time == null || !DateTime.now().isBefore(reviewAvailableOn(time));
  }

  Iterable<int> questionsFor(String category) =>
      Iterable<int>.generate(clips.length).where(
        (i) => clips[i].category == category && clips[i].format != 'challenge',
      );

  String challengeKey(String id, int level) => 'passed.$id.$level';
  bool hasPassed(String id, int level) {
    final value = prefs.get(challengeKey(id, level));
    return value == true || value is String;
  }

  bool passed(int level) => hasPassed(category, level);
  int get unlockedLevel => unlockedFor(category);
  int unlockedFor(String id) {
    for (var level = 1; level < 5; level++) {
      if (!hasPassed(id, level)) return level;
    }
    return 5;
  }

  String skillTitle(String id) =>
      growth(category: id).titles[unlockedFor(id) - 1];
  int? get challengeIndex {
    final value = clips.indexWhere(
      (clip) =>
          clip.category == category &&
          clip.level == practiceLevel &&
          clip.format == 'challenge',
    );
    return value < 0 ? null : value;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    plan.addListener(refreshPlan);
    unawaited(plan.connect());
    recordVisit();
    scheduleMidnightRefresh();
    unawaited(checkForUpdate());
    WidgetsBinding.instance.addPostFrameCallback((_) => showTutorial());
    subscriptions.addAll([
      player.onPositionChanged.listen((value) {
        if (mounted && index != null && playing) {
          setState(() => position = value);
        }
      }),
      player.onDurationChanged.listen((value) {
        if (mounted) setState(() => duration = value);
      }),
      player.onPlayerComplete.listen((_) {
        if (mounted && index != null && playing) {
          setState(() {
            playing = false;
            paused = false;
            played = true;
            position = duration;
          });
          if (tutorial == TutorialStep.listen) {
            showStep(TutorialStep.japanese);
          } else if (tutorial != null && round > 0) {
            showStep(tutorial);
          }
        }
      }),
    ]);
  }

  TutorialStep? tutorial;
  int? tutorialQuestion;
  int? tutorialLevel;
  final tutorialAnchor = GlobalKey();
  final tutorialSurface = GlobalKey();
  Rect? tutorialTarget;
  bool tutorialMeasurementQueued = false;

  void measureTutorialTarget() {
    if (tutorialMeasurementQueued || tutorial == null) return;
    tutorialMeasurementQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tutorialMeasurementQueued = false;
      if (!mounted || tutorial == null) return;
      final surface = tutorialSurface.currentContext?.findRenderObject();
      final target = tutorialAnchor.currentContext?.findRenderObject();
      Rect? bounds;
      if (surface is RenderBox &&
          surface.hasSize &&
          target is RenderBox &&
          target.hasSize) {
        bounds = MatrixUtils.transformRect(
          target.getTransformTo(surface),
          Offset.zero & target.size,
        ).inflate(6).intersect(Offset.zero & surface.size);
        final viewport = RenderAbstractViewport.maybeOf(target);
        if (viewport is RenderBox) {
          final box = viewport as RenderBox;
          bounds = bounds.intersect(
            MatrixUtils.transformRect(
              box.getTransformTo(surface),
              box.paintBounds,
            ),
          );
        }
        if (bounds.isEmpty || !bounds.isFinite) bounds = null;
      }
      if (bounds != tutorialTarget) setState(() => tutorialTarget = bounds);
    });
  }

  void showStep(TutorialStep? step) {
    if (!mounted) return;
    setState(() {
      if (tutorial != step) tutorialTarget = null;
      tutorial = step;
    });
    if (step == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = tutorialAnchor.currentContext;
      if (mounted && tutorial == step && target != null) {
        unawaited(
          Scrollable.ensureVisible(
            target,
            alignment: 0.28,
            duration: const Duration(milliseconds: 220),
          ),
        );
      }
    });
  }

  Widget guided(TutorialStep step, Widget child, {bool match = true}) {
    if (!match || tutorial != step) return child;
    return KeyedSubtree(key: tutorialAnchor, child: child);
  }

  void beginTutorial() {
    setState(() {
      historyOpen = false;
      tutorialQuestion = null;
      tutorialLevel = null;
    });
    showStep(
      prefs.containsKey('home.categories')
          ? TutorialStep.categories
          : TutorialStep.tree,
    );
  }

  void tutorialPickLesson(String id) {
    openCategory(id);
    setState(() => practiceLevel = 1);
    final first = questionsFor(id)
        .where((i) => clips[i].level == 1)
        .firstOrNull;
    final available = questionsFor(id)
        .where((i) => clips[i].level <= unlockedFor(id) && eligible(i))
        .toList();
    final other = available.where((i) => clips[i].level > 1).firstOrNull;
    tutorialQuestion = first != null && eligible(first)
        ? first
        : other ?? available.firstOrNull;
    tutorialLevel = tutorialQuestion == null
        ? null
        : clips[tutorialQuestion!].level;
    showStep(TutorialStep.levels);
  }

  Future<void> showTutorial() async {
    if (!mounted || prefs.getBool('tutorial.walkthroughSeen') == true) return;
    final start = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const UsagePage(introductionOnly: true),
      ),
    );
    if (!mounted) return;
    await prefs.setBool('tutorial.walkthroughSeen', true);
    if (start == true && mounted) beginTutorial();
  }

  Future<void> showUsage() async {
    var start = false;
    await openPage(
      UsagePage(
        onTutorial: () {
          start = true;
          Navigator.of(context).pop();
        },
      ),
    );
    if (start && mounted) beginTutorial();
  }

  void refreshPlan() {
    if (mounted) setState(() {});
  }

  Future<void> showPurchasePlan() async {
    unawaited(plan.refresh());
    await showDialog<void>(
      context: context,
      builder: (_) => PurchasePlanDialog(
        access: plan,
        balance: availableTickets(DateTime.now()),
      ),
    );
  }

  Future<void> checkForUpdate() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        checkingForUpdate ||
        updateDismissed) {
      return;
    }
    checkingForUpdate = true;
    try {
      const channel = MethodChannel('biz.wisemap.dokoshado/app_update');
      final available = await channel.invokeMethod<bool>('isUpdateAvailable');
      if (mounted && !updateDismissed) {
        setState(() => showUpdateNotice = available == true);
      }
    } on PlatformException {
      // A failed update check must not interrupt practice.
    } on MissingPluginException {
      // Update availability is supplied by the Android app.
    } finally {
      checkingForUpdate = false;
    }
  }

  Future<void> openPlayUpdate() async {
    for (final link in [
      'market://details?id=biz.wisemap.dokoshado',
      'https://play.google.com/store/apps/details?id=biz.wisemap.dokoshado',
    ]) {
      if (await openExternalLink(Uri.parse(link))) return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Google Playを開けませんでした。')));
    }
  }

  Widget tutorialBubble(TutorialStep step) {
    final tip = switch (step) {
      TutorialStep.listen => listeningTip,
      TutorialStep.read => readingTip,
      TutorialStep.shadowOne ||
      TutorialStep.shadowTwo ||
      TutorialStep.shadowThree ||
      TutorialStep.shadowFour => shadowingTip,
      TutorialStep.review => reviewTip,
      _ => null,
    };
    final colors = Theme.of(context).colorScheme;
    final (message, next) = switch (step) {
      TutorialStep.tree => ('まず「スキルツリーを見る」を押して、練習したい分野を選びましょう。', null),
      TutorialStep.categories => ('「カテゴリーを選ぶ」を押して、練習したい分野を選びましょう。', null),
      TutorialStep.levels => (
        '同じレベルの練習を5問終えると、挑戦問題が開きます。挑戦後に「できた」を選ぶと、次のレベルに進めます。',
        tutorialQuestion == null
            ? TutorialStep.alternativeCategory
            : tutorialLevel == 1
            ? TutorialStep.question
            : TutorialStep.alternativeLevel,
      ),
      TutorialStep.alternativeLevel => (
        'Lv.1の練習1は復習待ちです。囲まれたレベルを押して、練習できる問題を開きましょう。',
        null,
      ),
      TutorialStep.alternativeCategory => (
        'この分野には今すぐ練習できる問題がありません。上のカテゴリー名を押して、別の分野を選びましょう。',
        null,
      ),
      TutorialStep.question => ('囲まれた練習を押して、1問始めましょう。', null),
      TutorialStep.listen => (
        '「再生」を押し、英文も和訳も見ずに、今の自分がどこまで聞き取れるかを確かめましょう。',
        null,
      ),
      TutorialStep.japanese => ('聞き終わったら「日本語確認へ」を押しましょう。', null),
      TutorialStep.meaning => (
        '英文と和訳を見比べて、聞こえた言葉と文全体の意味を確認しましょう。',
        TutorialStep.notes,
      ),
      TutorialStep.notes => (
        '「言い回し・文法」で、聞き取れなかった表現や文のポイントを確認しましょう。',
        TutorialStep.readButton,
      ),
      TutorialStep.readButton => ('意味を確認できたら「音読へ」を押しましょう。', null),
      TutorialStep.read => (
        '英文と和訳で内容を確かめたら、声に出して3回以上読みましょう。前の単語に戻らず、英語の語順のまま意味を追います。',
        TutorialStep.shadowButton,
      ),
      TutorialStep.shadowButton => ('音読が終わったら「シャドーイングへ」を押しましょう。', null),
      TutorialStep.shadowOne => (
        '1回目。英文を見ながら、手本の発音や声の上がり下がりをモノマネするつもりで、少し遅れて声に出しましょう。',
        null,
      ),
      TutorialStep.shadowTwo => (
        '2回目。英文を見ながら、発音とイントネーションに加え、音の強弱やリズムもまねしましょう。',
        null,
      ),
      TutorialStep.shadowThree => (
        '3回目。英文を見ずに、聞こえた発音やイントネーションをそのまままねしましょう。',
        null,
      ),
      TutorialStep.shadowFour => (
        '4回目も英文を見ず、手本の話し方までまねしましょう。終わったら「学習を完了する」を押します。',
        null,
      ),
      TutorialStep.ratePractice => (
        '今回の手応えを選びましょう。選ぶと、評価を記録してスキルツリーに戻ります。',
        null,
      ),
      TutorialStep.review => (
        '練習直後の記憶に頼らず、耳で聞き取れるかを確かめるため、完了日から3日後の午前0時まで復習できません。',
        TutorialStep.returnHome,
      ),
      TutorialStep.returnHome => ('左上の矢印でトップへ戻りましょう。', null),
      TutorialStep.growth => (
        '問題を完了すると経験値がたまります。共通レベルはLv.100まであり、節目のレベルで新しい称号を獲得できます。',
        TutorialStep.quest,
      ),
      TutorialStep.quest => ('「クエスト」を押して、今日や今週の課題を見てみましょう。', null),
      TutorialStep.history => ('「学習記録」を押して、ここまでの練習を振り返りましょう。', null),
      TutorialStep.graph => (
        'グラフで、練習した問題数と学習時間の変化を確認できます。',
        TutorialStep.totals,
      ),
      TutorialStep.totals => (
        '今日・今週・今月の練習量は、ここでまとめて確認できます。',
        TutorialStep.badges,
      ),
      TutorialStep.badges => (
        '学習日数やクリアした問題数などに応じて、バッジを獲得できます。',
        TutorialStep.guide,
      ),
      TutorialStep.guide => (
        '操作に迷ったときは、上の「使い方」からいつでも確認できます。',
        TutorialStep.returnTraining,
      ),
      TutorialStep.returnTraining => ('「トレーニング」を押して、トップ画面に戻りましょう。', null),
      TutorialStep.tickets => (
        plan.unlimited
            ? '上の「∞」は、チケット無制限の表示です。無料プランでは、1問につきチケット1枚を使い、毎日午前0時に3枚に回復します。追加チケットはクエストや動画広告で受け取れます。'
            : '円の中は、今日使えるチケットの残り枚数です。1問につき1枚使い、毎日午前0時に3枚に回復します。右の「＋」は、クエストや動画広告で受け取った追加チケットの枚数です。',
        TutorialStep.ticketPlan,
      ),
      TutorialStep.ticketPlan => (
        'このアイコンを押すと、チケットと有料プランを確認できます。買い切りの有料プランでは、チケット無制限・広告非表示で練習できます。購入の復元もここから行えます。',
        TutorialStep.reminder,
      ),
      TutorialStep.reminder => ('最後にベルを押しましょう。学習を思い出したい時刻に、通知を設定できます。', null),
    };
    return Material(
      color: tip == null ? colors.surface : colors.primaryContainer,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: tip == null
            ? BorderSide.none
            : BorderSide(color: colors.primary, width: 2),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  tip?.icon ?? Icons.chat_bubble_outline,
                  size: 21,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tip != null) ...[
                        Text(
                          tip.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(message),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: () => showStep(null),
                  child: const Text('案内を終了'),
                ),
                if (next != null)
                  FilledButton(
                    onPressed: () => showStep(next),
                    child: const Text('案内の次へ'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground) {
      recordVisit();
      scheduleMidnightRefresh();
      unawaited(checkForUpdate());
      unawaited(plan.refresh());
      if (widget.refreshAtMidnight) setState(() {});
    }
    if (index != null && !complete) {
      if (foreground) {
        studyClock.start();
      } else {
        studyClock.stop();
      }
    }
    if (!foreground && playing) {
      setState(() {
        playing = false;
        paused = true;
      });
      unawaited(player.pause().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    plan.removeListener(refreshPlan);
    if (widget.purchases == null) plan.dispose();
    midnightRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(player.dispose());
    super.dispose();
  }

  void start(int i) {
    if (busy || index != null || ticketPromptOpen) return;
    if (!plan.unlimited &&
        nextTicket(availableTickets(DateTime.now())) == null) {
      unawaited(showTicketOptions());
      return;
    }
    if (clips[i].format != 'challenge' && recorded(i) == null) {
      unawaited(widget.analytics?.started(DateTime.now()));
    }
    studyClock
      ..reset()
      ..start();
    setState(() {
      index = i;
      round = 0;
      complete = false;
      pendingCompletion = null;
      sharedThisPractice = false;
      challengeResult = null;
      speed = 1;
      resetPlayback();
    });
    if (tutorial != null) {
      showStep(
        tutorial == TutorialStep.question && i == tutorialQuestion
            ? TutorialStep.listen
            : null,
      );
    }
  }

  Future<void> showTicketOptions() async {
    if (ticketPromptOpen || plan.unlimited) return;
    ticketPromptOpen = true;
    try {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('チケットがありません'),
          content: const Text(
            '練習にはチケットが1枚必要です。毎日午前0時に、デイリーチケットが3枚配布されます。広告動画を最後まで見ると、追加チケットを1枚受け取れます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'plan'),
              child: const Text('有料プランを見る'),
            ),
            FilledButton(
              onPressed: adsEnabled ? () => Navigator.pop(context, 'ad') : null,
              child: const Text('広告動画で1枚受け取る'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (action == 'plan') {
        await showPurchasePlan();
      } else if (action == 'ad') {
        final messenger = ScaffoldMessenger.of(context);
        final progress = messenger.showSnackBar(
          const SnackBar(
            content: Text('広告動画を読み込んでいます…'),
            duration: Duration(seconds: 15),
          ),
        );
        final reward = await showTicketAd();
        progress.close();
        if (reward == RewardedTicketResult.earned) {
          final count = prefs.getInt('tickets.adRewards') ?? 0;
          var saved = false;
          try {
            saved = await prefs.setInt('tickets.adRewards', count + 1);
            if (!saved) await prefs.reload();
          } catch (_) {
            await prefs.reload();
          }
          if (!mounted) return;
          setState(() {});
          messenger.showSnackBar(
            SnackBar(
              content: Text(saved ? '追加チケットを1枚受け取りました。' : '追加チケットを保存できませんでした。'),
            ),
          );
        } else if (reward == RewardedTicketResult.unavailable && mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('広告動画を読み込めませんでした。時間をおいてお試しください。')),
          );
        }
      }
    } finally {
      ticketPromptOpen = false;
    }
  }

  void resetPlayback() {
    playing = false;
    played = false;
    paused = false;
    reveal = false;
    position = Duration.zero;
    duration = Duration.zero;
    error = null;
  }

  Future<void> playRound() async {
    if (!foreground || index == null || busy || played || !usesAudio) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (playing) {
        await player.pause();
        if (mounted)
          setState(() {
            playing = false;
            paused = true;
          });
        return;
      }
      if (!paused) {
        await player.setSource(AssetSource('audio/${clips[index!].file}.m4a'));
        await player.seek(Duration.zero);
      }
      await player.setPlaybackRate(speed);
      if (!foreground || !mounted) return;
      setState(() {
        playing = true;
        paused = false;
      });
      await player.resume();
    } catch (_) {
      if (mounted)
        setState(() {
          playing = false;
          error = '音声を再生できませんでした';
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> advance() async {
    if (!canAdvance) return;
    if (round != 4) {
      setState(() {
        round = switch (round) {
          0 => meaningStep,
          meaningStep => readAloudStep,
          readAloudStep => 1,
          _ => round + 1,
        };
        resetPlayback();
      });
      if (tutorial != null) {
        showStep(switch (round) {
          meaningStep => TutorialStep.meaning,
          readAloudStep => TutorialStep.read,
          1 => TutorialStep.shadowOne,
          2 => TutorialStep.shadowTwo,
          3 => TutorialStep.shadowThree,
          4 => TutorialStep.shadowFour,
          _ => null,
        });
      }
      if (round > 0) {
        final expectedQuestion = index;
        final expectedRound = round;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && index == expectedQuestion && round == expectedRound) {
            unawaited(playRound());
          }
        });
      }
      return;
    }
    final now = DateTime.now();
    final ticket = plan.unlimited ? null : nextTicket(availableTickets(now));
    if (!plan.unlimited && ticket == null) {
      await showTicketOptions();
      return;
    }
    if (clips[index!].format == 'challenge') {
      setState(() => busy = true);
      final prior =
          prefs.getStringList('tickets.challengeEvents') ?? const <String>[];
      final attempt = encodeStudyEvent((
        when: now,
        seconds: studyClock.elapsed.inSeconds,
        difficultReview: false,
        rating: null,
        ticket: ticket,
      ));
      var saved = false;
      try {
        saved = await prefs.setStringList('tickets.challengeEvents', [
          ...prior,
          attempt,
        ]);
      } catch (_) {
        // Leave the attempt on the same screen for retry.
      }
      if (!saved) await prefs.reload();
      if (!mounted) return;
      setState(() {
        busy = false;
        error = saved ? null : 'チケットの利用を保存できませんでした。もう一度お試しください。';
        complete = saved;
      });
      if (saved) studyClock.stop();
      return;
    }
    studyClock.stop();
    final question = index!;
    final previous = recorded(question);
    setState(() {
      pendingCompletion = (
        event: (
          when: now,
          seconds: studyClock.elapsed.inSeconds,
          difficultReview:
              previous != null && lastPracticeNeedsReview(question),
          rating: null,
          ticket: ticket,
        ),
        history: [
          now.millisecondsSinceEpoch.toString(),
          '${(previous?.count ?? 0) + 1}',
          ...questionEvents(question).map(encodeStudyEvent),
        ],
      );
      complete = true;
    });
    if (tutorial == TutorialStep.shadowFour)
      showStep(TutorialStep.ratePractice);
  }

  Future<void> saveCompletion(PracticeRating rating) async {
    final pending = pendingCompletion;
    final question = index;
    if (pending == null || question == null || busy) return;
    final key = 'practice.${clips[question].file}';
    final attempt = encodeStudyEvent((
      when: pending.event.when,
      seconds: pending.event.seconds,
      difficultReview: pending.event.difficultReview,
      rating: rating,
      ticket: plan.unlimited ? null : pending.event.ticket,
    ));
    setState(() => busy = true);
    var saved = false;
    try {
      saved = await prefs.setStringList(key, [...pending.history, attempt]);
    } catch (_) {
      // Keep the rating controls available so the user can retry.
    }
    if (!saved) await prefs.reload();
    if (!mounted) return;
    setState(() {
      busy = false;
      error = saved ? null : '評価を保存できませんでした。もう一度選んでください。';
      if (saved) pendingCompletion = null;
    });
    if (saved) {
      if (pending.history[1] == '1') {
        unawaited(widget.analytics?.completed(DateTime.now()));
      }
      await back();
      if (mounted &&
          tutorial == null &&
          !sharedThisPractice &&
          foreground &&
          !isPreviewBuild) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              index == null &&
              treeOpen &&
              foreground &&
              tutorial == null) {
            unawaited(ReviewPrompt.requestIfDue(prefs, events, DateTime.now()));
          }
        });
      }
    }
  }

  Future<void> back() async {
    if (busy || pendingCompletion != null) return;
    if (index == null) {
      setState(() => treeOpen = false);
      if (tutorial == TutorialStep.returnHome) {
        showStep(TutorialStep.growth);
      } else if (tutorial != null) {
        showStep(null);
      }
      return;
    }
    studyClock.stop();
    setState(() {
      if (challengeResult != null && practiceLevel < unlockedLevel)
        practiceLevel = unlockedLevel;
      index = null;
      busy = true;
    });
    try {
      await player.stop();
    } finally {
      if (mounted) setState(() => busy = false);
    }
    if (tutorial == TutorialStep.ratePractice) {
      showStep(TutorialStep.review);
    } else if (tutorial != null) {
      showStep(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onTop = !treeOpen;
    final onTree = treeOpen && index == null;
    final activeClip = index == null ? null : clips[index!];
    final theme = Theme.of(context);
    measureTutorialTarget();
    return PopScope(
      canPop: onTop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(back());
      },
      child: Stack(
        key: tutorialSurface,
        fit: StackFit.expand,
        children: [
          NotificationListener<Notification>(
            onNotification: (notification) {
              if (notification is ScrollNotification ||
                  notification is ScrollMetricsNotification) {
                measureTutorialTarget();
              }
              return false;
            },
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                scrolledUnderElevation: 0,
                actions: onTop
                    ? [
                        if (!historyOpen)
                          guided(
                            tutorial == TutorialStep.ticketPlan
                                ? TutorialStep.ticketPlan
                                : TutorialStep.tickets,
                            ticketHeader(),
                          ),
                        guided(
                          TutorialStep.reminder,
                          IconButton(
                            tooltip: '学習リマインダー',
                            icon: const Icon(Icons.notifications_none_outlined),
                            onPressed: widget.reminders == null
                                ? null
                                : () {
                                    if (tutorial != null) showStep(null);
                                    openPage(
                                      ReminderSettingsPage(
                                        manager: widget.reminders!,
                                      ),
                                    );
                                  },
                          ),
                        ),
                        guided(
                          TutorialStep.guide,
                          TextButton(
                            onPressed: showUsage,
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimary,
                            ),
                            child: const Text('使い方'),
                          ),
                        ),
                        IconButton(
                          tooltip: 'アプリについて',
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => AppInformationDialog(
                              analytics: widget.analytics,
                              onPlan: () {
                                Navigator.of(context).pop();
                                unawaited(showPurchasePlan());
                              },
                            ),
                          ),
                        ),
                      ]
                    : null,
                title: onTop
                    ? Row(
                        children: [
                          Image.asset(
                            'assets/brand/dokoshado.png',
                            width: 32,
                            height: 32,
                            excludeFromSemantics: true,
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isPreviewBuild ? 'どこシャド確認版' : 'どこシャド',
                              ),
                            ),
                          ),
                        ],
                      )
                    : activeClip == null
                    ? const Text('スキルツリー')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            interestLabel(activeClip.category),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          Text(
                            'Lv.${activeClip.level} ${growth(category: activeClip.category).titles[activeClip.level - 1]}'
                            '${activeClip.format == 'challenge' ? ' ・ 挑戦問題' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                automaticallyImplyLeading: pendingCompletion == null,
                leading: onTop || pendingCompletion != null
                    ? null
                    : guided(
                        TutorialStep.returnHome,
                        IconButton(
                          tooltip: onTree ? 'トップへ戻る' : 'スキルツリーへ戻る',
                          onPressed: busy ? null : back,
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
              ),
              bottomNavigationBar: onTop
                  ? NavigationBar(
                      selectedIndex: historyOpen ? 1 : 0,
                      onDestinationSelected: (value) {
                        setState(() => historyOpen = value == 1);
                        if (tutorial == TutorialStep.returnTraining &&
                            value == 0) {
                          showStep(TutorialStep.tickets);
                        } else if (value == 1 &&
                            {
                              TutorialStep.tickets,
                              TutorialStep.ticketPlan,
                              TutorialStep.reminder,
                            }.contains(tutorial)) {
                          showStep(TutorialStep.returnTraining);
                        } else if (tutorial == TutorialStep.history &&
                            value == 1) {
                          showStep(TutorialStep.graph);
                        } else if (value == 0 &&
                            {
                              TutorialStep.graph,
                              TutorialStep.totals,
                              TutorialStep.badges,
                            }.contains(tutorial)) {
                          showStep(TutorialStep.history);
                        } else if (value == 1 &&
                            {
                              TutorialStep.tree,
                              TutorialStep.categories,
                              TutorialStep.growth,
                              TutorialStep.quest,
                            }.contains(tutorial)) {
                          showStep(null);
                        }
                      },
                      destinations: [
                        NavigationDestination(
                          icon: guided(
                            TutorialStep.returnTraining,
                            const Icon(Icons.auto_stories_outlined),
                          ),
                          label: 'トレーニング',
                        ),
                        NavigationDestination(
                          icon: guided(
                            TutorialStep.history,
                            const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.insights_outlined),
                            ),
                          ),
                          selectedIcon: const Icon(Icons.insights_outlined),
                          label: '学習記録',
                        ),
                      ],
                    )
                  : null,
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: SingleChildScrollView(
                      key: ValueKey((
                        onTop,
                        onTree,
                        index,
                        complete,
                        round,
                        historyOpen,
                      )),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: TutorialLayoutObserver(
                        onChanged: measureTutorialTarget,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: onTop
                              ? (historyOpen ? learningHistory() : home())
                              : onTree
                              ? skillTree()
                              : complete
                              ? [
                                  ...completion(),
                                  if (plan.initialized && !plan.unlimited)
                                    const TicketBanner(
                                      TicketAdPlacement.completion,
                                    ),
                                ]
                              : lesson(clips[index!]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (tutorial case final step?) ...[
            if (tutorialTarget case final target?)
              IgnorePointer(
                child: CustomPaint(painter: _TutorialShade(target)),
              ),
            SafeArea(
              child: CustomSingleChildLayout(
                delegate: _TutorialBubbleLayout(
                  tutorialTarget?.shift(
                    Offset(0, -MediaQuery.paddingOf(context).top),
                  ),
                ),
                child: tutorialBubble(step),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget heading(String text) =>
      Text(text, style: Theme.of(context).textTheme.headlineSmall);

  Future<void> openPage(Widget page) =>
      Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => page));

  List<Quest> get quests => questsFor(
    events,
    claims.map((claim) => claim.key).toSet(),
    DateTime.now(),
  );

  Future<bool> claimQuest(Quest quest) async {
    if (claimSaving ||
        !quests.any(
          (q) => q.key == quest.key && !q.claimed && q.value >= q.goal,
        ))
      return false;
    claimSaving = true;
    final previous = prefs.getStringList('quest.claims') ?? const [];
    try {
      final saved = await prefs.setStringList('quest.claims', [
        ...previous,
        '${DateTime.now().millisecondsSinceEpoch};${quest.key}',
      ]);
      if (saved && mounted) setState(() {});
      return saved;
    } catch (_) {
      return false;
    } finally {
      claimSaving = false;
    }
  }

  List<Widget> home() {
    final current = quests;
    final ready = current.where((q) => !q.claimed && q.value >= q.goal).length;
    return [
      if (showUpdateNotice && tutorial == null) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '新しいバージョンがあります',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text('Google Playからどこシャドを更新できます。'),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          showUpdateNotice = false;
                          updateDismissed = true;
                        }),
                        child: const Text('あとで'),
                      ),
                      FilledButton(
                        onPressed: openPlayUpdate,
                        child: const Text('アプリの更新'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      guided(
        TutorialStep.quest,
        OutlinedButton.icon(
          onPressed: () async {
            final inTutorial = tutorial == TutorialStep.quest;
            await openPage(
              QuestPage(
                quests: current,
                claim: claimQuest,
                events: events,
                commonXp: growth().xp,
                showTutorial: inTutorial,
              ),
            );
            if (mounted && inTutorial && tutorial == TutorialStep.quest) {
              showStep(TutorialStep.history);
            }
          },
          icon: const Icon(Icons.flag_outlined),
          label: Text(ready > 0 ? 'クエスト（報酬 $ready件）' : 'クエスト'),
        ),
      ),
      const SizedBox(height: 12),
      growthCard(),
      const SizedBox(height: 16),
      categoryGrowthCard(),
      if (plan.initialized && !plan.unlimited) const AdPrivacyOptions(),
      if (plan.initialized && !plan.unlimited)
        const TicketBanner(TicketAdPlacement.home),
    ];
  }

  Widget ticketHeader() {
    if (plan.unlimited) {
      return IconButton(
        tooltip: '無制限プランをご利用中',
        onPressed: showPurchasePlan,
        icon: const Icon(Icons.all_inclusive),
      );
    }
    final balance = availableTickets(DateTime.now());
    final color = Theme.of(context).colorScheme.onPrimary;
    final style = TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    return Tooltip(
      message: 'チケットと有料プラン',
      child: TextButton(
        onPressed: showPurchasePlan,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Semantics(
          label:
              'デイリーチケット 残り ${balance.daily} 枚、最大3枚。追加チケット ${balance.bonus} 枚。',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 29,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: balance.daily / dailyTicketLimit,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.25),
                      strokeWidth: 2.5,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('${balance.daily}/3', style: style),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: 33,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '+${balance.bonus}',
                    style: style.copyWith(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get displayedCategories =>
      prefs.getStringList('home.categories') ?? const ['travel'];

  void openCategory(String id) => setState(() {
    category = id;
    practiceLevel = unlockedFor(id);
    treeOpen = true;
  });

  Future<void> editDisplayedCategories() async {
    final inTutorial =
        tutorial == TutorialStep.tree || tutorial == TutorialStep.categories;
    final selected = inTutorial && !prefs.containsKey('home.categories')
        ? <String>{}
        : displayedCategories.toSet();
    String? chosen;
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(inTutorial ? '練習したい分野を選び、OKを押す' : '興味のある分野を選ぶ'),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in interestCategories)
                  CheckboxListTile(
                    secondary: Icon(item.icon, size: 20),
                    title: Text(item.label),
                    value: inTutorial
                        ? chosen == item.id
                        : selected.contains(item.id),
                    onChanged: (checked) => refresh(() {
                      if (checked == true) {
                        if (inTutorial) {
                          chosen = item.id;
                        } else {
                          selected.add(item.id);
                        }
                      } else {
                        if (inTutorial) {
                          chosen = null;
                        } else {
                          selected.remove(item.id);
                        }
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: inTutorial && chosen == null
                  ? null
                  : () => Navigator.pop(context, [
                      for (final item in interestCategories)
                        if (selected.contains(item.id) || item.id == chosen)
                          item.id,
                    ]),
              child: Text(inTutorial ? 'OK' : '保存'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    final saved = await prefs.setStringList('home.categories', result);
    if (mounted && saved) {
      if (inTutorial && tutorial != null) {
        tutorialPickLesson(chosen!);
      } else {
        setState(() {});
      }
    }
  }

  Widget categoryGrowthCard() {
    final colors = Theme.of(context).colorScheme;
    final displayed = displayedCategories.where(isInterest).toList();
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'カテゴリーの成長',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                guided(
                  TutorialStep.categories,
                  Tooltip(
                    message: 'カテゴリーを選ぶ',
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        minimumSize: const Size(0, 40),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('カテゴリー変更'),
                      onPressed: editDisplayedCategories,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              displayed.isEmpty
                  ? '興味のある分野を選ぶと、成長がここに表示されます。'
                  : '濃い色は挑戦合格。タップして学習へ。',
              style: TextStyle(fontSize: 11, color: colors.primary),
            ),
            if (displayed.isNotEmpty) const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= 260 &&
                        MediaQuery.textScalerOf(context).scale(12) <= 15
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    for (final id in displayed)
                      SizedBox(
                        width: width,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => openCategory(id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  interestLabel(id),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    for (var level = 1; level <= 5; level++)
                                      Expanded(
                                        child: Container(
                                          height: 7,
                                          margin: const EdgeInsets.only(
                                            right: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                            color: hasPassed(id, level)
                                                ? colors.primary
                                                : level == unlockedFor(id)
                                                ? const Color(0xff87aed5)
                                                : const Color(0xffe4eaf2),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Lv.${unlockedFor(id)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void recordVisit() {
    final stored = prefs.getStringList('visit.days') ?? const [];
    final today = dayKey(DateTime.now());
    if (stored.contains(today)) return;
    unawaited(
      prefs
          .setStringList('visit.days', [...stored, today])
          .then<void>((_) {})
          .catchError((Object _) {}),
    );
    if (historyOpen && mounted) setState(() {});
  }

  List<Widget> learningHistory() {
    final days = <String, DailyActivity>{};
    final visits = (prefs.getStringList('visit.days') ?? const []).toSet();
    for (final event in [...events, ...completedChallenges]) {
      final key = dayKey(event.when);
      visits.add(key);
      days[key] = (days[key] ?? const DailyActivity()).plus(
        questions: 1,
        milliseconds: event.seconds * 1000,
      );
    }
    final clears = <String?>[];
    var attempts = 0;
    for (final clip in clips.where((clip) => clip.format != 'challenge')) {
      final values = prefs.getStringList('practice.${clip.file}');
      if (values == null) continue;
      final count = int.parse(values[1]);
      attempts += count;
      final known = studyEvents(values);
      clears.add(known.length == count ? dayKey(known.first.when) : null);
    }
    final passes = <String?>[
      for (final item in interestCategories)
        for (var level = 1; level <= 5; level++)
          if (hasPassed(item.id, level))
            switch (prefs.get(challengeKey(item.id, level))) {
              final String date => date,
              _ => null,
            },
    ];
    return [
      LearningDashboard(
        days: days,
        visits: visits,
        badges: achievements(
          visitDays: visits,
          days: days,
          clears: clears,
          passes: passes,
          attempts: attempts,
        ),
        now: DateTime.now(),
        highlight: (section, child) => guided(switch (section) {
          LearningSection.graph => TutorialStep.graph,
          LearningSection.totals => TutorialStep.totals,
          LearningSection.badges => TutorialStep.badges,
        }, child),
      ),
      if (plan.initialized && !plan.unlimited)
        const TicketBanner(TicketAdPlacement.history),
    ];
  }

  Future<void> showGrowthHistory() {
    final gains = [
      for (final event in events)
        (when: event.when, amount: practiceXp, label: '学習完了'),
      for (final claim in claims)
        (when: claim.when, amount: rewardForClaim(claim), label: 'クエスト報酬'),
    ]..sort((a, b) => a.when.compareTo(b.when));
    var cumulative =
        growth().xp - gains.fold<int>(0, (sum, gain) => sum + gain.amount);
    final milestones = <Widget>[];
    for (final gain in gains) {
      final before = Growth(cumulative);
      cumulative += gain.amount;
      final after = Growth(cumulative);
      milestones.add(
        ListTile(
          leading: Icon(
            before.level == after.level
                ? Icons.add_circle_outline
                : Icons.emoji_events_outlined,
          ),
          title: Text('${gain.label}  +${gain.amount} EXP'),
          subtitle: Text(
            before.level == after.level
                ? dayLabel(gain.when)
                : '${dayLabel(gain.when)}  ·  Lv.${after.level} ${after.title}',
          ),
        ),
      );
    }
    return openPage(
      Scaffold(
        appBar: AppBar(title: const Text('成長履歴')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Lv.${growth().level} ${growth().title}  ·  累計 ${growth().xp} EXP',
            ),
            if (milestones.isEmpty) const Text('学習完了やクエスト報酬の記録がここに表示されます。'),
            ...milestones.reversed,
          ],
        ),
      ),
    );
  }

  Future<void> chooseCategory() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('カテゴリーを選ぶ'),
        children: [
          for (final item in interestCategories)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item.id),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(item.icon, size: 20),
                title: Text(item.label),
                subtitle: questionsFor(item.id).isEmpty
                    ? const Text('教材準備中')
                    : null,
                trailing: item.id == category ? const Icon(Icons.check) : null,
              ),
            ),
        ],
      ),
    );
    if (mounted &&
        selected != null &&
        tutorial == TutorialStep.alternativeCategory) {
      tutorialPickLesson(selected);
      return;
    }
    if (mounted && selected != null && selected != category) {
      setState(() {
        category = selected;
        practiceLevel = unlockedFor(selected);
      });
    }
  }

  List<Widget> skillTree() {
    final categoryQuestions = questionsFor(category).toList();
    final questions = categoryQuestions
        .where((i) => clips[i].level == practiceLevel)
        .toList();
    final cleared = questions.where((i) => last(i) != null).length;
    final unlocked = practiceLevel <= unlockedLevel;
    final isPassed = passed(practiceLevel);
    final challenge = challengeIndex;
    final titles = growth(category: category).titles;
    return [
      guided(
        TutorialStep.alternativeCategory,
        OutlinedButton(
          onPressed: busy ? null : chooseCategory,
          child: Row(
            children: [
              Icon(interestCategory(category).icon, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(interestLabel(category))),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text('カテゴリーを切り替えて、学習レベルを選択'),
      const SizedBox(height: 8),
      const SizedBox(height: 8),
      if (categoryQuestions.isEmpty)
        const Text('このカテゴリーの教材は準備中です。')
      else ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: SkillCharacter(
                    category: category,
                    level: practiceLevel,
                    title: unlocked ? titles[practiceLevel - 1] : '？？？',
                    unlocked: unlocked,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: guided(
                TutorialStep.levels,
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var level = 1; level <= 5; level++)
                      guided(
                        TutorialStep.alternativeLevel,
                        ChoiceChip(
                          label: Text(
                            'Lv.$level ${level <= unlockedLevel ? titles[level - 1] : '？？？'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          avatar: Icon(
                            passed(level)
                                ? Icons.check_circle_outline
                                : level <= unlockedLevel
                                ? Icons.circle_outlined
                                : Icons.lock_outline,
                            size: 16,
                          ),
                          selected: practiceLevel == level,
                          onSelected: busy
                              ? null
                              : (_) {
                                  setState(() => practiceLevel = level);
                                  if (tutorial ==
                                          TutorialStep.alternativeLevel &&
                                      level == tutorialLevel)
                                    showStep(TutorialStep.question);
                                },
                        ),
                        match: level == tutorialLevel,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        heading(
          'Lv.$practiceLevel ${unlocked ? titles[practiceLevel - 1] : '？？？'} の練習',
        ),
        if (!unlocked)
          const Text('前のレベルの挑戦に合格すると解放されます。')
        else ...[
          Text('通常問題  $cleared / ${questions.length} 問完了'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: questions.isEmpty ? 0 : cleared / questions.length,
          ),
          const SizedBox(height: 8),
          const Text('完了した問題は、完了日から3日後に再挑戦できます。'),
          for (final (step, question) in questions.indexed)
            guided(
              tutorial == TutorialStep.review
                  ? TutorialStep.review
                  : TutorialStep.question,
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: last(question) == null
                        ? Text('${step + 1}')
                        : const Icon(Icons.check, size: 20),
                  ),
                  title: Text('練習 ${step + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        last(question) == null
                            ? '未学習'
                            : eligible(question)
                            ? '復習できます'
                            : '完了・復習待ち',
                      ),
                      Text(ratingSummary(question)),
                    ],
                  ),
                  trailing: Icon(
                    eligible(question) ? Icons.play_arrow : Icons.lock_outline,
                  ),
                  enabled: !busy && eligible(question),
                  onTap: !busy && eligible(question)
                      ? () => start(question)
                      : null,
                ),
              ),
              match: tutorialQuestion == question,
            ),
          const SizedBox(height: 8),
          if (challenge != null)
            Card(
              child: ListTile(
                leading: Icon(
                  isPassed ? Icons.emoji_events_outlined : Icons.flag_outlined,
                ),
                title: const Text('挑戦問題'),
                subtitle: Text(
                  isPassed
                      ? '合格'
                      : cleared == questions.length
                      ? '自己評価で「できた」なら合格'
                      : '通常問題5問を完了すると解放',
                ),
                enabled:
                    !busy && !isPassed && questions.length == 5 && cleared == 5,
                onTap:
                    !busy && !isPassed && questions.length == 5 && cleared == 5
                    ? () => start(challenge)
                    : null,
              ),
            ),
        ],
      ],
    ];
  }

  Widget growthCard() {
    final progress = growth();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('共通レベル・称号', style: theme.textTheme.titleMedium),
              ),
              IconButton(
                tooltip: '成長履歴',
                onPressed: showGrowthHistory,
                icon: const Icon(Icons.history_rounded),
              ),
              IconButton(
                tooltip: '経験値と称号のルール',
                icon: const Icon(Icons.help_outline),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('経験値と称号'),
                    content: const Text(
                      '通常問題を1問完了すると、全体とカテゴリーにそれぞれ10 EXPが入ります。復習も対象です。共通レベルはLv.100まであり、節目で称号が変わります。カテゴリーの称号は、挑戦に合格して次のレベルを解放すると変わります。',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('閉じる'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          guided(
            TutorialStep.growth,
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Lv. ${progress.level}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
                Text(
                  '称号：${progress.title}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.fraction,
            minHeight: 10,
            backgroundColor: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 10),
          Text(
            progress.remaining == 0
                ? '最高称号に到達'
                : 'あと ${progress.remaining} EXPで Lv. ${progress.level + 1}',
          ),
          Text('累計 ${progress.xp} EXP'),
          if (progress.nextTitleLevel case final nextTitleLevel?)
            Text('次の称号「？？？」はLv.$nextTitleLevel')
          else
            const Text('最高の称号に到達しました。'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: guided(
              TutorialStep.tree,
              FilledButton.icon(
                onPressed: () {
                  if (tutorial == TutorialStep.tree) {
                    editDisplayedCategories();
                  } else {
                    setState(() {
                      practiceLevel = unlockedLevel;
                      treeOpen = true;
                    });
                  }
                },
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('スキルツリーを見る'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> lesson(Clip clip) {
    final shadowStep = switch (round) {
      1 => TutorialStep.shadowOne,
      2 => TutorialStep.shadowTwo,
      3 => TutorialStep.shadowThree,
      _ => TutorialStep.shadowFour,
    };
    final words = clip.english.split(' ');
    final progress = duration == Duration.zero
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final activeWord = widget.karaoke.wordAt(clip.file, clip.english, position);
    final colors = Theme.of(context).colorScheme;
    return [
      TravelScene(clip.file, category: clip.category),
      const SizedBox(height: 12),
      heading(switch (round) {
        0 => 'まずは聞いてみよう',
        meaningStep => '日本語で意味を確認',
        readAloudStep => '音読',
        _ => 'シャドーイング  $round / 4',
      }),
      Text(switch (round) {
        0 => '「再生」を押して、何を話しているか聞き取ってみましょう。',
        meaningStep => '英文と和訳を読み、言い回しや文法の解説で聞き取れなかった部分を確かめましょう。',
        readAloudStep =>
          '英文の意味を理解しながら、自分のペースで3回声に出して読みましょう。読み終わったら「シャドーイングへ」を押してください。',
        _ => '聞こえた英語を少し遅れて声に出しましょう。',
      }),
      if (usesAudio) ...[
        const SizedBox(height: 12),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 8),
        if (error != null) Text(error!),
        if (played)
          const Text('再生が終わりました')
        else
          guided(
            TutorialStep.listen,
            FilledButton.tonalIcon(
              onPressed: busy ? null : playRound,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              label: Text(
                playing
                    ? '一時停止'
                    : paused
                    ? '再開'
                    : '再生',
              ),
            ),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final rate in [0.8, 1.0, 1.2])
              ChoiceChip(
                label: Text('$rate倍'),
                selected: speed == rate,
                onSelected: busy
                    ? null
                    : (_) async {
                        setState(() => speed = rate);
                        if (playing) await player.setPlaybackRate(rate);
                      },
              ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      if (round >= 3)
        OutlinedButton(
          onPressed: () => setState(() => reveal = !reveal),
          child: Text(reveal ? '英文を隠す' : '英文を表示'),
        ),
      if (round == 0 || (round >= 3 && !reveal))
        guided(
          shadowStep,
          const Text('英文は非表示です'),
          match: round >= 3 && !played,
        ),
      if (!usesAudio || (round > 0 && round <= 2) || reveal)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                guided(
                  switch (round) {
                    meaningStep => TutorialStep.meaning,
                    readAloudStep => TutorialStep.read,
                    _ => shadowStep,
                  },
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            for (var i = 0; i < words.length; i++)
                              TextSpan(
                                text: '${words[i]} ',
                                style:
                                    playing &&
                                        round > 0 &&
                                        round <= 2 &&
                                        i == activeWord
                                    ? TextStyle(
                                        backgroundColor:
                                            colors.primaryContainer,
                                        color: colors.onPrimaryContainer,
                                      )
                                    : null,
                              ),
                          ],
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(clip.japanese),
                    ],
                  ),
                  match: round <= 0 || !played,
                ),
                if (round == meaningStep) ...[
                  const Divider(height: 28),
                  guided(
                    TutorialStep.notes,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '言い回し・文法',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final (expression, explanation) in clip.notes)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expression,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(explanation),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      const SizedBox(height: 12),
      guided(
        switch (round) {
          0 => TutorialStep.japanese,
          meaningStep => TutorialStep.readButton,
          readAloudStep => TutorialStep.shadowButton,
          _ => shadowStep,
        },
        FilledButton(
          onPressed: canAdvance ? advance : null,
          child: Text(switch (round) {
            0 => '日本語確認へ',
            meaningStep => '音読へ',
            readAloudStep => 'シャドーイングへ',
            4 => clips[index!].format == 'challenge' ? '自己評価へ' : '学習を完了する',
            _ => '次のシャドーイングへ',
          }),
        ),
        match: round <= 0 || played,
      ),
    ];
  }

  Future<void> passChallenge() async {
    setState(() => busy = true);
    try {
      if (!await prefs.setString(
        challengeKey(category, practiceLevel),
        dayKey(DateTime.now()),
      )) {
        throw StateError('Challenge result could not be saved');
      }
      if (mounted) {
        setState(() {
          error = null;
          challengeResult = practiceLevel < 5
              ? 'Lv.${practiceLevel + 1}を解放しました！\n称号「${skillTitle(category)}」を獲得！'
              : 'Lv.5の挑戦に合格しました！';
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = '挑戦結果を保存できませんでした');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<Widget> challengeCompletion() => [
    PracticeFinishedCard(category: category, level: practiceLevel),
    ...completionShare(),
    const SizedBox(height: 16),
    heading(challengeResult == null ? '挑戦の自己評価' : '挑戦結果'),
    const SizedBox(height: 8),
    if (challengeResult != null) ...[
      Text(challengeResult!),
      FilledButton(onPressed: back, child: const Text('スキルツリーに戻る')),
    ] else ...[
      const Text('音声の内容がわかり、聞こえた英語を追いかけて言えましたか？'),
      if (error != null) Text(error!),
      FilledButton(
        onPressed: busy ? null : passChallenge,
        child: const Text('できた'),
      ),
      OutlinedButton(
        onPressed: busy || error != null
            ? null
            : () => setState(() {
                challengeResult = '挑戦は何度でもやり直せます。';
              }),
        child: const Text('まだ難しい'),
      ),
    ],
  ];

  List<Widget> completionShare() {
    final now = DateTime.now();
    final total = todayStudy(
      [...events, ...completedChallenges],
      now,
      pending: pendingCompletion?.event,
    );
    return [
      if (total.questions >= 3 && tutorial == null) ...[
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '今日の練習：${total.questions}問完了',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          sharedThisPractice = true;
                          await showDailyStudyShare(
                            context,
                            total: total,
                            date: now,
                            category: category,
                            level: practiceLevel,
                          );
                        },
                  icon: const Icon(Icons.ios_share),
                  label: const Text('今日のがんばりをシェア'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> completion() {
    if (clips[index!].format == 'challenge') return challengeCompletion();
    return [
      PracticeFinishedCard(category: category, level: practiceLevel),
      ...completionShare(),
      const SizedBox(height: 16),
      heading('今回の手応えは？'),
      const Text('手応えを選ぶと記録を保存して、スキルツリーに戻ります。'),
      if (error != null) Text(error!),
      const SizedBox(height: 12),
      guided(
        TutorialStep.ratePractice,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final rating in PracticeRating.values)
              OutlinedButton(
                onPressed: busy ? null : () => saveCompletion(rating),
                child: Text(rating.label),
              ),
          ],
        ),
      ),
    ];
  }
}
