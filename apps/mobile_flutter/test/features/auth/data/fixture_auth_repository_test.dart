// FixtureAuthRepository: the seeded-account login contract, the
// same-shape-as-live failure for unknown credentials, and the
// persist-through-TokenStorage round trip that makes currentUser()/
// updateProfile() work with no server. Exercised against
// InMemoryTokenStorage — no platform channel, no real keystore.

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/data/fixture_auth_repository.dart';

void main() {
  late InMemoryTokenStorage tokenStorage;
  late FixtureAuthRepository repository;

  setUp(() {
    tokenStorage = InMemoryTokenStorage();
    repository = FixtureAuthRepository(tokenStorage: tokenStorage);
  });

  group('login', () {
    test('signs in each seeded role with any password', () async {
      final buyer = await repository.login(
        email: 'buyer@lacasa.uz',
        password: 'anything',
      );
      expect(buyer.role, UserRole.user);

      final agent = await repository.login(
        email: 'agent@lacasa.uz',
        password: 'whatever-at-all',
      );
      expect(agent.role, UserRole.agent);
      expect(agent.realtor?.status, RealtorStatus.approved);

      final coworker = await repository.login(
        email: 'coworker@lacasa.uz',
        password: '',
      );
      expect(coworker.role, UserRole.coworker);
      expect(coworker.agentId, 'fixture-user-agent');
    });

    test('email match is case-insensitive and trims whitespace', () async {
      final user = await repository.login(
        email: '  Buyer@LaCasa.uz  ',
        password: 'x',
      );
      expect(user.role, UserRole.user);
    });

    test(
      'throws the same ApiErrorException shape the live endpoint would for '
      'an unknown email',
      () async {
        await expectLater(
          repository.login(email: 'nobody@example.com', password: 'x'),
          throwsA(
            isA<ApiErrorException>()
                .having((e) => e.code, 'code', ApiErrorCode.invalidCredentials)
                .having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      },
    );

    test('persists a session token through the injected TokenStorage', () async {
      expect(await tokenStorage.getToken(), isNull);

      await repository.login(email: 'buyer@lacasa.uz', password: 'x');

      expect(await tokenStorage.getToken(), isNotNull);
    });
  });

  group('register', () {
    test(
      'always returns role "user", even with a realtor block — approval is '
      'a separate step this fixture cannot simulate',
      () async {
        final user = await repository.register(
          fullName: 'New Agent',
          email: 'new-agent@example.com',
          password: 'secret1',
          realtor: const RealtorApplicationInput.agency(
            agencyName: 'La Casa Realty',
            teamSize: TeamSize.twoToFive,
          ),
        );

        expect(user.role, UserRole.user);
        expect(user.realtor?.status, RealtorStatus.pending);
        expect(user.realtor?.kind, RealtorKind.agency);
        expect(user.realtor?.agencyName, 'La Casa Realty');
      },
    );

    test('a buyer registration (no realtor block) has a null realtor', () async {
      final user = await repository.register(
        fullName: 'Buyer',
        email: 'buyer2@example.com',
        password: 'secret1',
      );

      expect(user.role, UserRole.user);
      expect(user.realtor, isNull);
    });
  });

  group('currentUser', () {
    test('throws unauthorized when nothing has ever been persisted', () async {
      await expectLater(
        repository.currentUser(),
        throwsA(
          isA<ApiErrorException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.unauthorized,
          ),
        ),
      );
    });

    test('returns the account a prior login persisted', () async {
      await repository.login(email: 'agent@lacasa.uz', password: 'x');

      final user = await repository.currentUser();

      expect(user.email, 'agent@lacasa.uz');
      expect(user.role, UserRole.agent);
    });

    test(
      'throws unauthorized (not a crash) for a token this fixture did not '
      'write — e.g. a real JWT left over from a live-mode build',
      () async {
        await tokenStorage.setToken('a.real.jwt-looking-string');

        await expectLater(
          repository.currentUser(),
          throwsA(
            isA<ApiErrorException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.unauthorized,
            ),
          ),
        );
      },
    );
  });

  group('updateProfile', () {
    test('merges only the provided fields onto the persisted session', () async {
      await repository.login(email: 'buyer@lacasa.uz', password: 'x');

      final updated = await repository.updateProfile(fullName: 'New Name');

      expect(updated.fullName, 'New Name');
      expect(updated.email, 'buyer@lacasa.uz'); // untouched

      final reread = await repository.currentUser();
      expect(reread.fullName, 'New Name');
    });

    test('throws unauthorized with no persisted session', () async {
      await expectLater(
        repository.updateProfile(fullName: 'X'),
        throwsA(isA<ApiErrorException>()),
      );
    });
  });

  group('signOut', () {
    test('clears the persisted token', () async {
      await repository.login(email: 'buyer@lacasa.uz', password: 'x');
      expect(await tokenStorage.getToken(), isNotNull);

      await repository.signOut();

      expect(await tokenStorage.getToken(), isNull);
    });

    test('is a no-op when nothing was signed in', () async {
      await repository.signOut();
      expect(await tokenStorage.getToken(), isNull);
    });
  });
}
