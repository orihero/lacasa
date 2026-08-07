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
/// This build only distinguishes the three placeholder variants named in
/// the spec (`ProfileSignedOutScreen` / `ProfileBuyerScreen` /
/// `ProfileAgentScreen`) by label; a later agent replaces each branch's
/// placeholder with the real screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import 'auth_session.dart';
import 'placeholder_screen.dart';

class ProfileRoleScreen extends ConsumerWidget {
  const ProfileRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authSessionProvider).role;

    final name = switch (role) {
      null => 'Profile (Signed Out)',
      UserRole.agent || UserRole.coworker => 'Profile (Agent)',
      UserRole.user || UserRole.unknown => 'Profile (Buyer)',
    };

    return PlaceholderScreen(name: name);
  }
}
