import 'package:flutter/material.dart';

import 'interests.dart';

class SkillCharacter extends StatelessWidget {
  const SkillCharacter({
    super.key,
    required this.category,
    required this.level,
    required this.title,
    required this.unlocked,
  }) : assert(level >= 1 && level <= 5);

  final String category;
  final int level;
  final String title;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: const Color(0xfff3efe4),
    clipBehavior: Clip.antiAlias,
    child: AspectRatio(
      aspectRatio: 3 / 5,
      child: unlocked
          ? ClipRect(
              child: FractionallySizedBox(
                widthFactor: 5,
                alignment: Alignment(-1 + (level - 1) / 2, 0),
                child: Image.asset(
                  'assets/characters/$category.webp',
                  // Each category sheet contains five equal frames in one row.
                  fit: BoxFit.fill,
                  cacheWidth: 1500,
                  semanticLabel:
                      '${interestLabel(category)} Lv.$level $titleのキャラクター',
                ),
              ),
            )
          : Semantics(
              label: 'Lv.$level 未解放のキャラクター',
              child: Icon(
                Icons.lock_outline_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
    ),
  );
}
