import 'dart:ui' as ui;

import 'package:dokoshado/interests.dart';
import 'package:dokoshado/main.dart';
import 'package:dokoshado/skill_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('all 17 category sheets decode into five portrait frames', (
    tester,
  ) async {
    for (final category in interestCategories) {
      final bytes = await rootBundle.load(
        'assets/characters/${category.id}.webp',
      );
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, frame.image.height * 3, reason: category.id);
        expect(frame.image.width / 5, greaterThanOrEqualTo(300));
        frame.image.dispose();
        codec.dispose();
      });
    }
  });

  testWidgets(
    'skill tree character follows category and unlocked level selection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        'tutorial.walkthroughSeen': true,
        'passed.travel.1': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: Practice(prefs)));
      await tester.ensureVisible(find.text('スキルツリーを見る'));
      await tester.tap(find.text('スキルツリーを見る'));
      await tester.pumpAndSettle();
      var character = tester.widget<SkillCharacter>(
        find.byType(SkillCharacter),
      );
      expect(character.category, 'travel');
      expect(character.level, 2);
      expect(character.unlocked, true);
      expect(character.title, '街角の聞き手');

      await tester.ensureVisible(find.text('Lv.5 ？？？'));
      await tester.tap(find.text('Lv.5 ？？？'));
      await tester.pumpAndSettle();
      character = tester.widget<SkillCharacter>(find.byType(SkillCharacter));
      expect(character.unlocked, false);
      expect(
        find.descendant(
          of: find.byType(SkillCharacter),
          matching: find.byType(Image),
        ),
        findsNothing,
      );
      expect(prefs.getBool('passed.travel.4'), isNull);

      await tester.ensureVisible(find.text('旅行/観光'));
      await tester.tap(find.text('旅行/観光'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('美容/コスメ'));
      await tester.pumpAndSettle();
      character = tester.widget<SkillCharacter>(find.byType(SkillCharacter));
      expect(character.category, 'beauty');
      expect(character.level, 1);
      expect(character.unlocked, true);
      expect(character.title, 'コスメの見習い');
      expect(tester.takeException(), isNull);
    },
  );
}
