/// Barrel for `lib/features/profile/` — the Profile tab's three role
/// variants (`profile-signed-out` §3.14, `profile-buyer` §3.15,
/// `profile-agent` §3.16). Exports only what `profile_role_screen.dart`
/// needs: the three top-level screens, each constructible with no
/// arguments, each reading whatever session state it needs itself via
/// `authSessionProvider`.
///
/// `lib/navigation/profile_role_screen.dart` (owned by a different task —
/// see this file's own header for why the Profile branch is one route, not
/// three) is the one call site these three exist for. Wiring it is a
/// three-line swap of its `PlaceholderScreen(name: ...)` branches:
///
/// ```dart
/// final role = ref.watch(authSessionProvider).role;
/// return switch (role) {
///   null => const ProfileSignedOutScreen(),
///   UserRole.agent || UserRole.coworker => const ProfileAgentScreen(),
///   UserRole.user || UserRole.unknown => const ProfileBuyerScreen(),
/// };
/// ```
///
/// No `data/`/`state/` subdirectories: unlike `features/agents/` or
/// `features/contact/`, this feature introduces no new repository — every
/// screen here reads `lib/navigation/auth_session.dart`'s
/// `authSessionProvider` (already built) and the already-built
/// `features/language/` / `features/contact/` sheets directly.
library;

export 'widgets/profile_agent_screen.dart';
export 'widgets/profile_buyer_screen.dart';
export 'widgets/profile_signed_out_screen.dart';
