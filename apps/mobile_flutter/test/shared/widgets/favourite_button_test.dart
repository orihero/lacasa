// Covers the one behavior this widget grew on promotion out of
// features/home: the [hideForCoworker] override that lets `listing-detail`
// follow SCREENS.md §3.7's literal "shown only if role != 'agent'" text
// (which leaves the heart visible for a coworker) without changing the
// default rule every card-shaped caller (Home's rails, search results)
// still relies on — hidden for both agent and coworker.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_favourite_ad_ids_repository.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required UserRole role,
    bool hideForCoworker = true,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          FakeFavouriteAdIdsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).setRole(role);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: FavouriteButton(
              adId: 'ad-1',
              hideForCoworker: hideForCoworker,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('default hides for an agent session', (tester) async {
    await pump(tester, role: UserRole.agent);
    expect(find.byKey(const ValueKey('favourite-ad-1')), findsNothing);
  });

  testWidgets('default hides for a coworker session', (tester) async {
    await pump(tester, role: UserRole.coworker);
    expect(find.byKey(const ValueKey('favourite-ad-1')), findsNothing);
  });

  testWidgets(
    'hideForCoworker: false still hides for an agent session',
    (tester) async {
      await pump(tester, role: UserRole.agent, hideForCoworker: false);
      expect(find.byKey(const ValueKey('favourite-ad-1')), findsNothing);
    },
  );

  testWidgets(
    'hideForCoworker: false shows for a coworker session (SCREENS.md §3.7)',
    (tester) async {
      await pump(tester, role: UserRole.coworker, hideForCoworker: false);
      expect(find.byKey(const ValueKey('favourite-ad-1')), findsOneWidget);
    },
  );

  testWidgets('visible for a buyer session regardless of the flag', (
    tester,
  ) async {
    await pump(tester, role: UserRole.user);
    expect(find.byKey(const ValueKey('favourite-ad-1')), findsOneWidget);
  });
}
