// Covers the one thing [TapTarget] exists to guarantee and the one thing
// it must not break: the HIT box is at least 48dp on every axis, and the
// PAINTED child keeps whatever size the mockup gave it. Asserting only the
// widget's own size would pass for a design that simply scaled the artwork
// up to 48dp — which is the wrong fix and visibly off-mockup — so the tests
// below check both halves, plus an actual tap landing in the transparent
// padding between them (the region that used to fall through to whatever
// sat underneath, e.g. a listing card's own onTap).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/shared/shared.dart';

void main() {
  const probeKey = ValueKey('tapTarget-probe');
  const childKey = ValueKey('tapTarget-child');

  Future<int Function()> pumpProbe(
    WidgetTester tester, {
    required Widget child,
    double minSize = TapTarget.minimumSize,
  }) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TapTarget(
              key: probeKey,
              semanticsLabel: 'Probe',
              minSize: minSize,
              onTap: () => taps++,
              child: child,
            ),
          ),
        ),
      ),
    );
    return () => taps;
  }

  const smallChild = SizedBox(
    key: childKey,
    width: 28,
    height: 28,
    child: ColoredBox(color: Color(0xFFFF0000)),
  );

  testWidgets('a 28dp child gets a 48dp hit box and stays 28dp painted', (
    tester,
  ) async {
    await pumpProbe(tester, child: smallChild);

    expect(tester.getSize(find.byKey(probeKey)), const Size(48, 48));
    expect(tester.getSize(find.byKey(childKey)), const Size(28, 28));
  });

  testWidgets(
    'a tap in the transparent padding — outside the paint, inside the box — '
    'still fires onTap',
    (tester) async {
      final taps = await pumpProbe(tester, child: smallChild);

      // 20dp diagonally out from the centre: past the 28dp child's 14dp
      // half-extent, still inside the 48dp box's 24dp one. Under the old
      // bare GestureDetector-around-the-artwork this point was a miss.
      await tester.tapAt(
        tester.getCenter(find.byKey(probeKey)) + const Offset(20, 20),
      );
      await tester.pump();

      expect(taps(), 1);
    },
  );

  testWidgets('a tap outside the 48dp box does not fire onTap', (tester) async {
    final taps = await pumpProbe(tester, child: smallChild);

    await tester.tapAt(
      tester.getCenter(find.byKey(probeKey)) + const Offset(30, 30),
    );
    await tester.pump();

    expect(taps(), 0);
  });

  testWidgets('a child already larger than the floor is not shrunk to it', (
    tester,
  ) async {
    await pumpProbe(
      tester,
      child: const SizedBox(key: childKey, width: 120, height: 56),
    );

    expect(tester.getSize(find.byKey(probeKey)), const Size(120, 56));
  });

  testWidgets('it shrink-wraps rather than swallowing a loose parent', (
    tester,
  ) async {
    // The Center above hands down loose 800x600 constraints. Without
    // widthFactor/heightFactor the inner Center would expand to all of it
    // and every TapTarget in a Row or Column would eat the whole line.
    await pumpProbe(tester, child: smallChild);

    expect(tester.getSize(find.byKey(probeKey)), const Size(48, 48));
  });

  testWidgets('it exposes one labelled, activatable button node', (
    tester,
  ) async {
    // Disposed inline at the end of the body, not via addTearDown:
    // `WidgetTester._endOfTestVerifications` asserts every SemanticsHandle
    // is already released, and it runs inside the test body — before any
    // tearDown the test package registered.
    final handle = tester.ensureSemantics();

    // A Text child would carry its own semantics node; TapTarget excludes
    // it so a screen reader announces the control once, under the label the
    // caller chose, rather than twice. Excluding the subtree also takes the
    // inner GestureDetector's tap action with it, which is why the node
    // must declare its own — a label with no action is not a button.
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TapTarget(
              key: probeKey,
              semanticsLabel: 'Probe',
              onTap: () => taps++,
              child: const Text('Probe', key: childKey),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byKey(probeKey)),
      isSemantics(label: 'Probe', isButton: true, hasTapAction: true),
    );
    // Exactly one node carries the label, so the excluded Text really is
    // gone rather than merely out-ranked.
    expect(find.semantics.byLabel('Probe'), findsOne);

    tester.semantics.tap(find.semantics.byLabel('Probe'));
    await tester.pump();
    expect(taps, 1);

    handle.dispose();
  });

  testWidgets('minSize is honoured when a caller lowers the floor', (
    tester,
  ) async {
    await pumpProbe(tester, child: smallChild, minSize: 36);

    expect(tester.getSize(find.byKey(probeKey)), const Size(36, 36));
  });
}
