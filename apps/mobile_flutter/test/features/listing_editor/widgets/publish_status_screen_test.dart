// Widget tests for `publish-status` (SCREENS.md §29).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_editor/listing_editor.dart';
import 'package:lacasa_mobile/features/listing_editor/state/listing_editor_repository_provider.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/widgets/status_pill.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_listing_editor_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeListingEditorRepository repository,
    String adId = 'ad-1001',
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        listingEditorRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.work,
      routes: [
        GoRoute(
          path: RoutePaths.work,
          builder: (context, state) => const Scaffold(body: Text('work-root')),
        ),
        GoRoute(
          path: RoutePaths.workPublishStatus,
          builder: (context, state) =>
              PublishStatusScreen(adId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.push(RoutePaths.workPublishStatus.replaceFirst(':id', adId));
    await tester.pumpAndSettle();

    return container;
  }

  ChannelStatus statusFor(
    Channel channel,
    PublishStatus status, {
    String? errorMessage,
    String? externalUrl,
    DateTime? lastAttemptAt,
  }) {
    return ChannelStatus(
      channel: channel,
      status: status,
      externalUrl: externalUrl,
      externalId: null,
      lastAttemptAt: lastAttemptAt,
      errorMessage: errorMessage,
    );
  }

  group('states', () {
    testWidgets(
      'renders all 4 server rows in Channel.allChannels order',
      (tester) async {
        final repository = FakeListingEditorRepository()
          ..publishStatusResult = AdPublishStatus(
            adId: 'ad-1001',
            channels: [
              for (final c in Channel.allChannels)
                statusFor(c, PublishStatus.pending),
            ],
          );
        await pumpScreen(tester, repository: repository);

        expect(find.text('Telegram'), findsOneWidget);
        expect(find.text('Instagram'), findsOneWidget);
        expect(find.text('YouTube'), findsOneWidget);
        expect(find.text('OLX'), findsOneWidget);
      },
    );

    testWidgets('a failed fetch offers Retry, which re-fetches', (
      tester,
    ) async {
      final repository = FakeListingEditorRepository()
        ..publishStatusError = const NetworkException('offline');
      await pumpScreen(tester, repository: repository);

      expect(find.text("Couldn't load publish status."), findsOneWidget);
      expect(repository.publishStatusCalls, 1);

      repository
        ..publishStatusError = null
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            for (final c in Channel.allChannels)
              statusFor(c, PublishStatus.pending),
          ],
        );
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.publishStatusCalls, 2);
      expect(find.text('Telegram'), findsOneWidget);
    });
  });

  group('OLX row', () {
    testWidgets(
      'grayed, with the short line in the meta slot and a status pill like every other row',
      (tester) async {
        final repository = FakeListingEditorRepository()
          ..publishStatusResult = AdPublishStatus(
            adId: 'ad-1001',
            channels: [
              for (final c in Channel.allChannels)
                statusFor(c, PublishStatus.pending),
            ],
          );
        await pumpScreen(tester, repository: repository);

        expect(find.text('Not available on mobile'), findsOneWidget);

        // §5's full desktop-extension sentence is deliberately NOT here. §29's
        // row is `<span class="pst__m">Not available on mobile</span>` — the
        // short line, in the same meta slot every other row uses for its
        // last-attempt stamp. The long sentence lives on the two surfaces with
        // room for it (`publish-channels-sheet` and the Publish section), which
        // have their own tests for it.
        expect(
          find.text(
            'OLX cross-posting is only available from the desktop app (requires a '
            'browser extension).',
          ),
          findsNothing,
        );

        // `<span class="pst__r"><span class="st st--mute">PENDING</span></span>`
        // — OLX carries a pill like every other row; the dimming and the meta
        // line are what say it will never publish, not a missing pill.
        // One pill per rendered row, and every channel the server sends
        // is rendered. Derived from `allChannels` rather than written as a
        // literal so this keeps tracking the wire contract if the server's
        // list ever grows.
        expect(
          find.byType(PublishStatusPill),
          findsNWidgets(Channel.allChannels.length),
        );
      },
    );
  });

  group('status pills and detail rows', () {
    testWidgets(
      'shows PUBLISHED with a View Post link when externalUrl is present',
      (tester) async {
        final repository = FakeListingEditorRepository()
          ..publishStatusResult = AdPublishStatus(
            adId: 'ad-1001',
            channels: [
              statusFor(
                Channel.telegram,
                PublishStatus.published,
                externalUrl: 'https://t.me/c/123/456',
                lastAttemptAt: DateTime.utc(2026, 8, 9, 10, 30),
              ),
              for (final c in Channel.allChannels.skip(1))
                statusFor(c, PublishStatus.pending),
            ],
          );
        await pumpScreen(tester, repository: repository);

        expect(find.text('PUBLISHED'), findsOneWidget);
        expect(find.text('View Post'), findsOneWidget);
        expect(find.textContaining('Last attempt:'), findsOneWidget);

        // No `url_launcher` in this build — tapping copies to clipboard and
        // says so, rather than silently doing nothing.
        await tester.tap(find.byKey(const ValueKey('publishStatus-viewPost')));
        await tester.pumpAndSettle();
        expect(find.text('Post link copied to clipboard.'), findsOneWidget);
      },
    );

    // **This case used to name Instagram, and had stopped meaning
    // anything.** It was written before `POST /publish/ads/:adId/:channel/
    // retry` existed, when *every* Retry was inert; Instagram is now one of
    // the two channels `_isRetryableChannel` allows, so the widget under
    // "a disabled Retry" was in fact the live `_RetryButton` — a
    // `GestureDetector` carrying the key itself, which `find.ancestor`
    // excludes, so the no-handler assertion passed by construction and the
    // tap fired a real `retryPublish` that nothing then asserted on. Every
    // assertion below is the original one, moved onto a channel that is
    // genuinely non-retryable (YouTube has no direct-publish call to
    // replay), plus the retryable half it never had.
    testWidgets('a non-retryable FAILED row shows the error message and a '
        'genuinely disabled Retry', (tester) async {
      final repository = FakeListingEditorRepository()
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            statusFor(
              Channel.youtube,
              PublishStatus.failed,
              errorMessage: 'Token expired',
            ),
            statusFor(Channel.telegram, PublishStatus.pending),
            statusFor(Channel.instagram, PublishStatus.pending),
            statusFor(Channel.olx, PublishStatus.pending),
          ],
        );
      await pumpScreen(tester, repository: repository);

      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text('Token expired'), findsOneWidget);

      final retryFinder = find.byKey(const ValueKey('publishStatus-retry'));
      expect(retryFinder, findsOneWidget);

      // "disabled" means genuinely non-interactive, not merely "still on
      // screen after a tap" (a plain `Container` with no gesture handler at
      // all was never going to navigate regardless, so that alone proves
      // nothing — see this file's own git history / the finding this
      // strengthens). Assert directly that there is no tappable widget at
      // or above the keyed one.
      expect(
        find.ancestor(
          of: retryFinder,
          matching: find.byWidgetPredicate(
            (w) => w is GestureDetector || w is InkWell,
          ),
        ),
        findsNothing,
        reason: 'the Retry affordance must not be wired to any gesture handler',
      );
      // …and the keyed widget is not itself the handler, which is exactly
      // how the Instagram version of this test went quietly vacuous.
      expect(
        retryFinder.evaluate().single.widget,
        isNot(isA<GestureDetector>()),
      );

      // Belt-and-suspenders: even if a future edit added a handler, it must
      // never re-call publish — ruling 7.3 forbids treating "Retry" as a
      // fresh publish attempt — and this channel has nothing to retry.
      await tester.tap(retryFinder);
      await tester.pumpAndSettle();
      expect(find.byType(PublishStatusScreen), findsOneWidget);
      expect(repository.publishInstagramCalls, 0);
      expect(repository.publishTelegramCalls, 0);
      expect(repository.retryPublishCalls, 0);
    });

    testWidgets('a retryable FAILED row replays that channel through the '
        'retry endpoint', (tester) async {
      final repository = FakeListingEditorRepository()
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            statusFor(
              Channel.instagram,
              PublishStatus.failed,
              errorMessage: 'Token expired',
            ),
            statusFor(Channel.telegram, PublishStatus.pending),
            statusFor(Channel.youtube, PublishStatus.pending),
            statusFor(Channel.olx, PublishStatus.pending),
          ],
        );
      await pumpScreen(tester, repository: repository);

      await tester.tap(find.byKey(const ValueKey('publishStatus-retry')));
      await tester.pumpAndSettle();

      // The retry endpoint, not a fresh publish — ruling 7.3 again, from
      // the other side.
      expect(repository.retryPublishCalls, 1);
      expect(repository.lastRetryPublishAdId, 'ad-1001');
      expect(repository.lastRetryPublishChannel, Channel.instagram);
      expect(repository.publishInstagramCalls, 0);
      expect(repository.publishTelegramCalls, 0);
    });
  });

  group('the channel name is not starved by a long status pill', () {
    testWidgets('"Instagram" stays on one line next to DRAFTED_AWAITING_REVIEW '
        'at 360dp', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // §29 has the pill quote the raw wire enum in caps, and
      // `DRAFTED_AWAITING_REVIEW` is the longest one the server can send.
      // The trailing column used to be a plain, non-flexible child: a `Row`
      // sizes those at their full intrinsic width first and only splits
      // what is left among its flexible children, so the pill took more
      // than the row had and the `Expanded` name column was laid out at the
      // clamped-to-zero remainder — "Instagram" wrapped a character per
      // line. (`Expanded` is not measured after `Flexible`; they are one
      // widget differing in `fit`, and both children here take an equal
      // share of the free space. See `_ChannelRow`'s own comment.)

      // The yardstick for "one line": what the identical `Text`, in the
      // identical style, measures with nothing squeezing it. Measured
      // rather than compared against a dp literal — this assertion used to
      // read `lessThan(26)`, and `rowTitle` is 12.75px, so under the 1.0em
      // Ahem-style font widget tests resolve, *two* lines measure 25.5dp
      // and sailed straight through the guard. It would have passed the
      // exact regression it names. Same trick the 800dp case below already
      // uses for the pill.
      final rowTitle = AppTheme.light().extension<LaCasaTypography>()!.rowTitle;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Text('Instagram', style: rowTitle),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final oneLine = tester.getSize(find.text('Instagram')).height;

      final repository = FakeListingEditorRepository()
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            statusFor(Channel.instagram, PublishStatus.draftedAwaitingReview),
          ],
        );
      await pumpScreen(tester, repository: repository);

      final name = find.text('Instagram');
      expect(name, findsOneWidget);
      expect(
        tester.getSize(name).height,
        moreOrLessEquals(oneLine, epsilon: 0.5),
        reason:
            '"Instagram" is taller in the row than it is unconstrained, so it '
            'wrapped onto a second line',
      );
    });

    testWidgets('DRAFTED_AWAITING_REVIEW still prints in full at 800dp, where '
        'the row has room for it', (tester) async {
      // A tablet, a phone in landscape, or an unfolded foldable. The phone
      // fix above must not be paid for here: half of this Row's free space
      // is ~335dp at 800dp, several times what the longest status needs, so
      // nothing should be ellipsized. A fixed `maxWidth: 120` on the
      // trailing column truncated it on every one of these.
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // The yardstick for "not truncated": what the same pill measures when
      // nothing squeezes it. Taken by measurement rather than as a literal
      // dp figure so this does not depend on which font the test host
      // resolves for `GoogleFonts.poppins`.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: PublishStatusPill(
                status: PublishStatus.draftedAwaitingReview,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final unsqueezed = tester.getSize(find.byType(PublishStatusPill)).width;
      // Guards the guard: if the longest status fitted inside the old 120dp
      // cap there would be nothing here to regress.
      expect(unsqueezed, greaterThan(120));

      final repository = FakeListingEditorRepository()
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            // YouTube carries the widest status text
            // (`DRAFTED_AWAITING_REVIEW`), which is what this test needs.
            statusFor(Channel.youtube, PublishStatus.draftedAwaitingReview),
          ],
        );
      await pumpScreen(tester, repository: repository);

      final pill = find.byType(PublishStatusPill);
      expect(pill, findsOneWidget);
      expect(
        tester.getSize(pill).width,
        moreOrLessEquals(unsqueezed, epsilon: 0.5),
        reason: 'the status pill was squeezed on a screen with room to spare',
      );
    });
  });

  group('pull-to-refresh (UX audit §9.3)', () {
    testWidgets('a pull re-fetches the channel list and repaints the pills', (
      tester,
    ) async {
      // The finding this guards: an agent opens this screen *to watch* an
      // in-flight publish. Nothing here polls and `publishStatusProvider`
      // resolves once, so before the `RefreshIndicator` landed a PENDING
      // pill could not change without killing the app.
      final repository = FakeListingEditorRepository()
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            for (final c in Channel.allChannels)
              statusFor(c, PublishStatus.pending),
          ],
        );
      await pumpScreen(tester, repository: repository);
      expect(repository.publishStatusCalls, 1);
      expect(find.text('PUBLISHED'), findsNothing);

      // The publish finished server-side while the screen sat open.
      repository.publishStatusResult = AdPublishStatus(
        adId: 'ad-1001',
        channels: [
          statusFor(
            Channel.telegram,
            PublishStatus.published,
            lastAttemptAt: DateTime.utc(2026, 8, 9, 10, 30),
          ),
          for (final c in Channel.allChannels.skip(1))
            statusFor(c, PublishStatus.pending),
        ],
      );

      await tester.fling(
        find.byKey(const ValueKey('publishStatus-refresh')),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repository.publishStatusCalls, 2);
      expect(find.text('PUBLISHED'), findsOneWidget);
    });
  });

  group('disabled states keep their explanation legible (UX audit §10.5)', () {
    testWidgets('the OLX row dims its brand tile and name but not the line '
        'that explains the dimming', (tester) async {
      final repository = FakeListingEditorRepository()
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            for (final c in Channel.allChannels)
              statusFor(c, PublishStatus.pending),
          ],
        );
      await pumpScreen(tester, repository: repository);

      // The channel name is the part that means "this one is off", so it
      // is the part that fades.
      final dimmedName = tester.widgetList<Opacity>(
        find.ancestor(of: find.text('OLX'), matching: find.byType(Opacity)),
      );
      expect(
        dimmedName.any((o) => o.opacity < 1),
        isTrue,
        reason: 'the OLX channel name should still read as switched off',
      );

      // The reason must not be. The whole card used to sit under one
      // `Opacity(0.55)`, which took `muted` (3.75:1 on white) down to
      // roughly 1.9:1 — on the only sentence that says why the row is
      // grayed at all.
      final reason = find.byKey(const ValueKey('publishStatus-olxReason'));
      expect(reason, findsOneWidget);
      final overReason = tester.widgetList<Opacity>(
        find.ancestor(of: reason, matching: find.byType(Opacity)),
      );
      expect(
        overReason.every((o) => o.opacity == 1),
        isTrue,
        reason: 'the explanation of a disabled row must not itself be dimmed',
      );
      expect(
        tester.widget<Text>(reason).style?.color,
        AppTheme.light().extension<LaCasaColors>()!.ink2,
        reason:
            'the explanation carries the row\'s information now, so it '
            'takes `ink2` rather than `muted`',
      );
    });

    testWidgets('a non-retryable FAILED row states "disabled" in semantics '
        'instead of only fading', (tester) async {
      final repository = FakeListingEditorRepository()
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            statusFor(
              Channel.youtube,
              PublishStatus.failed,
              errorMessage: 'The upload was rejected.',
            ),
            for (final c in Channel.allChannels.where(
              (c) => c != Channel.youtube,
            ))
              statusFor(c, PublishStatus.pending),
          ],
        );
      await pumpScreen(tester, repository: repository);

      final retry = find.byKey(const ValueKey('publishStatus-retry'));
      expect(retry, findsOneWidget);

      // `Opacity` says nothing to a screen reader, which is half of what
      // §10.5 is about; the nearest enclosing `Semantics` now does.
      final semantics = tester.widget<Semantics>(
        find.ancestor(of: retry, matching: find.byType(Semantics)).first,
      );
      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.enabled, isFalse);

      // And it is no longer a faded copy of the live control: `Opacity(0.5)`
      // over `muted` was under 2:1 on the one word naming what is
      // unavailable.
      final overPill = tester.widgetList<Opacity>(
        find.ancestor(of: retry, matching: find.byType(Opacity)),
      );
      expect(overPill.every((o) => o.opacity == 1), isTrue);
    });
  });

  group('layout holds at real phone widths', () {
    const phones = <String, Size>{
      'small android 360x800': Size(360, 800),
      'iphone 14 390x844': Size(390, 844),
      'pro max 430x932': Size(430, 932),
    };

    phones.forEach((label, size) {
      testWidgets('no overflow at $label', (tester) async {
        final overflows = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.exceptionAsString();
          if (text.contains('overflowed')) {
            overflows.add(text.split('\n').first);
          }
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = previous;
        });

        final repository = FakeListingEditorRepository()
          ..publishStatusResult = AdPublishStatus(
            adId: 'ad-1001',
            channels: [
              statusFor(
                Channel.telegram,
                PublishStatus.failed,
                errorMessage:
                    'The bot could not deliver this message to one or more configured channels.',
                lastAttemptAt: DateTime.utc(2026, 8, 9, 10, 30),
              ),
              statusFor(
                Channel.instagram,
                PublishStatus.published,
                externalUrl: 'https://instagram.com/p/abcdefghijklmnop',
                lastAttemptAt: DateTime.utc(2026, 8, 9, 10, 30),
              ),
              // YouTube carries the widest status text, so this sweep
              // exercises the longest pill at every phone width.
              statusFor(Channel.youtube, PublishStatus.draftedAwaitingReview),
              statusFor(Channel.olx, PublishStatus.pending),
            ],
          );
        await pumpScreen(tester, repository: repository);

        FlutterError.onError = previous;
        expect(
          overflows,
          isEmpty,
          reason: 'overflow at $label:\n${overflows.join('\n')}',
        );
      });
    });
  });
}
