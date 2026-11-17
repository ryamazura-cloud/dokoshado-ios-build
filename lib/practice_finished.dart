import 'package:flutter/material.dart';

import 'skill_character.dart';

class PracticeFinishedCard extends StatelessWidget {
  const PracticeFinishedCard({
    super.key,
    required this.category,
    required this.level,
  });

  final String category;
  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: 220,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 138,
                      height: 138,
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(
                      height: 144,
                      child: SkillCharacter(
                        category: category,
                        level: level,
                        title: '',
                        unlocked: true,
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: 4,
                      child: CircleAvatar(
                        radius: 23,
                        backgroundColor: colors.primary,
                        child: Icon(
                          Icons.check_rounded,
                          color: colors.onPrimary,
                          size: 32,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 18,
                      child: Icon(
                        Icons.auto_awesome,
                        color: colors.primary,
                        size: 28,
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 12,
                      child: Icon(
                        Icons.star_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                    ),
                    Positioned(
                      left: 36,
                      bottom: 15,
                      child: Icon(
                        Icons.star_rounded,
                        color: colors.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '1問、おつかれさまでした！',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '聞いて、声に出す練習をやりきりました。',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
