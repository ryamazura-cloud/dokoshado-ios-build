import 'package:flutter/material.dart';

/// A loaded banner can relayout the page without rebuilding the tutorial owner.
class TutorialLayoutObserver extends StatelessWidget {
  const TutorialLayoutObserver({
    super.key,
    required this.onChanged,
    required this.child,
  });
  final VoidCallback onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          onChanged();
          return false;
        },
        child: SizeChangedLayoutNotifier(child: child),
      );
}
