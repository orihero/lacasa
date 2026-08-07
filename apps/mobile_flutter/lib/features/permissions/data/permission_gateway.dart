/// The seam between `permissions-primer` and the OS permission dialogs.
///
/// ## Why this is a seam and not a `permission_handler` call
///
/// SCREENS.md §3.2 says the per-row **"Allow"** button "triggers OS prompt".
/// Doing that for real needs `permission_handler` plus per-platform
/// declarations: `CAMERA`/`READ_MEDIA_IMAGES`/`POST_NOTIFICATIONS` in
/// `AndroidManifest.xml` and `NSCameraUsageDescription`/
/// `NSPhotoLibraryUsageDescription` in `Info.plist`.
///
/// Those declarations were **not** added, deliberately. Nothing in the app
/// uses either capability yet: `create-listing` (the photo-upload screen
/// this primer exists to precede) is unbuilt, and there is no push
/// infrastructure at all — no messaging plugin here, no device-token
/// endpoint in `apps/api`. Shipping a manifest that requests camera and
/// notification access for features that do not exist is worse than not
/// shipping it: it is what app-store review flags, and it is what teaches
/// users to distrust a permission prompt.
///
/// So the screen is real, its explanations are real, and the grant path is
/// an interface with a no-op default. The row renders
/// [PermissionOutcome.unavailable] honestly rather than pretending a prompt
/// appeared. When `create-listing` or push lands, that feature adds the
/// plugin, the manifest entries it actually needs, and one implementation
/// of this interface — and this screen starts working with no changes.
library;

/// What a grant attempt actually did.
enum PermissionOutcome {
  granted,
  denied,

  /// No permission backend is wired up in this build — see this file's doc
  /// comment. Distinct from [denied]: the user did not refuse anything, the
  /// app never asked.
  unavailable,
}

enum AppPermission { cameraAndPhotos, notifications }

abstract class PermissionGateway {
  /// Raises the OS prompt for [permission] and reports what happened.
  Future<PermissionOutcome> request(AppPermission permission);
}

/// The default. Asks nothing and says so.
class UnavailablePermissionGateway implements PermissionGateway {
  const UnavailablePermissionGateway();

  @override
  Future<PermissionOutcome> request(AppPermission permission) async {
    return PermissionOutcome.unavailable;
  }
}
