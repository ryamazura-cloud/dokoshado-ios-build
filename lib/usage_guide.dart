import 'package:flutter/material.dart';

const _steps = [
  (
    title: '聞き取れる英語を、少しずつ増やす',
    image: null,
    details: [
      '誰かが「Thank you」と言ったとき、文字を見なくても「ありがとう」だとわかる。そんなふうに、耳で聞いてすぐにわかる表現を少しずつ増やすのが、どこシャドの目的です。',
      '何度も耳にした表現は、音と意味が結びついて聞き取りやすくなります。シャドーイングでは、手本の音声を聞きながら、少し遅れて同じ言葉を声に出します。発音や英語の強弱、リズムもまねしてみましょう。',
      '興味のある分野の短いフレーズから始め、レベルが上がるにつれて、より長い英文に挑戦します。まず英文を見ずに聞き、英文と意味を確かめ、音読してからシャドーイングに進みます。',
      '文を覚えた直後の記憶に頼らず、耳で聞き取れるかを確かめるため、復習は学習を終えた日から3日後の午前0時に開きます。',
      '「見たらわかる英語」を「聞き慣れた英語」へ。短い文から、一つずつ練習していきましょう。',
    ],
  ),
  (
    title: 'カテゴリーの選択',
    image: '01-category',
    details: [
      'トップの「スキルツリーを見る」を押します。',
      'スキルツリー上部のカテゴリー名を押し、一覧から学びたい分野を選びます。全17カテゴリーから選べます。',
    ],
  ),
  (
    title: 'レベル・問題・復習・挑戦',
    image: '02-level',
    details: [
      '最初はLv.1から。レベルを選び、「練習 1」などの問題を押します。',
      '同じレベルの通常5問を完了すると「挑戦問題」が開きます。挑戦後の自己評価で「できた」を選ぶと、Lv.4までは次のレベルが解放されます。',
    ],
  ),
  (
    title: '初回リスニング',
    image: '03-listening',
    details: ['「再生」を押して聞いてみましょう。聞き終わったら「日本語確認へ」を押します。'],
  ),
  (
    title: '英文と日本語のすり合わせ',
    image: '04-meaning',
    details: [
      '英文と全文和訳を読み、聞こえた音がどのことばや意味に対応するかを確認します。',
      '「言い回し・文法」で聞き取れなかった表現を確かめたら、「音読へ」を押します。',
    ],
  ),
  (
    title: '音読',
    image: '05-reading',
    details: ['英文と和訳で内容を確かめ、自分のペースで3回声に出して読みます。', '3回読み終えたら「シャドーイングへ」を1回押します。'],
  ),
  (
    title: 'シャドーイング',
    image: '06-shadowing',
    details: [
      '画面が開くと音声が流れます。聞こえた英語を少し遅れて声に出し、1回ずつボタンで進めます。',
      '最初の2回は英文を見ながら練習します。後半の2回は英文が隠れ、必要なら「英文を表示」で確認できます。',
      '4回目を終えたら「学習を完了する」を押し、今回の手応えを選びます。挑戦問題の場合は「自己評価へ」を押します。',
    ],
  ),
];

const reviewTip = (
  icon: Icons.event_available_outlined,
  title: '復習は、完了日から3日後',
  text: 'この練習の目的は、耳で聞き取れる英語を増やすことです。練習直後の記憶に頼らず、音だけで意味がわかるかを確かめるため、復習は完了日から3日後の午前0時までできません。',
);
const listeningTip = (
  icon: Icons.hearing,
  title: '今の聞き取りを確かめる',
  text: '最初は英文も和訳も見ずに、今の自分がどこまで聞き取れるかを確かめます。聞こえた単語や、話の大まかな意味をつかんでみましょう。',
);
const readingTip = (
  icon: Icons.menu_book_outlined,
  title: '意味を追いながら、前へ読む',
  text: '英文を声に出しながら、英語の語順のまま意味をつかみます。文の途中で前の単語に戻らず、意味を追いながら最後まで読み進めましょう。',
);
const shadowingTip = (
  icon: Icons.record_voice_over_outlined,
  title: '話し方ごと、まねする',
  text: '手本の声をモノマネするつもりで、少し遅れて声に出します。言葉だけでなく、発音、声の上がり下がり（イントネーション）、強弱やリズムまで意識して続けましょう。',
);

const _highlights = {
  '02-level': reviewTip,
  '03-listening': listeningTip,
  '05-reading': readingTip,
  '06-shadowing': shadowingTip,
};

class UsagePage extends StatefulWidget {
  const UsagePage({super.key, this.introductionOnly = false, this.onTutorial});

  final bool introductionOnly;
  final VoidCallback? onTutorial;

  @override
  State<UsagePage> createState() => _UsagePageState();
}

class _UsagePageState extends State<UsagePage> {
  final _controller = PageController();
  int _page = 0;
  int get pageCount => widget.introductionOnly ? 1 : _steps.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void move(int offset) {
    _controller.animateToPage(
      _page + offset,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  String asset(String id) => 'assets/guide/$id.webp';

  Future<void> expand(String title, String image) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: '閉じる',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Expanded(
            child: InteractiveViewer(
              maxScale: 4,
              child: SizedBox.expand(
                child: Image.asset(
                  asset(image),
                  fit: BoxFit.contain,
                  semanticLabel: '$titleの画面例',
                ),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.all(12), child: Text('ピンチで拡大できます')),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('使い方')),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_page + 1) / pageCount),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pageCount,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  final image = step.image;
                  final highlight = _highlights[image];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    children: [
                      Text(
                        'STEP ${index + 1} / $pageCount',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (highlight != null) ...[
                        _GuideHighlight(
                          icon: highlight.icon,
                          title: highlight.title,
                          text: highlight.text,
                        ),
                        const SizedBox(height: 12),
                      ],
                      for (final detail in step.details)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: image == null ? 16 : 6,
                          ),
                          child: Text(
                            detail,
                            style: image == null
                                ? theme.textTheme.bodyLarge?.copyWith(
                                    height: 1.65,
                                  )
                                : null,
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (image == null)
                        const _ListeningIllustration()
                      else ...[
                        Center(
                          child: Semantics(
                            button: true,
                            label: '${step.title}のスクリーンショットを拡大',
                            child: InkWell(
                              onTap: () => expand(step.title, image),
                              borderRadius: BorderRadius.circular(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  asset(image),
                                  height: 400,
                                  fit: BoxFit.contain,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => expand(step.title, image),
                          icon: const Icon(Icons.zoom_in),
                          label: const Text('画面例を拡大'),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            if (widget.introductionOnly)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('あとで'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('実際の画面で試す'),
                    ),
                  ],
                ),
              )
            else ...[
              if (_page == 0 && widget.onTutorial != null)
                TextButton(
                  onPressed: widget.onTutorial,
                  child: const Text('実際の画面で試す'),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _page > 0 ? () => move(-1) : null,
                      child: const Text('前へ'),
                    ),
                    Expanded(
                      child: Text(
                        '${_page + 1} / ${_steps.length}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    FilledButton(
                      onPressed: _page == _steps.length - 1
                          ? () => Navigator.pop(context)
                          : () => move(1),
                      child: Text(_page == _steps.length - 1 ? '閉じる' : '次へ'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuideHighlight extends StatelessWidget {
  const _GuideHighlight({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        border: Border.all(color: colors.primary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onPrimaryContainer,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeningIllustration extends StatelessWidget {
  const _ListeningIllustration();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/guide/00-listening-purpose.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        semanticLabel: '短い言葉から長いフレーズへ、英語を聞き取れるようになるイラスト',
      ),
    );
  }
}
