typedef Completion = ({int stamp, int count});

const practiceXp = 10;

const commonTitleMilestones = <int, String>{
  1: '音の旅人',
  5: '聞き取りの見習い',
  10: 'フレーズの聞き手',
  15: '音の冒険者',
  20: 'リズムの騎士',
  30: '音の魔導士',
  40: '聞き分けの賢者',
  50: '世界を聴く旅人',
  60: '音の大魔導士',
  70: '聞き取りの導き手',
  80: '世界の声を聴く賢者',
  90: '音の英雄',
  100: '伝説の聞き手',
};

const _categoryTitles = <String, List<String>>{
  'beauty': ['コスメの見習い', '彩りの聞き手', '美肌の探究者', '輝きの仕立て屋', '美の錬金術師'],
  'health': ['健康初心者', '健やかの聞き手', '健康の探究者', 'いのちの守り手', '健康の賢者'],
  'food': ['料理好き', '味の聞き手', '香りの料理人', '美食の案内人', '食卓の魔術師'],
  'fashion': ['おしゃれの卵', '装いの聞き手', '着こなしの職人', '流行の仕掛け人', '装いの創造主'],
  'entertainment': ['推し活の新人', '話題の聞き手', 'エンタメ通', '熱狂の仕掛け人', '舞台裏の賢者'],
  'lifestyle': ['一人暮し初心者', '日々の工夫家', '心地よさの職人', '暮らしの演出家', '日常の錬金術師'],
  'parenting': ['見守りの芽', '笑顔の聞き手', '子育ての伴走者', '安心の守り手', '家族の太陽'],
  'learning': ['高い知的好奇心', '知識の聞き手', 'ひらめきの使い手', '知恵の探究者', '学びの大賢者'],
  'relationships': ['ときめきの旅人', '心の聞き上手', '想いの橋渡し', '絆の紡ぎ手', '愛の理解者'],
  'pets': ['もふもふ見習い', 'しっぽの聞き手', 'お世話の達人', '心をつなぐ相棒', 'どうぶつの賢者'],
  'games': ['物語の旅人', 'クエストの挑戦者', 'セリフの聞き手', '世界を渡る勇者', '伝説の冒険王'],
  'business': ['新入社員', '段取りの聞き手', '交渉の戦略家', 'チームの導き手', '未来の開拓者'],
  'travel': ['旅じたく中', '街角の聞き手', '国境を渡る旅人', '世界の案内人', '七つの海の冒険家'],
  'cars': ['ドライブ見習い', '街道の聞き手', 'ハンドルの職人', '大地の探検家', '走りのマイスター'],
  'gadgets': ['スイッチの見習い', '便利の発見者', 'ガジェットの聞き手', '電脳の探検家', '未来の発明家'],
  'sports': ['ウォームアップ隊員', '作戦の聞き手', '技の磨き手', '勝利の戦略家', '限界を超える覇者'],
  'money': ['節約家', '家計の聞き手', 'お金の計画家', '資産の航海士', '未来を築く賢者'],
};

final _commonThresholds = List<int>.unmodifiable([
  0,
  20,
  50,
  90,
  140,
  for (var level = 6; level <= 100; level++) 140 + (level - 5) * 60,
]);
const _categoryThresholds = [0, 10, 30, 60, 100];
final _commonTitles = List<String>.unmodifiable([
  for (var level = 1; level <= _commonThresholds.length; level++)
    commonTitleMilestones.entries
        .lastWhere((entry) => entry.key <= level)
        .value,
]);

class Growth {
  Growth(this.xp, {String? category})
    : thresholds = category == null ? _commonThresholds : _categoryThresholds,
      titles = category == null ? _commonTitles : _categoryTitles[category]!;

  final int xp;
  final List<int> thresholds;
  final List<String> titles;

  int levelAt(int value) =>
      thresholds.lastIndexWhere((threshold) => threshold <= value) + 1;
  int get level => levelAt(xp);
  String get title => titles[level - 1];
  bool get maxed => level == thresholds.length;
  int get remaining => maxed ? 0 : thresholds[level] - xp;
  double get fraction =>
      maxed ? 1 : 1 - remaining / (thresholds[level] - thresholds[level - 1]);
  int? get nextTitleLevel {
    for (var next = level + 1; next <= titles.length; next++) {
      if (titles[next - 1] != title) return next;
    }
    return null;
  }

  String get summary => 'Lv. $level  $title  ·  $xp EXP';
}
