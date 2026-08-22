/// Barrel for `lib/features/edit_profile/` — SCREENS.md §3.18 (`edit-
/// profile`, screen 18). Exports only the screen: this feature has no
/// `data/`/`state/` of its own to export.
///
/// **Why there is no `data/` or `state/` directory here, unlike
/// `features/agents/` or `features/contact/`.** Every other feature in this
/// tree owns a repository seam because it owns a resource nothing else
/// reads or writes (agents, ads, contact messages). `edit-profile` doesn't
/// — it is a thin form over `PATCH /api/users/me`, which is already fully
/// specified as `features/auth/data/auth_repository.dart`'s
/// [AuthRepository.updateProfile], and its result has to flow back into
/// `lib/navigation/auth_session.dart`'s [AuthSessionNotifier] (the single
/// source of truth for "who is signed in") the same way login/register do.
/// Inventing a second repository interface that just forwards to the first
/// one, or a second copy of [AuthUser], would be indirection with no
/// caller, so `edit_profile_screen.dart` reads `authRepositoryProvider` and
/// `authSessionProvider` directly instead — see that file's doc comment.
library;

export 'widgets/edit_profile_screen.dart';
