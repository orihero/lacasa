// AuthSessionNotifier: the three commands (signInWithPassword,
// registerAccount, signOut), their failure paths, and startup restore —
// both halves (`hasPersistedAuthTokenProvider`'s gate and the bounded async
// validation it triggers). No widget pumping needed: this is plain
// Notifier/ProviderContainer state, following
// test/features/agents/agent_profile_screen_test.dart's `retry: null`
// convention for a deterministic single attempt per thrown error.
//
// `fake_async` (used by the timeout test below) is a real, resolved
// transitive dependency (pulled in by flutter_test itself) rather than
// something this file adds — but it is not a *direct* dependency in
// pubspec.yaml, which this task is not allowed to touch, hence the ignore.
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/state/auth_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';

import 'support/auth_test_data.dart';
import 'support/fake_auth_repository.dart';

void main() {
  ProviderContainer buildContainer({
    required FakeAuthRepository repository,
    bool hasPersistedAuthToken = false,
  }) {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        hasPersistedAuthTokenProvider.overrideWithValue(hasPersistedAuthToken),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('default state', () {
    test('starts fully signed out with no repository calls', () {
      final repo = FakeAuthRepository();
      final container = buildContainer(repository: repo);

      final state = container.read(authSessionProvider);

      expect(state.isSignedIn, isFalse);
      expect(state.role, isNull);
      expect(state.user, isNull);
      expect(state.isRestoring, isFalse);
      expect(repo.currentUserCallCount, 0);
    });
  });

  group('signInWithPassword', () {
    test('applies the returned user on success', () async {
      final repo = FakeAuthRepository(
        loginResult: authUser(email: 'agent@lacasa.uz', role: UserRole.agent),
      );
      final container = buildContainer(repository: repo);

      await container
          .read(authSessionProvider.notifier)
          .signInWithPassword(email: 'agent@lacasa.uz', password: 'x');

      final state = container.read(authSessionProvider);
      expect(state.isSignedIn, isTrue);
      expect(state.role, UserRole.agent);
      expect(state.canAccessWork, isTrue);
      expect(repo.loginCallCount, 1);
    });

    test(
      'propagates ApiErrorException unchanged, leaving the session signed '
      'out — never swallowed into a bool',
      () async {
        final repo = FakeAuthRepository(
          loginError: ApiErrorException(
            body: const ApiErrorBody(
              code: ApiErrorCode.invalidCredentials,
              message: 'Invalid email or password',
            ),
            statusCode: 401,
          ),
        );
        final container = buildContainer(repository: repo);
        final notifier = container.read(authSessionProvider.notifier);

        await expectLater(
          notifier.signInWithPassword(email: 'a@example.com', password: 'x'),
          throwsA(
            isA<ApiErrorException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.invalidCredentials,
            ),
          ),
        );
        expect(container.read(authSessionProvider).isSignedIn, isFalse);
      },
    );
  });

  group('registerAccount', () {
    test(
      'applies the returned user — role "user" even for a realtor signup',
      () async {
        final repo = FakeAuthRepository(
          registerResult: authUser(email: 'new@example.com'),
        );
        final container = buildContainer(repository: repo);

        await container
            .read(authSessionProvider.notifier)
            .registerAccount(
              fullName: 'New Person',
              email: 'new@example.com',
              password: 'secret1',
              realtor: const RealtorApplicationInput.solo(),
            );

        final state = container.read(authSessionProvider);
        expect(state.isSignedIn, isTrue);
        expect(state.role, UserRole.user);
        expect(repo.registerCallCount, 1);
      },
    );

    test('propagates a 409 emailTaken failure, session stays signed out', () async {
      final repo = FakeAuthRepository(
        registerError: ApiErrorException(
          body: const ApiErrorBody(
            code: ApiErrorCode.emailTaken,
            message: 'Email is already registered',
          ),
          statusCode: 409,
        ),
      );
      final container = buildContainer(repository: repo);
      final notifier = container.read(authSessionProvider.notifier);

      await expectLater(
        notifier.registerAccount(
          fullName: 'X',
          email: 'taken@example.com',
          password: 'secret1',
        ),
        throwsA(isA<ApiErrorException>()),
      );
      expect(container.read(authSessionProvider).isSignedIn, isFalse);
    });
  });

  group('signOut', () {
    test('clears the session and calls through to the repository', () async {
      final repo = FakeAuthRepository(
        loginResult: authUser(role: UserRole.agent),
      );
      final container = buildContainer(repository: repo);
      final notifier = container.read(authSessionProvider.notifier);
      await notifier.signInWithPassword(email: 'a@example.com', password: 'x');
      expect(container.read(authSessionProvider).isSignedIn, isTrue);

      await notifier.signOut();

      expect(container.read(authSessionProvider).isSignedIn, isFalse);
      expect(repo.signOutCallCount, 1);
    });

    test(
      'a failed token clear still drops the session, and still rethrows',
      () async {
        // The realistic failure: a corrupted keystore makes
        // flutter_secure_storage's delete throw. Both halves of signOut's
        // documented contract are asserted here, because each guards a
        // different thing — the clear stops a user who asked to sign out
        // from being left looking at their own account, and the rethrow is
        // the only signal that a surviving token may sign them back in.
        final repo = FakeAuthRepository(
          loginResult: authUser(role: UserRole.agent),
          signOutError: Exception('keystore unavailable'),
        );
        final container = buildContainer(repository: repo);
        final notifier = container.read(authSessionProvider.notifier);
        await notifier.signInWithPassword(
          email: 'a@example.com',
          password: 'x',
        );

        await expectLater(notifier.signOut(), throwsA(isA<Exception>()));

        final state = container.read(authSessionProvider);
        expect(state.isSignedIn, isFalse);
        // Not just the role — a stale AuthUser would leak the previous
        // person's name, email and phone to whoever holds the device next.
        expect(state.user, isNull);
        expect(state.canAccessWork, isFalse);
      },
    );
  });

  group('setRole (test/preview escape hatch)', () {
    test('flips role without touching the repository', () {
      final repo = FakeAuthRepository();
      final container = buildContainer(repository: repo);

      container.read(authSessionProvider.notifier).setRole(UserRole.coworker);

      final state = container.read(authSessionProvider);
      expect(state.role, UserRole.coworker);
      expect(state.isCoworker, isTrue);
      expect(repo.loginCallCount + repo.currentUserCallCount, 0);
    });
  });

  group('startup restore', () {
    test(
      'hasPersistedAuthTokenProvider defaulting to false (unoverridden) '
      'never attempts a restore',
      () {
        final repo = FakeAuthRepository();
        // No override at all — proves the *default*, not just `false`
        // passed explicitly by buildContainer above.
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final state = container.read(authSessionProvider);

        expect(state.isSignedIn, isFalse);
        expect(state.isRestoring, isFalse);
        expect(repo.currentUserCallCount, 0);
      },
    );

    test(
      'a persisted token that validates signs the session in asynchronously',
      () async {
        final repo = FakeAuthRepository(
          currentUserResult: authUser(role: UserRole.agent),
        );
        final container = buildContainer(
          repository: repo,
          hasPersistedAuthToken: true,
        );

        // First read: build() has fired but the microtask hasn't run yet.
        final initial = container.read(authSessionProvider);
        expect(initial.isSignedIn, isFalse);
        expect(initial.isRestoring, isTrue);

        await pumpEventQueue();

        final restored = container.read(authSessionProvider);
        expect(restored.isSignedIn, isTrue);
        expect(restored.role, UserRole.agent);
        expect(restored.isRestoring, isFalse);
        expect(repo.currentUserCallCount, 1);
      },
    );

    test(
      'a dead token (401 unauthorized) settles to signed out and clears '
      'the stored token via signOut()',
      () async {
        final repo = FakeAuthRepository(
          currentUserError: ApiErrorException(
            body: const ApiErrorBody(
              code: ApiErrorCode.unauthorized,
              message: 'Invalid or expired token',
            ),
            statusCode: 401,
          ),
        );
        final container = buildContainer(
          repository: repo,
          hasPersistedAuthToken: true,
        );

        // First read is what triggers `build()` — and with it the
        // fire-and-forget restore microtask — exactly like the "validates"
        // test above. Pumping before this first read would pump an event
        // queue `authSessionProvider` hasn't even started using yet, so the
        // read below would return the just-started (`isRestoring: true`)
        // state instead of the settled one.
        container.read(authSessionProvider);
        await pumpEventQueue();

        final state = container.read(authSessionProvider);
        expect(state.isSignedIn, isFalse);
        expect(state.isRestoring, isFalse);
        expect(repo.signOutCallCount, 1);
      },
    );

    test(
      'a network failure settles to signed out WITHOUT clearing the stored '
      'token — it might still be valid once connectivity returns',
      () async {
        final repo = FakeAuthRepository(
          currentUserError: const NetworkException('Could not connect'),
        );
        final container = buildContainer(
          repository: repo,
          hasPersistedAuthToken: true,
        );

        // See the "dead token" test above for why this first read has to
        // come before the pump.
        container.read(authSessionProvider);
        await pumpEventQueue();

        final state = container.read(authSessionProvider);
        expect(state.isSignedIn, isFalse);
        expect(repo.signOutCallCount, 0);
      },
    );

    test(
      'a restore that never resolves times out and settles to signed out, '
      'without a real multi-second wait (package:fake_async)',
      () {
        fakeAsync((async) {
          final repo = FakeAuthRepository(currentUserHold: Completer<void>());
          final container = buildContainer(
            repository: repo,
            hasPersistedAuthToken: true,
          );

          // Triggers build(), which schedules the restore microtask.
          container.read(authSessionProvider);
          async.elapse(const Duration(seconds: 30));

          final state = container.read(authSessionProvider);
          expect(state.isSignedIn, isFalse);
          expect(state.isRestoring, isFalse);
          // A timeout is not an ApiErrorException, so the (possibly still
          // good) token is left alone.
          expect(repo.signOutCallCount, 0);
        });
      },
    );
  });
}
