/// Chooses which [AgentsRepository] the Agents tab runs on: bundled
/// fixtures (default) or the real [LaCasaApi]. Exact same pattern and
/// rationale as `features/home/data/home_feed_mode.dart` and
/// `features/search/data/search_mode.dart` — a screen-local compile-time
/// switch rather than a read of `lib/api/env.dart`, so flipping one
/// feature to live does not drag the others with it.
///
/// One switch covers both `agents-directory` and `agent-profile`: they are
/// two views of the same `/api/agents` data behind one repository, and a
/// build where the directory was live but the profile it navigates to was
/// fixture would show two different people under the same name.
///
/// **To point the Agents tab at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_AGENTS_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

const bool useLiveAgentsApi = bool.fromEnvironment('LACASA_AGENTS_LIVE_API');
