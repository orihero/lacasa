// Widget tests for `contact-sheet` (SCREENS.md §3.11).
//
// The validation copy, the success toast and the button label are all
// quoted from the spec, so these tests double as the check that three
// independent implementations still say the same words.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/contact/contact.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/theme/theme.dart';

/// Records what it was handed, or fails with a chosen error.
class _FakeContactRepository implements ContactRepository {
  _FakeContactRepository({this.error});

  final Object? error;
  final List<ContactRequest> submitted = [];

  @override
  Future<void> submit(ContactRequest request) async {
    submitted.add(request);
    if (error != null) throw error!;
  }
}

void main() {
  /// Pumps a host screen with a button that opens the sheet, and opens it.
  Future<void> pumpSheet(
    WidgetTester tester,
    _FakeContactRepository repository, {
    ContactPrefill prefill = const ContactPrefill(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showContactSheet(context, prefill: prefill),
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
  }

  Future<void> fill(WidgetTester tester, {String? name, String? phone}) async {
    if (name != null) {
      await tester.enterText(find.byType(TextField).at(0), name);
    }
    if (phone != null) {
      await tester.enterText(find.byType(TextField).at(1), phone);
    }
  }

  testWidgets('shows the spec\'s title, subtitle and button', (tester) async {
    await pumpSheet(tester, _FakeContactRepository());

    expect(find.text('Contact Us'), findsOneWidget);
    expect(find.textContaining('We welcome all your concerns'), findsOneWidget);
    expect(find.text('Send message'), findsOneWidget);
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('PHONE'), findsOneWidget);
    expect(find.text('MESSAGE'), findsOneWidget);
  });

  group('validation', () {
    testWidgets('empty fields report "Required fields are not filled"', (
      tester,
    ) async {
      final repository = _FakeContactRepository();
      await pumpSheet(tester, repository);

      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();

      expect(find.text('Required fields are not filled'), findsOneWidget);
      // The rate limiter costs 1 of 5 per minute — a locally-detectable
      // mistake must not spend one.
      expect(repository.submitted, isEmpty);
    });

    testWidgets('a bad phone reports "Invalid phone number format"', (
      tester,
    ) async {
      final repository = _FakeContactRepository();
      await pumpSheet(tester, repository);

      await fill(tester, name: 'Aziz', phone: '901234567');
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid phone number format'), findsOneWidget);
      expect(repository.submitted, isEmpty);
    });

    testWidgets('emptiness is reported before format', (tester) async {
      // An empty phone is "required", not "invalid" — the spec's order.
      final repository = _FakeContactRepository();
      await pumpSheet(tester, repository);

      await fill(tester, name: 'Aziz', phone: '');
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();

      expect(find.text('Required fields are not filled'), findsOneWidget);
      expect(find.text('Invalid phone number format'), findsNothing);
    });
  });

  testWidgets('a valid submit sends, closes, and toasts', (tester) async {
    final repository = _FakeContactRepository();
    await pumpSheet(tester, repository);

    await fill(tester, name: '  Aziz  ', phone: '+998901234567');
    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();

    expect(repository.submitted, hasLength(1));
    // Trimmed before it goes near the wire.
    expect(repository.submitted.single.name, 'Aziz');
    expect(repository.submitted.single.phone, '+998901234567');

    expect(find.text('Contact Us'), findsNothing);
    expect(find.text('Message sent successfully.'), findsOneWidget);
  });

  testWidgets('opens pre-filled from a listing', (tester) async {
    await pumpSheet(
      tester,
      _FakeContactRepository(),
      prefill: ContactPrefill.forListing(
        title: 'Bright 3-room apartment in Chilonzor',
        adId: 'ad-1001',
        agentName: 'Javlon Rustamov',
      ),
    );

    // SCREENS.md §3.7: "pre-filled with listing title + agent". Both now
    // appear twice — once in the message the user is about to send, once on
    // the `.prefill` context card above the fields — hence findsWidgets
    // rather than findsOneWidget.
    expect(
      find.textContaining('Bright 3-room apartment in Chilonzor'),
      findsWidgets,
    );
    expect(find.textContaining('Javlon Rustamov'), findsWidgets);
    expect(find.textContaining('#ad-1'), findsOneWidget);
  });

  testWidgets('a long title is truncated so the 500-char cap still fits', (
    tester,
  ) async {
    final prefill = ContactPrefill.forListing(
      title: 'A' * 300,
      adId: 'ad-1001',
      agentName: 'Javlon Rustamov',
    );

    expect(prefill.message.length, lessThanOrEqualTo(500));
    expect(prefill.message, contains('...'));
  });

  group('server failures get copy the user can act on', () {
    testWidgets('an unconfigured server does not suggest retrying', (
      tester,
    ) async {
      // 503 contact_unconfigured means nobody is wired up to receive this;
      // "try again" would be a lie.
      final repository = _FakeContactRepository(
        error: ApiErrorException(
          body: const ApiErrorBody(
            code: ApiErrorCode.contactUnconfigured,
            message: 'not configured',
          ),
          statusCode: 503,
        ),
      );
      await pumpSheet(tester, repository);

      await fill(tester, name: 'Aziz', phone: '+998901234567');
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Please call the agent directly.'),
        findsOneWidget,
      );
      // The sheet stays open with the user's input intact.
      expect(find.text('Contact Us'), findsOneWidget);
    });

    testWidgets('rate limiting says how long to wait', (tester) async {
      final repository = _FakeContactRepository(
        error: ApiErrorException(
          body: const ApiErrorBody(
            code: ApiErrorCode.rateLimited,
            message: 'slow down',
          ),
          statusCode: 429,
        ),
      );
      await pumpSheet(tester, repository);

      await fill(tester, name: 'Aziz', phone: '+998901234567');
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();

      expect(find.textContaining('try again in a minute'), findsOneWidget);
    });

    testWidgets('being offline says so', (tester) async {
      final repository = _FakeContactRepository(
        error: const NetworkException('offline'),
      );
      await pumpSheet(tester, repository);

      await fill(tester, name: 'Aziz', phone: '+998901234567');
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No connection.'), findsOneWidget);
    });

    testWidgets('a failure leaves the button usable for a second attempt', (
      tester,
    ) async {
      final repository = _FakeContactRepository(
        error: const NetworkException('offline'),
      );
      await pumpSheet(tester, repository);

      await fill(tester, name: 'Aziz', phone: '+998901234567');
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();

      expect(repository.submitted, hasLength(2));
    });
  });
}
