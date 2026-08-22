/// The single `/profile` route's body. SCREENS.md's Profile branch is one
/// route whose *content* switches on role, not three branches (mirroring
/// the mockup's own `applySession()`, which retargets one tab button
/// rather than declaring three) — see the build spec's "Profile branch is
/// one route, not three."
///
/// Deliberately a [ConsumerWidget] reading [authSessionProvider] itself,
/// rather than a role baked in by the `GoRoute.builder` closure at match
/// time: that way the displayed variant reacts to a sign-in/sign-out/role
/// change purely through normal Riverpod `ref.watch` rebuild, with no
/// dependency on go_router re-invoking the route's builder.
///
/// The three branches below render the real screens built by
/// `features/profile/` (`ProfileSignedOutScreen`/`ProfileBuyerScreen`/
/// `ProfileAgentScreen` — SCREENS.md §3.14/§3.15/§3.16), each a plain `const`
/// constructor that reads whatever session state it needs itself, exactly
/// as that feature's own barrel doc comment describes. This file used to
/// route to `PlaceholderScreen` here; that placeholder era is over.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../features/profile/profile.dart';
import 'auth_session.dart';

class ProfileRoleScreen extends ConsumerWidget {
  const ProfileRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authSessionProvider).role;

    return switch (role) {
      null => const ProfileSignedOutScreen(),
      UserRole.agent || UserRole.coworker => const ProfileAgentScreen(),
      UserRole.user || UserRole.unknown => const ProfileBuyerScreen(),
    };
  }
}
