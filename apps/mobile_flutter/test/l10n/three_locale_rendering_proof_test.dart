// Proof that the three ARB locales (en/uz/ru) actually render through real
// screens — not just that `app_en.arb`/`app_uz.arb`/`app_ru.arb` exist and
// parse. Every assertion below pumps a real widget with `locale:` forced to
// each of the three, and checks the *visible* text differs across locales
// and is never silently the English fallback for uz/ru (the failure mode a
// missing/mistyped ARB key produces: `flutter gen-l10n` degrades a missing
// translation to the template value with no build-time signal).
//
// Three shapes, per the integration task that added this file:
// - a plural (`listingRoomsCount`, map-view's pin-preview rooms count —
//   English distinguishes one/other, Russian needs one/few/many/other,
//   Uzbek doesn't inflect at all — see `lib/l10n/GLOSSARY.md`'s `room` row)
// - a placeholder (`settingsAboutRowSubtitle`, "Version {version}")
// - a form's validation messages (`edit-profile`'s required-field and
//   phone-format errors, SCREENS.md §18)
//
// `language_sheet_test.dart`'s 'selecting a language changes the live app
// locale, no restart needed' test already proves the *switch* mechanism
// (the provider → `MaterialApp.locale` wiring). This file is the
// complementary proof that the *content* behind that switch is real.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/state/auth_repository_provider.dart';
import 'package:lacasa_mobile/features/edit_profile/edit_profile.dart';
import 'package:lacasa_mobile/features/language/language.dart';
import 'package:lacasa_mobile/features/map_view/widgets/map_preview_card.dart';
import 'package:lacasa_mobile/features/settings/settings.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../features/edit_profile/support/recording_auth_repository.dart';
import '../features/language/support/fake_language_repository.dart';
import '../features/map_view/support/map_test_ads.dart';
import '../features/settings/support/fake_notifications_preference_repository.dart';

void main() {
  group('plural — map-view pin preview rooms count (listingRoomsCount)', () {
    Future<void> pumpCard(WidgetTester tester, Locale locale, int rooms) {
      return tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: MapPreviewCard(
              ad: mapAd(id: 'plural-proof', rooms: rooms),
              onTap: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('en: singular vs plural word forms', (tester) async {
      await pumpCard(tester, const Locale('en'), 1);
      expect(find.text('1 room'), findsOneWidget);

      await pumpCard(tester, const Locale('en'), 3);
      expect(find.text('3 rooms'), findsOneWidget);
    });

    testWidgets(
      'ru: one/few ICU categories render distinct Russian words, never the English fallback',
      (tester) async {
        // count=1 -> Russian "one" category.
        await pumpCard(tester, const Locale('ru'), 1);
        expect(find.text('1 комната'), findsOneWidget);
        expect(find.text('1 room'), findsNothing);

        // count=3 -> Russian "few" category (2/3/4), a different word from
        // both "one" (комната) and "many" (комнат) — proves the ICU block's
        // branch selection is live, not just its first branch.
        await pumpCard(tester, const Locale('ru'), 3);
        expect(find.text('3 комнаты'), findsOneWidget);
        expect(find.text('3 rooms'), findsNothing);

        // count=5 -> Russian "many" category.
        await pumpCard(tester, const Locale('ru'), 5);
        expect(find.text('5 комнат'), findsOneWidget);
      },
    );

    testWidgets(
      'uz: renders the Uzbek word at every count (CLDR other-only plural rule), never the English fallback',
      (tester) async {
        await pumpCard(tester, const Locale('uz'), 1);
        expect(find.text('1 xona'), findsOneWidget);
        expect(find.text('1 room'), findsNothing);

        await pumpCard(tester, const Locale('uz'), 5);
        expect(find.text('5 xona'), findsOneWidget);
        expect(find.text('5 rooms'), findsNothing);
      },
    );
  });

  group('placeholder — settings About row (settingsAboutRowSubtitle)', () {
    Future<void> pumpSettings(WidgetTester tester, Locale locale) async {
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          authRepositoryProvider.overrideWithValue(RecordingAuthRepository()),
          languageRepositoryProvider.overrideWithValue(
            FakeLanguageRepository(),
          ),
          notificationsPreferenceRepositoryProvider.overrideWithValue(
            FakeNotificationsPreferenceRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(authSessionProvider.notifier).setRole(UserRole.user);

      final router = GoRouter(
        initialLocation: '/profile/settings',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) =>
                const Scaffold(body: Text('profile-root')),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // appVersion is '1.0.0' as of data/app_version.dart; the placeholder
    // substitutes it into a word that itself differs per locale, proving
    // both halves (translated word + untranslated data) work together.
    testWidgets('en shows "Version 1.0.0"', (tester) async {
      await pumpSettings(tester, const Locale('en'));
      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('uz shows "Versiya 1.0.0", not the English word', (
      tester,
    ) async {
      await pumpSettings(tester, const Locale('uz'));
      expect(find.text('Versiya 1.0.0'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsNothing);
    });

    testWidgets('ru shows "Версия 1.0.0", not the English word', (
      tester,
    ) async {
      await pumpSettings(tester, const Locale('ru'));
      expect(find.text('Версия 1.0.0'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsNothing);
    });
  });

  group('form validation — edit-profile (SCREENS.md §18)', () {
    AuthUser user() => AuthUser.fromJson({
      'id': 'user-1',
      'fullName': 'Dilnoza Yusupova',
      'email': 'buyer@lacasa.uz',
      'role': 'user',
      'phoneNumber': '+998901112233',
      'avatar': null,
      'agentId': null,
      'tgChatIds': <int>[],
      'igAccounts': <Map<String, dynamic>>[],
      'igAssistConsentAt': null,
      'realtor': null,
    });

    Future<void> pumpEditProfile(WidgetTester tester, Locale locale) async {
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [authRepositoryProvider.overrideWithValue(
          RecordingAuthRepository(),
        )],
      );
      addTearDown(container.dispose);
      container.read(authSessionProvider.notifier).signIn(user());

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) =>
                const Scaffold(body: Text('profile-root')),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    const EditProfileScreen(branchPrefix: '/profile'),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      router.push('/profile/edit');
      await tester.pumpAndSettle();
    }

    testWidgets(
      'en: empty full name shows the English required message',
      (tester) async {
        await pumpEditProfile(tester, const Locale('en'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Dilnoza Yusupova'),
          '',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('First name is required'), findsOneWidget);
      },
    );

    testWidgets(
      'uz: empty full name shows the Uzbek required message, not the English one',
      (tester) async {
        await pumpEditProfile(tester, const Locale('uz'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Dilnoza Yusupova'),
          '',
        );
        // "Save" itself is localized (editProfileSaveButtonLabel) — the
        // English label would not exist on screen under uz.
        await tester.tap(find.text('Saqlash'));
        await tester.pumpAndSettle();

        expect(find.text('Ism kiritilishi shart'), findsOneWidget);
        expect(find.text('First name is required'), findsNothing);
      },
    );

    testWidgets(
      'ru: a malformed phone number shows the Russian invalid-phone message, not the English one',
      (tester) async {
        await pumpEditProfile(tester, const Locale('ru'));
        await tester.enterText(
          find.widgetWithText(TextField, '+998901112233'),
          '+99890111',
        );
        await tester.tap(find.text('Сохранить'));
        await tester.pumpAndSettle();

        expect(find.text('Неверный номер телефона Узбекистана'), findsOneWidget);
        expect(find.text('Invalid Uzbekistan phone number'), findsNothing);
      },
    );
  });
}
