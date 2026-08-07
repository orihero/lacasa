/// The version string shown on `settings`'s "About" row (SCREENS.md §3.19
/// gives the row a label and nothing else — no spec'd body copy, no
/// destination screen. Showing the real app name and version instead of a
/// dead row is this task's own call; see `widgets/settings_screen.dart`'s
/// doc comment for the reasoning).
///
/// **Hand-transcribed from `pubspec.yaml`'s `version:` field, not read at
/// runtime.** The obvious real implementation is `package_info_plus`
/// (`PackageInfo.fromPlatform().version`), which reads this from the
/// platform build metadata instead of duplicating it here — but adding a
/// package is out of this task's scope (`pubspec.yaml` is explicitly not
/// owned by this task). This constant is a stand-in that will drift the
/// first time someone bumps `pubspec.yaml` without updating this file; that
/// staleness risk is exactly what `package_info_plus` exists to remove, and
/// is the concrete argument for adding it whenever this feature next gets a
/// real dependency budget.
const String appVersion = '1.0.0';

const String appName = 'La Casa';
