// Proof of the language switch's persistence contract (SCREENS.md §3.20 —
// `secure_language_repository.dart`'s backing store), complementing
// `language_sheet_test.dart`'s proof of the *live* switch (no restart
// needed to see the new locale).
//
// `flutter_secure_storage` needs a platform channel this suite doesn't
// have, so — same as every other secure-storage-backed repository in this
// app (see `language_repository_provider.dart`'s doc comment) — this
// exercises the real [LanguageRepository] *contract* through
// [FakeLanguageRepository], an in-memory stand-in for the keystore. What
// "survives a restart" means in Riverpod terms: a fresh `ProviderContainer`
// (a new `LanguageNotifier.build()` call, exactly what happens when the app
// process restarts and the provider tree is rebuilt from scratch) reading
// the *same* backing store a previous container wrote to.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/features/language/language.dart';

import 'support/fake_language_repository.dart';

void main() {
  group('persistence survives a restart', () {
    test('a selection written by one container is read back by a fresh one', (
    ) async {
      // One repository instance stands in for the on-disk keystore across
      // both containers — the same instance a real app's single
      // `SecureLanguageRepository` would be, since the keystore itself
      // outlives any one process.
      final store = FakeLanguageRepository();

      final firstLaunch = ProviderContainer(
        overrides: [languageRepositoryProvider.overrideWithValue(store)],
      );
      await firstLaunch.read(languageProvider.future);
      await firstLaunch.read(languageProvider.notifier).select(AppLanguage.ru);
      expect(firstLaunch.read(languageProvider).value, AppLanguage.ru);
      firstLaunch.dispose(); // simulates the app process ending.

      final relaunch = ProviderContainer(
        overrides: [languageRepositoryProvider.overrideWithValue(store)],
      );
      addTearDown(relaunch.dispose);

      // A brand-new AsyncNotifier.build() — no state carried over in
      // memory, only what `store` itself has on it.
      final reloaded = await relaunch.read(languageProvider.future);

      expect(reloaded, AppLanguage.ru);
    });

    test('each of the three languages round-trips through a restart', () async {
      for (final language in AppLanguage.values) {
        final store = FakeLanguageRepository();

        final before = ProviderContainer(
          overrides: [languageRepositoryProvider.overrideWithValue(store)],
        );
        await before.read(languageProvider.notifier).select(language);
        before.dispose();

        final after = ProviderContainer(
          overrides: [languageRepositoryProvider.overrideWithValue(store)],
        );
        addTearDown(after.dispose);

        expect(await after.read(languageProvider.future), language);
      }
    });

    test(
      'a language chosen before the very first load resolves to that language, not the loading-state default',
      () async {
        // Covers the seam `language_sheet.dart`'s doc comment names: the
        // sheet reads `languageAsync.value ?? AppLanguage.en` while loading.
        // This proves the *notifier*'s own build() — not just the sheet's
        // fallback — ends up correct once the read resolves, for a
        // repository that was never touched by this process before.
        final store = FakeLanguageRepository(initial: AppLanguage.uz);

        final container = ProviderContainer(
          overrides: [languageRepositoryProvider.overrideWithValue(store)],
        );
        addTearDown(container.dispose);

        expect(await container.read(languageProvider.future), AppLanguage.uz);
      },
    );
  });
}
