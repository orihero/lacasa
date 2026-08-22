/// Where the "Notifications" toggle's on/off state (SCREENS.md §3.19) is
/// persisted.
///
/// Same shape as `language/data/language_repository.dart`: one small
/// interface, one `flutter_secure_storage`-backed implementation, no new
/// dependency, no fixture/live split — there is nothing to fetch from a
/// server, this is a purely local preference.
///
/// **What flipping this actually does, and does not, do** — read before
/// assuming this wires up push notifications: it does not. There is no
/// messaging plugin in `pubspec.yaml`, no device-token endpoint in
/// `apps/api`, and `features/permissions/data/permission_gateway.dart`'s
/// grant path for `AppPermission.notifications` is a documented no-op (see
/// that file). This repository only remembers what the user asked for, so
/// that whichever future change adds real push infrastructure has a
/// pre-existing intent signal to honour instead of defaulting every existing
/// install to "on" the day push ships. `widgets/settings_screen.dart`'s
/// row says this in the UI itself rather than leaving it to be inferred.
library;

abstract class NotificationsPreferenceRepository {
  /// The persisted preference. Defaults to `true` (matching the design
  /// mockup's initial state) if none was ever saved or the read failed —
  /// there is no wrong answer to default to since the preference is
  /// currently inert, so the mockup's own default is as good as any.
  Future<bool> load();

  Future<void> save(bool enabled);
}
