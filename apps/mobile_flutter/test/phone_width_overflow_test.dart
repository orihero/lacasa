// Guards the app against overflowing at real phone widths.
//
// Worth knowing why this exists rather than a screenshot check: the web build's
// Flutter canvas does not reliably adopt Chrome's --window-size, so browser
// screenshots at a phone viewport show clipping that is an artifact of the
// canvas rather than a layout fault. Pinning tester.view.physicalSize is
// authoritative instead — Flutter records a FlutterError for every
// RenderFlex/RenderBox overflow during layout, which this test collects.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/app.dart';

/// The narrow end (small Android), a common mid (iPhone 13/14), and the wide
/// end (iPhone Pro Max) of the phone range the app actually targets.
const _phones = <String, Size>{
  'small android 360x800': Size(360, 800),
  'iphone 14 390x844': Size(390, 844),
  'pro max 430x932': Size(430, 932),
};

void main() {
  _phones.forEach((label, size) {
    testWidgets('no overflow at $label', (tester) async {
      final overflows = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('overflowed')) {
          overflows.add(text.split('\n').first);
        } else {
          previous?.call(details);
        }
      };

      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = previous;
      });

      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(
        overflows,
        isEmpty,
        reason: 'overflow at $label:\n${overflows.join('\n')}',
      );
    });
  });
}
