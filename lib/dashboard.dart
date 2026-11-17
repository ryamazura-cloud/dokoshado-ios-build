import 'package:flutter/material.dart';

enum PracticeRating {
  great('ばっちり'),
  okay('まあまあ'),
  hard('難しかった');

  const PracticeRating(this.label);

  final String label;
}

enum TicketKind { daily, bonus }

typedef StudyEvent = ({
  DateTime when,
  int seconds,
  bool difficultReview,
  PracticeRating? rating,
  TicketKind? ticket,
});
typedef QuestClaim = ({String key, DateTime when});

String dayLabel(DateTime date) => '${date.year}/${date.month}/${date.day}';
DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

List<StudyEvent> studyEvents(List<String> values) {
  StudyEvent event(
    int stamp,
    int seconds,
    bool difficultReview, [
    PracticeRating? rating,
    TicketKind? ticket,
  ]) => (
    when: DateTime.fromMillisecondsSinceEpoch(stamp),
    seconds: seconds,
    difficultReview: difficultReview,
    rating: rating,
    ticket: ticket,
  );
  if (values.length == 2) return [event(int.parse(values.first), 0, false)];
  return [
    for (final record in values.skip(2))
      switch (record.split('|')) {
        [final stamp, final seconds, final reviewed] => event(
          int.parse(stamp),
          int.parse(seconds),
          reviewed == '1',
        ),
        [final stamp, final seconds, final reviewed, final rating] => event(
          int.parse(stamp),
          int.parse(seconds),
          reviewed == '1',
          PracticeRating.values.byName(rating),
        ),
        [
          final stamp,
          final seconds,
          final reviewed,
          final rating,
          final ticket,
        ] =>
          event(
            int.parse(stamp),
            int.parse(seconds),
            reviewed == '1',
            rating.isEmpty ? null : PracticeRating.values.byName(rating),
            TicketKind.values.byName(ticket),
          ),
        _ => throw const FormatException('Invalid study event'),
      },
  ];
}

String encodeStudyEvent(StudyEvent event) =>
    '${event.when.millisecondsSinceEpoch}|${event.seconds}|${event.difficultReview ? 1 : 0}'
    '${event.ticket == null ? (event.rating == null ? '' : '|${event.rating!.name}') : '|${event.rating?.name ?? ''}|${event.ticket!.name}'}';

const questRewards = <String, int>{
  'first': 10,
  'five': 20,
  'ten': 30,
  'review': 20,
  'three-days': 80,
  'five-days': 120,
};

int rewardForClaim(QuestClaim claim) =>
    questRewards[claim.key.split('|').last] ?? 0;

int ticketRewardForQuest(String key) =>
    const {'ten', 'three-days', 'five-days'}.contains(key.split('|').last)
    ? 1
    : 0;

typedef Quest = ({
  String key,
  String title,
  String description,
  int value,
  int goal,
  int reward,
  bool claimed,
  bool weekly,
});

List<Quest> questsFor(
  List<StudyEvent> events,
  Set<String> claimed,
  DateTime now,
) {
  final today = _day(now);
  final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
  final daily = events.where((event) => _day(event.when) == today);
  final weeklyDays = events
      .map((event) => _day(event.when))
      .where((day) => !day.isBefore(monday) && !day.isAfter(today))
      .toSet()
      .length;
  Quest quest(
    String id,
    String title,
    String description,
    int value,
    int goal, {
    bool weekly = false,
  }) {
    final key = '${dayLabel(weekly ? monday : today)}|$id';
    return (
      key: key,
      title: title,
      description: description,
      value: value,
      goal: goal,
      reward: questRewards[id]!,
      claimed: claimed.contains(key),
      weekly: weekly,
    );
  }

  final dailyQuests = [
    quest('first', 'はじめの一歩', '今日、1問を完了しよう', daily.length, 1),
    quest('five', '耳と声の練習', '今日、2問を完了しよう。復習も対象です', daily.length, 2),
    quest(
      'review',
      '苦手を味方に',
      '「まあまあ」または「難しかった」を付けた問題を、今日1問復習しよう',
      daily.where((event) => event.difficultReview).length,
      1,
    ),
  ];
  return [
    ...dailyQuests,
    quest(
      'ten',
      'シャドーイングの特訓',
      'ほかの今日のクエストをすべて達成しよう',
      dailyQuests.where((quest) => quest.value >= quest.goal).length,
      dailyQuests.length,
    ),
    quest('three-days', '今週の冒険', '今週、3日学習しよう', weeklyDays, 3, weekly: true),
    quest('five-days', '今週の大冒険', '今週、5日学習しよう', weeklyDays, 5, weekly: true),
  ];
}

class QuestPage extends StatefulWidget {
  const QuestPage({
    super.key,
    required this.quests,
    required this.claim,
    this.showTutorial = false,
  });
  final List<Quest> quests;
  final Future<bool> Function(Quest quest) claim;
  final bool showTutorial;

  @override
  State<QuestPage> createState() => _QuestPageState();
}

class _QuestPageState extends State<QuestPage> {
  final rewardAnchor = GlobalKey();
  final scroll = ScrollController();
  String? guidedReward;
  bool receivedReward = false;

  @override
  void initState() {
    super.initState();
    if (!widget.showTutorial) return;
    guidedReward = widget.quests
        .where((quest) => !quest.claimed && quest.value >= quest.goal)
        .firstOrNull
        ?.key;
    if (guidedReward != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = rewardAnchor.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(target, alignment: 0.3);
        }
      });
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<bool> claim(Quest quest) async {
    final saved = await widget.claim(quest);
    if (mounted && saved && widget.showTutorial && guidedReward != null) {
      setState(() {
        guidedReward = null;
        receivedReward = true;
      });
      if (scroll.hasClients) {
        scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    }
    return saved;
  }

  @override
  Widget build(BuildContext context) {
    final guideBack = widget.showTutorial && guidedReward == null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('クエスト'),
        leading: guideBack
            ? const Padding(
                padding: EdgeInsets.all(5),
                child: _QuestHighlight(child: BackButton()),
              )
            : null,
      ),
      body: SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (guideBack)
              _QuestHint(
                text: receivedReward ? '経験値を受け取りました。左上の矢印を押して、トップに戻りましょう。' : '達成したクエストの報酬を受け取ると、共通レベルの経験値が増えます。今は受け取れる報酬がないので、左上の矢印でトップに戻りましょう。',
              )
            else
              const Text('クエストを達成し、報酬を受け取ると共通EXPが増えます。'),
            for (final weekly in [false, true]) ...[
              const SizedBox(height: 16),
              Text(
                weekly ? '今週のクエスト' : '今日のクエスト',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final quest in widget.quests.where(
                (q) => q.weekly == weekly,
              ))
                _QuestCard(
                  quest: quest,
                  claim: claim,
                  rewardAnchor: quest.key == guidedReward ? rewardAnchor : null,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestHint extends StatelessWidget {
  const _QuestHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 21),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _QuestHighlight extends StatelessWidget {
  const _QuestHighlight({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xff2684e8), width: 3),
    ),
    child: Padding(padding: const EdgeInsets.all(4), child: child),
  );
}

class _QuestCard extends StatefulWidget {
  const _QuestCard({
    required this.quest,
    required this.claim,
    this.rewardAnchor,
  });
  final GlobalKey? rewardAnchor;
  final Quest quest;
  final Future<bool> Function(Quest quest) claim;

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard> {
  bool saving = false;
  bool received = false;

  Future<void> receive() async {
    setState(() => saving = true);
    final saved = await widget.claim(widget.quest);
    if (!mounted) return;
    setState(() {
      received = saved;
      saving = false;
    });
    if (!saved) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('報酬を保存できませんでした。')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quest;
    final rewardButton = FilledButton(
      onPressed: saving ? null : receive,
      child: const Text('報酬を受け取る'),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.title, style: Theme.of(context).textTheme.titleMedium),
            Text(q.description),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (q.value / q.goal).clamp(0, 1)),
            const SizedBox(height: 6),
            Text(
              '${q.value.clamp(0, q.goal)} / ${q.goal}　・　報酬 ${q.reward} EXP'
              '${ticketRewardForQuest(q.key) > 0 ? ' ＋ 追加チケット1枚' : ''}',
            ),
            if (ticketRewardForQuest(q.key) > 0)
              const Text('「報酬を受け取る」でEXPと追加チケットを受け取れます。'),
            if (q.claimed || received)
              const Text('受け取り済み')
            else if (q.value >= q.goal)
              if (widget.rewardAnchor case final anchor?) ...[
                const _QuestHint(
                  text: '「報酬を受け取る」を押しましょう。クエストを達成すると、共通レベルの経験値がもらえます。',
                ),
                _QuestHighlight(key: anchor, child: rewardButton),
              ] else
                rewardButton,
          ],
        ),
      ),
    );
  }
}
