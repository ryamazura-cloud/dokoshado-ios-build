import 'package:dokoshado/tutorial_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a late banner relayout remeasures the highlighted controls', (
    tester,
  ) async {
    final banner = ValueNotifier(false);
    addTearDown(banner.dispose);
    final target = GlobalKey();
    Rect? highlighted;
    var observations = 0;
    Rect bounds() {
      final box = target.currentContext!.findRenderObject()! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }

    void remeasure() => WidgetsBinding.instance.addPostFrameCallback((_) {
      highlighted = bounds();
      observations++;
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: TutorialLayoutObserver(
                onChanged: remeasure,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(key: target, width: 260, height: 144),
                    ValueListenableBuilder<bool>(
                      valueListenable: banner,
                      builder: (_, visible, _) =>
                          SizedBox(height: visible ? 66 : 0, width: 320),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    remeasure();
    await tester.pump();
    final before = highlighted!;
    final count = observations;
    banner.value = true;
    await tester.pump();
    await tester.pump();
    expect(observations, greaterThan(count));
    expect(highlighted, bounds());
    expect(highlighted!.top, isNot(before.top));
    banner.value = false;
    await tester.pump();
    await tester.pump();
    expect(highlighted, before);
  });
}
