/// Chooses which [AgentsRepository] the Agents tab runs on: the real
/// [LaCasaApi] (default) or bundled fixtures. Resolves through
/// `lib/api/app_mode.dart` — the single source of truth every
/// `*_mode.dart` switch's default now defers to — rather than
/// hand-rolling its own `false`.
///
/// One switch covers both `agents-directory` and `agent-profile`: they are
/// two views of the same `/api/agents` data behind one repository, and a
/// build where the directory was live but the profile it navigates to was
/// fixture would show two different people under the same name.
///
/// **To force the Agents tab to fixtures:**
/// ```
/// flutter run --dart-define=LACASA_AGENTS_LIVE_API=false
/// ```
///
/// **To point the Agents tab at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

import '../../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveAgentsApi = resolveUseLiveApi(
  const String.fromEnvironment('LACASA_AGENTS_LIVE_API', defaultValue: ''),
);
