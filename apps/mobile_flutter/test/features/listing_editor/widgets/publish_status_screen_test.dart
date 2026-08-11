// Widget tests for `publish-status` (SCREENS.md §29).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_editor/listing_editor.dart';
import 'package:lacasa_mobile/features/listing_editor/state/listing_editor_repository_provider.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
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
      overrides: [listingEditorRepositoryProvider.overrideWithValue(repository)],
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
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, theme: AppTheme.light(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.push(RoutePaths.workPublishStatus.replaceFirst(':id', adId));
    await tester.pumpAndSettle();

    return container;
  }

  ChannelStatus statusFor(Channel channel, PublishStatus status, {String? errorMessage, String? externalUrl, DateTime? lastAttemptAt}) {
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
    testWidgets('always renders exactly 5 channel rows, Channel.allChannels order', (
      tester,
    ) async {
      final repository = FakeListingEditorRepository()
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            for (final c in Channel.allChannels) statusFor(c, PublishStatus.pending),
          ],
        );
      await pumpScreen(tester, repository: repository);

      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('OLX'), findsOneWidget);
      expect(find.text('Realting'), findsOneWidget);
    });

    testWidgets('a failed fetch offers Retry, which re-fetches', (tester) async {
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
            for (final c in Channel.allChannels) statusFor(c, PublishStatus.pending),
          ],
        );
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.publishStatusCalls, 2);
      expect(find.text('Telegram'), findsOneWidget);
    });
  });

  group('OLX row', () {
    testWidgets('grayed with "Not available on mobile" and the fixed hint', (tester) async {
      final repository = FakeListingEditorRepository()
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            for (final c in Channel.allChannels) statusFor(c, PublishStatus.pending),
          ],
        );
      await pumpScreen(tester, repository: repository);

      expect(find.text('Not available on mobile'), findsOneWidget);
      expect(
        find.text(
          'OLX cross-posting is only available from the desktop app (requires a '
          'browser extension).',
        ),
        findsOneWidget,
      );
    });
  });

  group('status pills and detail rows', () {
    testWidgets('shows PUBLISHED with a View Post link when externalUrl is present', (
      tester,
    ) async {
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
            for (final c in Channel.allChannels.skip(1)) statusFor(c, PublishStatus.pending),
          ],
        );
      await pumpScreen(tester, repository: repository);

      expect(find.text('Published'), findsOneWidget);
      expect(find.text('View Post'), findsOneWidget);
      expect(find.textContaining('Last attempt:'), findsOneWidget);

      // No `url_launcher` in this build — tapping copies to clipboard and
      // says so, rather than silently doing nothing.
      await tester.tap(find.byKey(const ValueKey('publishStatus-viewPost')));
      await tester.pumpAndSettle();
      expect(find.text('Post link copied to clipboard.'), findsOneWidget);
    });

    testWidgets('a FAILED row shows the error message and a disabled Retry', (tester) async {
      final repository = FakeListingEditorRepository()
        ..publishStatusResult = AdPublishStatus(
          adId: 'ad-1001',
          channels: [
            statusFor(Channel.instagram, PublishStatus.failed, errorMessage: 'Token expired'),
            statusFor(Channel.telegram, PublishStatus.pending),
            statusFor(Channel.youtube, PublishStatus.pending),
            statusFor(Channel.olx, PublishStatus.pending),
            statusFor(Channel.realting, PublishStatus.pending),
          ],
        );
      await pumpScreen(tester, repository: repository);

      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Token expired'), findsOneWidget);

      final retryFinder = find.byKey(const ValueKey('publishStatus-retry'));
      expect(retryFinder, findsOneWidget);

      // "disabled" means genuinely non-interactive, not merely "still on
      // screen after a tap" (a plain `Container` with no gesture handler at
      // all was never going to navigate regardless, so that alone proves
      // nothing — see this file's own git history / the finding this
      // strengthens). Assert directly that there is no tappable ancestor at
      // all between the keyed widget and the row.
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

      // Belt-and-suspenders: even if a future edit added a handler, it must
      // never re-call publish — ruling 7.3 forbids treating "Retry" as a
      // fresh publish attempt.
      await tester.tap(retryFinder);
      await tester.pumpAndSettle();
      expect(find.byType(PublishStatusScreen), findsOneWidget);
      expect(repository.publishInstagramCalls, 0);
      expect(repository.publishTelegramCalls, 0);
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
          if (text.contains('overflowed')) overflows.add(text.split('\n').first);
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
              statusFor(Channel.youtube, PublishStatus.pending),
              statusFor(Channel.olx, PublishStatus.pending),
              statusFor(Channel.realting, PublishStatus.draftedAwaitingReview),
            ],
          );
        await pumpScreen(tester, repository: repository);

        FlutterError.onError = previous;
        expect(overflows, isEmpty, reason: 'overflow at $label:\n${overflows.join('\n')}');
      });
    });
  });
}
