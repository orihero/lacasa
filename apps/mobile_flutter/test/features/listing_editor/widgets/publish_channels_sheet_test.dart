// Widget tests for `publish-channels-sheet` (SCREENS.md §28).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_editor/listing_editor.dart';
import 'package:lacasa_mobile/features/listing_editor/state/listing_editor_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_listing_editor_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<
    ({ProviderContainer container, FakeListingEditorRepository repository})
  >
  pumpSheet(
    WidgetTester tester, {
    FakeListingEditorRepository? repository,
    List<int> tgChatIds = const [],
    Ad? ad,
  }) async {
    final repo = repository ?? FakeListingEditorRepository();
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [listingEditorRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    if (tgChatIds.isNotEmpty) {
      container.read(authSessionProvider.notifier).signIn(
        AuthUser.fromJson({
          'id': 'agent-1',
          'fullName': 'Javlon Rustamov',
          'email': 'javlon@lacasa.uz',
          'role': 'agent',
          'phoneNumber': null,
          'avatar': null,
          'agentId': null,
          'tgChatIds': tgChatIds,
          'igAccounts': const <Map<String, dynamic>>[],
          'igAssistConsentAt': null,
          'realtor': null,
        }),
      );
    }

    final theAd = ad ?? testAd();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showPublishChannelsSheet(context, ad: theAd),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return (container: container, repository: repo);
  }

  group('Instagram section', () {
    testWidgets('shows the no-account-connected hint when nothing is connected', (
      tester,
    ) async {
      await pumpSheet(tester, repository: FakeListingEditorRepository());

      expect(
        find.text(
          'No Instagram account is connected. You can connect one in '
          'Settings, or draft the post yourself.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('lists each connected account as a checkbox row', (tester) async {
      final repository = FakeListingEditorRepository()
        ..instagramAccountsResult = const [
          ConnectedInstagramAccount(
            igUserId: 'ig-1',
            username: 'lacasa.realty',
            expiresAt: null,
            profilePictureUrl: null,
            mediaCount: null,
            followersCount: null,
            followsCount: null,
          ),
        ];
      await pumpSheet(tester, repository: repository);

      expect(find.text('lacasa.realty'), findsOneWidget);
      expect(find.byKey(const ValueKey('publishChannelsSheet-ig-ig-1')), findsOneWidget);
    });
  });

  group('Telegram section', () {
    testWidgets('shows a no-channel-connected note when tgChatIds is empty', (tester) async {
      await pumpSheet(tester);

      expect(find.text('No Telegram channel is connected.'), findsOneWidget);
    });

    testWidgets('lists one row per connected chat id, labelled by its raw id', (tester) async {
      await pumpSheet(tester, tgChatIds: const [111, 222]);

      expect(find.text('Telegram channel #111'), findsOneWidget);
      expect(find.text('Telegram channel #222'), findsOneWidget);
    });
  });

  group('OLX row', () {
    testWidgets('always visible, disabled, with the fixed hint (SCREENS.md §5)', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(find.text('OLX'), findsOneWidget);
      expect(
        find.text(
          'OLX cross-posting is only available from the desktop app (requires a '
          'browser extension).',
        ),
        findsOneWidget,
      );
    });
  });

  group('Publish button (SCREENS.md §5)', () {
    testWidgets('disabled when nothing is selected', (tester) async {
      final repository = FakeListingEditorRepository()
        ..instagramAccountsResult = const [
          ConnectedInstagramAccount(
            igUserId: 'ig-1',
            username: 'lacasa.realty',
            expiresAt: null,
            profilePictureUrl: null,
            mediaCount: null,
            followersCount: null,
            followsCount: null,
          ),
        ];
      await pumpSheet(tester, repository: repository);

      await tester.tap(find.byKey(const ValueKey('publishChannelsSheet-publish')));
      await tester.pumpAndSettle();

      expect(repository.publishInstagramCalls, 0);
    });

    testWidgets('selecting an Instagram account enables Publish and fans out one call', (
      tester,
    ) async {
      final repository = FakeListingEditorRepository()
        ..instagramAccountsResult = const [
          ConnectedInstagramAccount(
            igUserId: 'ig-1',
            username: 'lacasa.realty',
            expiresAt: null,
            profilePictureUrl: null,
            mediaCount: null,
            followersCount: null,
            followsCount: null,
          ),
        ];
      await pumpSheet(tester, repository: repository);

      await tester.tap(find.byKey(const ValueKey('publishChannelsSheet-ig-ig-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('publishChannelsSheet-publish')));
      await tester.pumpAndSettle();

      expect(repository.publishInstagramCalls, 1);
      expect(repository.lastPublishInstagramIgUserIds, ['ig-1']);
      expect(repository.publishTelegramCalls, 0);
      expect(find.text('Instagram post published!'), findsOneWidget);
    });

    testWidgets('a failed attempt shows the failed-usernames toast', (tester) async {
      final repository = FakeListingEditorRepository()
        ..instagramAccountsResult = const [
          ConnectedInstagramAccount(
            igUserId: 'ig-1',
            username: 'lacasa.realty',
            expiresAt: null,
            profilePictureUrl: null,
            mediaCount: null,
            followersCount: null,
            followsCount: null,
          ),
        ]
        ..instagramResultsOk = false;
      await pumpSheet(tester, repository: repository);

      await tester.tap(find.byKey(const ValueKey('publishChannelsSheet-ig-ig-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('publishChannelsSheet-publish')));
      await tester.pumpAndSettle();

      expect(find.text('Instagram publish failed for lacasa.realty'), findsOneWidget);
    });

    testWidgets('selecting a Telegram chat fans out publishTelegram with that chat id', (
      tester,
    ) async {
      final repository = FakeListingEditorRepository();
      await pumpSheet(tester, repository: repository, tgChatIds: const [555]);

      await tester.tap(find.byKey(const ValueKey('publishChannelsSheet-tg-555')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('publishChannelsSheet-publish')));
      await tester.pumpAndSettle();

      expect(repository.publishTelegramCalls, 1);
      expect(repository.lastPublishTelegramChatIds, ['555']);
      expect(repository.publishInstagramCalls, 0);
      expect(find.text('Telegram post published!'), findsOneWidget);
    });
  });

  group('Cancel', () {
    testWidgets('closes without publishing anything', (tester) async {
      final repository = FakeListingEditorRepository()
        ..instagramAccountsResult = const [
          ConnectedInstagramAccount(
            igUserId: 'ig-1',
            username: 'lacasa.realty',
            expiresAt: null,
            profilePictureUrl: null,
            mediaCount: null,
            followersCount: null,
            followsCount: null,
          ),
        ];
      await pumpSheet(tester, repository: repository);

      await tester.tap(find.byKey(const ValueKey('publishChannelsSheet-ig-ig-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('publishChannelsSheet-cancel')));
      await tester.pumpAndSettle();

      expect(repository.publishInstagramCalls, 0);
      expect(find.text('Select the channels you want to publish to!'), findsNothing);
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
          ..instagramAccountsResult = const [
            ConnectedInstagramAccount(
              igUserId: 'ig-1',
              username: 'lacasa.realty',
              expiresAt: null,
              profilePictureUrl: null,
              mediaCount: null,
              followersCount: null,
              followsCount: null,
            ),
          ];
        await pumpSheet(
          tester,
          repository: repository,
          tgChatIds: const [111, 222],
        );

        FlutterError.onError = previous;
        expect(overflows, isEmpty, reason: 'overflow at $label:\n${overflows.join('\n')}');
      });
    });
  });
}
