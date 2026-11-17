typedef Clip = ({
  String file,
  String category,
  int level,
  String format,
  String voice,
  double seconds,
  String english,
  String japanese,
  List<(String, String)> notes,
});
const clips = <Clip>[
  (
    file: 'travel-01',
    category: 'travel',
    level: 1,
    format: 'dialogue',
    voice: 'af_heart',
    seconds: 3.95,
    english: "Excuse me, could you show me where the nearest train station is?",
    japanese: "すみません、最寄りの駅がどこか教えてもらえますか？",
    notes: [
      ("Could you show me ...?", "道を尋ねるときの丁寧な頼み方。show me の後ろに、知りたい内容を続けます。"),
      (
        "where the nearest train station is",
        "間接疑問では where の後ろが「主語＋動詞」の語順になります。where is the station? との違いを確認しましょう。",
      ),
    ],
  ),
  (
    file: 'travel-02',
    category: 'travel',
    level: 1,
    format: 'dialogue',
    voice: 'am_michael',
    seconds: 4.20,
    english: "I'd like to check in. My reservation is under Miller.",
    japanese: "チェックインをお願いします。ミラーの名前で予約しています。",
    notes: [
      (
        "I'd like to check in.",
        "I'd like to ＋動詞は、したいことを丁寧に伝える言い方です。check in は宿泊や搭乗の受付をすること。",
      ),
      (
        "My reservation is under Miller.",
        "予約名を伝えるときの定番。under ＋名字で「〜の名前で登録されている」を表します。",
      ),
    ],
  ),
  (
    file: 'travel-03',
    category: 'travel',
    level: 1,
    format: 'dialogue',
    voice: 'af_bella',
    seconds: 4.50,
    english:
        "Is there a bus that goes straight to the airport? I have two bags.",
    japanese: "空港まで直行するバスはありますか？ 荷物が2つあります。",
    notes: [
      (
        "Is there a bus ...?",
        "そのようなバスがあるかを尋ねる形です。Is there ...? は店や設備の有無にも使えます。",
      ),
      (
        "that goes straight to the airport",
        "that 以下が a bus を説明します。go straight to は、ここでは「乗り換えなしで〜へ行く」の意味です。",
      ),
    ],
  ),
  (
    file: 'travel-04',
    category: 'travel',
    level: 1,
    format: 'narration',
    voice: 'am_adam',
    seconds: 4.38,
    english: "The museum opens at ten and closes at five every day.",
    japanese: "博物館は毎日10時に開館し、5時に閉館します。",
    notes: [
      (
        "opens at ten / closes at five",
        "開館・閉館のような決まった時刻は、現在形で案内できます。具体的な時刻の前には at を使います。",
      ),
      ("every day", "「毎日」を表す副詞句。every の後ろの day は単数形です。"),
    ],
  ),
  (
    file: 'travel-05',
    category: 'travel',
    level: 1,
    format: 'narration',
    voice: 'af_heart',
    seconds: 3.75,
    english: "The next train leaves from platform four in five minutes.",
    japanese: "次の電車は5分後に4番ホームから出発します。",
    notes: [
      (
        "leaves from platform four",
        "leave from ＋場所は「〜から出発する」。ホーム番号は platform の後ろに置きます。",
      ),
      ("in five minutes", "今から5分後の意味。ここでの in は、動作が起きるまでの時間を示します。"),
    ],
  ),
  (
    file: 'travel-06',
    category: 'travel',
    level: 2,
    format: 'dialogue',
    voice: 'am_michael',
    seconds: 7.13,
    english: "Could we leave our bags here for a couple of hours after we check out? Our train does not leave until three.",
    japanese: "チェックアウトしたあと、ここで荷物を2時間ほど預かってもらえますか？ 電車は3時まで出ないんです。",
    notes: [
      (
        "Could we leave our bags here?",
        "leave は「出発する」のほかに「物を置いていく」の意味があります。この場面では荷物を預けたいという依頼です。",
      ),
      (
        "does not leave until three",
        "not ... until は「〜までは…しない」。3時より前には出発しない、という時間の下限を伝えています。",
      ),
    ],
  ),
  (
    file: 'travel-07',
    category: 'travel',
    level: 2,
    format: 'dialogue',
    voice: 'af_bella',
    seconds: 7.42,
    english: "I think we are on the wrong bus. Does this one stop anywhere near the old town, or should we get off here and walk?",
    japanese: "バスを間違えたかもしれません。このバスは旧市街の近くに停まりますか？ それともここで降りて歩いたほうがいいですか？",
    notes: [
      (
        "on the wrong bus",
        "バス・電車・飛行機に乗っているときは一般に on を使います。wrong は、行き先に対して「違う」という意味です。",
      ),
      (
        "Does this one stop ...?",
        "this one は乗っているバスを指し、同じ名詞の繰り返しを避けています。get off は乗り物から「降りる」です。",
      ),
    ],
  ),
  (
    file: 'travel-08',
    category: 'travel',
    level: 2,
    format: 'dialogue',
    voice: 'am_adam',
    seconds: 5.90,
    english: "Do I need to book a table, or can I just show up around seven? It is just me and my sister.",
    japanese: "席を予約したほうがいいですか？ それとも7時ごろに直接行っても大丈夫ですか？ 姉妹と私の2人だけです。",
    notes: [
      ("book a table", "レストランの席を予約する定番表現。book はここでは動詞です。"),
      (
        "just show up around seven",
        "show up は「その場に現れる」。この文では予約せず直接行く意味で、around は時刻が目安であることを表します。",
      ),
    ],
  ),
  (
    file: 'travel-09',
    category: 'travel',
    level: 2,
    format: 'narration',
    voice: 'af_heart',
    seconds: 8.20,
    english: "The ferry runs every half hour. You can buy tickets at the little booth by the pier. It closes just before the last departure.",
    japanese: "フェリーは30分おきに出ます。チケットは桟橋そばの小さな売り場で買えます。売り場は最終便の出発直前に閉まります。",
    notes: [
      (
        "runs every half hour",
        "乗り物が「運行する」ときにも run を使います。every half hour は30分間隔です。",
      ),
      (
        "the little booth by the pier",
        "booth は小さな窓口や売り場。by は「〜のそば」で、続く文の It はフェリーではなく売り場を指しています。",
      ),
    ],
  ),
  (
    file: 'travel-10',
    category: 'travel',
    level: 2,
    format: 'narration',
    voice: 'am_michael',
    seconds: 6.13,
    english: "The walking tour starts in the main square. Look for a guide with a bright yellow umbrella.",
    japanese: "徒歩ツアーは中央広場から出発します。鮮やかな黄色い傘を持ったガイドを探してください。",
    notes: [
      (
        "starts in the main square",
        "square は形の「正方形」のほか、町の「広場」も指します。ツアーが始まる場所を in で示しています。",
      ),
      (
        "Look for a guide with ...",
        "look for は「探す」、look at は「見る」。with 以下が、ガイドを見分ける目印です。",
      ),
    ],
  ),
  (
    file: 'travel-11',
    category: 'travel',
    level: 3,
    format: 'dialogue',
    voice: 'af_bella',
    seconds: 7.47,
    english: "We booked a room with two beds, but this one only has one. Would you mind checking if there's another room available?",
    japanese: "ベッド2台の部屋を予約しましたが、この部屋には1台しかありません。別の空き部屋がないか調べていただけますか？",
    notes: [
      (
        "this one only has one",
        "最初の one は部屋、後ろの one はベッドを指します。同じ語でも、前後の文脈で指すものが変わります。",
      ),
      (
        "Would you mind checking if ...?",
        "「〜かどうか調べていただけますか」という丁寧な依頼。mind の後ろは動詞の -ing 形です。",
      ),
    ],
  ),
  (
    file: 'travel-12',
    category: 'travel',
    level: 3,
    format: 'dialogue',
    voice: 'am_adam',
    seconds: 6.97,
    english: "Our flight got pushed back, so we might not make the last train. Do you know what a taxi usually costs from the airport?",
    japanese: "便が遅れたので、終電に間に合わないかもしれません。空港からタクシーに乗ると、普段はいくらくらいかかりますか？",
    notes: [
      ("got pushed back", "get ＋過去分詞で、ここでは便が「後ろの時刻にずらされた」ことを表します。"),
      (
        "make the last train",
        "make はこの場面では「間に合う」。might not は「〜できないかもしれない」と可能性を伝えます。",
      ),
    ],
  ),
  (
    file: 'travel-13',
    category: 'travel',
    level: 3,
    format: 'dialogue',
    voice: 'af_heart',
    seconds: 6.92,
    english: "I'm looking for somewhere quiet where we can grab a bite. It doesn't have to be fancy, just somewhere the locals like.",
    japanese: "軽く食べられる静かな場所を探しています。しゃれた店でなくてもいいので、地元の人が好む店がいいです。",
    notes: [
      ("grab a bite", "「軽く何かを食べる」というくだけた言い回し。grab a bite to eat とも言えます。"),
      (
        "It doesn't have to be fancy.",
        "don't have to は「〜する必要はない」。fancy はここでは店がしゃれていたり高級だったりすることです。",
      ),
    ],
  ),
  (
    file: 'travel-14',
    category: 'travel',
    level: 3,
    format: 'narration',
    voice: 'am_michael',
    seconds: 8.93,
    english: "The trail gets steep after the second bridge. If you're short on time, turn left there and take the shorter loop back to the parking lot.",
    japanese: "2つ目の橋を過ぎると道が急になります。時間がなければ、そこで左に曲がり、短い周回コースで駐車場に戻ってください。",
    notes: [
      ("short on time", "short on ＋名詞で「〜が足りない」。時間に余裕がない旅行者に向けた案内です。"),
      (
        "take the shorter loop back",
        "loop は一周して戻るルート。shorter は複数のコースを比べて短いほうを指します。",
      ),
    ],
  ),
  (
    file: 'travel-15',
    category: 'travel',
    level: 3,
    format: 'narration',
    voice: 'af_bella',
    seconds: 8.57,
    english: "The market is busiest right around lunchtime. If you'd rather avoid the crowds, go early and start at the entrance on the river side.",
    japanese: "市場はちょうど昼食どきが一番混みます。混雑を避けたいなら、早めに行って川側の入口から入りましょう。",
    notes: [
      (
        "right around lunchtime",
        "around は「〜ごろ」、right を添えると「ちょうどそのあたり」と強調できます。",
      ),
      (
        "If you'd rather avoid the crowds",
        "would rather ＋動詞の原形は「できれば〜したい」。希望に合わせて別の行き方を提案する形です。",
      ),
    ],
  ),
  (
    file: 'travel-16',
    category: 'travel',
    level: 4,
    format: 'dialogue',
    voice: 'am_adam',
    seconds: 9.65,
    english: "I know the tour is supposed to be nonrefundable, but the airline canceled our flight this morning. Is there any chance you could move our booking to Friday instead?",
    japanese:
        "返金不可のツアーなのは承知していますが、今朝、航空会社が便を欠航にしました。予約を金曜日に振り替えていただける可能性はありますか？",
    notes: [
      (
        "is supposed to be nonrefundable",
        "be supposed to はここでは「規則上〜ということになっている」。nonrefundable は返金不可です。",
      ),
      (
        "Is there any chance you could ...?",
        "例外対応を相談する丁寧な言い回し。move the booking to Friday は予約を金曜日に移すことです。",
      ),
    ],
  ),
  (
    file: 'travel-17',
    category: 'travel',
    level: 4,
    format: 'dialogue',
    voice: 'af_heart',
    seconds: 8.80,
    english: "I was charged for breakfast on both days, but we only ate here on Sunday. Would you mind taking a look at the bill before you run my card?",
    japanese: "2日分の朝食代が請求されていますが、ここで食べたのは日曜日だけです。カード決済の前に明細を確認していただけますか？",
    notes: [
      (
        "I was charged for breakfast",
        "be charged for ＋品目で「〜の代金を請求される」。請求した人より、請求内容に焦点を当てる受け身です。",
      ),
      (
        "before you run my card",
        "run a card はカード決済を処理する言い方。before 以下は確認を済ませてほしい期限を示します。",
      ),
    ],
  ),
  (
    file: 'travel-18',
    category: 'travel',
    level: 4,
    format: 'dialogue',
    voice: 'am_michael',
    seconds: 10.57,
    english: "We're thinking of renting a car for the day, but I've heard parking downtown can be a nightmare. Would we be better off taking the train and walking from the station?",
    japanese:
        "1日だけレンタカーを借りようかと思っていますが、中心部では駐車がかなり大変だと聞きました。電車で行って駅から歩くほうがいいでしょうか？",
    notes: [
      (
        "parking downtown can be a nightmare",
        "nightmare は比喩で「ひどく大変なこと」。can be は、いつもそうとは限らない可能性を表します。",
      ),
      (
        "Would we be better off taking the train?",
        "be better off ＋動詞の -ing 形は「〜したほうが都合がよい」。選択肢を比較するときに使います。",
      ),
    ],
  ),
  (
    file: 'travel-19',
    category: 'travel',
    level: 4,
    format: 'narration',
    voice: 'af_bella',
    seconds: 11.40,
    english: "The coastal road is closed north of the lighthouse because of last night's storm. Drivers headed to the harbor should follow the orange signs and allow an extra twenty minutes.",
    japanese: "昨夜の嵐のため、灯台より北の海岸道路は通行止めです。港へ向かう車はオレンジ色の標識に従い、所要時間に20分余裕を見てください。",
    notes: [
      (
        "Drivers headed to the harbor",
        "headed to は「〜へ向かっている」。Drivers who are headed to ... の who are が省略された形です。",
      ),
      (
        "allow an extra twenty minutes",
        "allow は「許す」のほか、時間を「見込む」の意味があります。通常より20分多く見ておく案内です。",
      ),
    ],
  ),
  (
    file: 'travel-20',
    category: 'travel',
    level: 4,
    format: 'narration',
    voice: 'am_adam',
    seconds: 10.72,
    english: "Your timed ticket gets you into the exhibition, but it doesn't include the rooftop terrace. On clear days, the staff release a limited number of terrace passes at the front desk.",
    japanese: "時間指定券で展示には入れますが、屋上テラスは対象外です。晴れた日には、受付でテラスの入場券を枚数限定で配布します。",
    notes: [
      (
        "gets you into the exhibition",
        "get ＋人＋into ＋場所で「人がその場所に入れるようにする」。ここではチケットで入場できる範囲を示します。",
      ),
      (
        "a limited number of terrace passes",
        "a limited number of は「数に限りのある」。pass はここでは追加の入場券を指します。",
      ),
    ],
  ),
  (
    file: 'travel-21',
    category: 'travel',
    level: 5,
    format: 'dialogue',
    voice: 'af_heart',
    seconds: 12.30,
    english: "I realize the original fare didn't include changes, but the schedule change was on your end. If there's no room on the morning flight, could you put us on standby and hold our seats on the evening one?",
    japanese: "元の運賃では変更できないことは承知していますが、時刻を変更したのはそちらです。朝の便に空席がなければ、空席待ちに登録して夕方の便の席を押さえていただけますか？",
    notes: [
      ("on your end", "「そちら側で」という会話表現。話し手は、変更が航空会社側で起きたことを伝えています。"),
      (
        "put us on standby",
        "standby は空席待ち。put ＋人＋on standby で登録すること、hold our seats で席を押さえることを表します。",
      ),
    ],
  ),
  (
    file: 'travel-22',
    category: 'travel',
    level: 5,
    format: 'dialogue',
    voice: 'am_michael',
    seconds: 13.68,
    english: "We'd love to join the boat trip, but one of us gets seasick pretty easily. If the water's rough and you switch to the shorter route, do we still get to stop at the island, or do we stay on board the whole time?",
    japanese: "船のツアーにぜひ参加したいのですが、同行者の一人が船酔いしやすいんです。波が荒くて短いルートに変わっても、島には立ち寄りますか？ それともずっと船に乗ったままですか？",
    notes: [
      (
        "one of us gets seasick",
        "one of us は「私たちのうちの一人」なので、動詞は単数に合わせて gets です。",
      ),
      (
        "do we still get to stop ...?",
        "get to ＋動詞は「〜する機会がある」。still を加えて、ルート変更後も立ち寄れるか聞いています。",
      ),
    ],
  ),
  (
    file: 'travel-23',
    category: 'travel',
    level: 5,
    format: 'dialogue',
    voice: 'af_bella',
    seconds: 13.40,
    english: "Before we book the apartment, I just want to make sure we're reading the cancellation policy right. If we cancel exactly a week before check-in, do we get the full amount back, or is the cleaning fee still taken out?",
    japanese: "アパートを予約する前に、キャンセル規定の読み方が合っているか確認したいです。チェックインのちょうど1週間前に取り消した場合、全額戻りますか？ それとも清掃料は差し引かれますか？",
    notes: [
      (
        "make sure we're reading ... right",
        "make sure は「確かめる」。right はここでは「正しく」で、規定の解釈を確認しています。",
      ),
      (
        "is the cleaning fee still taken out?",
        "take out はこの場面では金額を「差し引く」。受け身で、清掃料が返金額から引かれるかを尋ねています。",
      ),
    ],
  ),
  (
    file: 'travel-24',
    category: 'travel',
    level: 5,
    format: 'narration',
    voice: 'am_adam',
    seconds: 14.70,
    english: "Although the downtown shuttle usually stops outside the station, it's picking up passengers across the street while the entrance is being repaved. If you have a suitcase, use the crosswalk at the lights rather than trying to cross right in front of the station.",
    japanese: "中心街行きのシャトルは普段は駅の前に停まりますが、入口の舗装工事中は通りの向かい側で乗車できます。スーツケースがある方は、駅の真ん前で渡らず信号のある横断歩道をご利用ください。",
    notes: [
      (
        "while the entrance is being repaved",
        "is being ＋過去分詞は、今行われている作業を表す進行形の受け身。repave は舗装し直すことです。",
      ),
      (
        "rather than trying to cross ...",
        "rather than は「〜する代わりに」。at the lights の lights は信号を指します。",
      ),
    ],
  ),
  (
    file: 'travel-25',
    category: 'travel',
    level: 5,
    format: 'narration',
    voice: 'af_heart',
    seconds: 14.05,
    english: "The overlook is open year-round, but visibility changes quickly in the mountains. If you can't see the ridge from the visitor center, wait for the next weather update before heading up, since the shuttle back only runs once an hour.",
    japanese: "展望台は通年利用できますが、山では視界がすぐに変わります。ビジターセンターから尾根が見えなければ、上る前に次の気象情報を待ってください。帰りのシャトルは1時間に1本しかありません。",
    notes: [
      ("open year-round", "year-round は「一年中」。季節限定ではない施設やサービスの案内に使えます。"),
      (
        "since the shuttle back only runs once an hour",
        "since はここでは時点ではなく理由を示します。once an hour は「1時間に1回」です。",
      ),
    ],
  ),
];
