// Widget tests for `language-sheet` (SCREENS.md §3.20).
//
// The sheet title and the three radio labels ("En"/"Uz"/"Ru", not the
// expanded language names) are quoted from the spec character for
// character, so these tests double as the check that three independent
// implementations still say the same words.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/features/language/language.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/fake_language_repository.dart';

void main() {
  Future<ProviderContainer> pumpSheet(
    WidgetTester tester, {
    required FakeLanguageRepository repository,
  }) async {
    final container = ProviderContainer(
      // See agents_directory_screen_test.dart for why: Riverpod 3
      // auto-retries a thrown Exception, which would make
      // repository.saved / call-count assertions non-deterministic.
      retry: (retryCount, error) => null,
      overrides: [languageRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showLanguageSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows the spec\'s title and all three radio options', (
    tester,
  ) async {
    await pumpSheet(tester, repository: FakeLanguageRepository());

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('En'), findsOneWidget);
    expect(find.text('Uz'), findsOneWidget);
    expect(find.text('Ru'), findsOneWidget);
  });

  testWidgets('is honest that only the preference, not the copy, changes', (
    tester,
  ) async {
    await pumpSheet(tester, repository: FakeLanguageRepository());

    expect(
      find.textContaining('app text is English-only for now'),
      findsOneWidget,
    );
  });

  testWidgets('the currently-saved language starts selected', (tester) async {
    await pumpSheet(
      tester,
      repository: FakeLanguageRepository(initial: AppLanguage.ru),
    );

    final ruRow = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.text('Ru'),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(ruRow.properties.selected, isTrue);

    final enRow = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.text('En'),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(enRow.properties.selected, isFalse);
  });

  group('selecting applies immediately and closes', () {
    testWidgets('tapping "Uz" persists it and closes the sheet', (
      tester,
    ) async {
      final repository = FakeLanguageRepository();
      final container = await pumpSheet(tester, repository: repository);

      await tester.tap(find.text('Uz'));
      await tester.pumpAndSettle();

      // Closed — no Apply button, no confirmation step.
      expect(find.text('Language'), findsNothing);
      expect(repository.saved, [AppLanguage.uz]);
      expect(container.read(languageProvider).value, AppLanguage.uz);
    });

    testWidgets('tapping "Ru" persists it and closes the sheet', (
      tester,
    ) async {
      final repository = FakeLanguageRepository();
      final container = await pumpSheet(tester, repository: repository);

      await tester.tap(find.text('Ru'));
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsNothing);
      expect(repository.saved, [AppLanguage.ru]);
      expect(container.read(languageProvider).value, AppLanguage.ru);
    });

    testWidgets('re-selecting the already-active language still closes', (
      tester,
    ) async {
      final repository = FakeLanguageRepository(initial: AppLanguage.en);
      await pumpSheet(tester, repository: repository);

      await tester.tap(find.text('En'));
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsNothing);
      expect(repository.saved, [AppLanguage.en]);
    });
  });

  testWidgets('the close "X" dismisses without changing the selection', (
    tester,
  ) async {
    final repository = FakeLanguageRepository(initial: AppLanguage.uz);
    await pumpSheet(tester, repository: repository);

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsNothing);
    expect(repository.saved, isEmpty);
  });

  group('layout holds at real phone widths', () {
    for (final size in const [
      (label: 'small android', size: Size(360, 800)),
      (label: 'iphone 14', size: Size(390, 844)),
      (label: 'pro max', size: Size(430, 932)),
    ]) {
      testWidgets('no overflow at ${size.label}', (tester) async {
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
        addTearDown(() => FlutterError.onError = previous);

        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpSheet(tester, repository: FakeLanguageRepository());

        expect(
          overflows,
          isEmpty,
          reason: 'RenderFlex overflow(s) at ${size.label}: $overflows',
        );
      });
    }
  });
}
