// Smoke test: the app boots — theme, go_router shell, and the Home tab's
// real feed screen all render — without throwing. Superseded in depth by
// test/navigation/tab_shell_test.dart (back-stack/role-gating behavior) and
// test/features/home/home_feed_screen_test.dart (the Home feed's own
// content/loading/error/favourite-gating behavior).
//
// Updated alongside lib/features/home/: the Home tab root is now
// HomeFeedScreen, not PlaceholderScreen, so the old `screen-Home` key this
// test asserted on no longer exists — this file's own header comment
// invited exactly that replacement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/app.dart';
import 'package:lacasa_mobile/features/home/home.dart';

void main() {
  testWidgets('App boots, shows the shell scaffold and the Home feed screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.byType(HomeFeedScreen), findsOneWidget);
  });
}
