/// The seam between `permissions-primer` and the OS permission dialogs.
///
/// ## Why this is a seam and not a bare `permission_handler` call in the
/// widget
///
/// SCREENS.md §3.2 says the per-row **"Allow"** button "triggers OS prompt".
/// The platform phase of this build added `permission_handler` plus the
/// per-platform declarations it needs: `CAMERA`, `READ_MEDIA_IMAGES`,
/// `READ_MEDIA_VIDEO` in `AndroidManifest.xml` and
/// `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` in
/// `Info.plist`. [PermissionHandlerGateway] below is real: it raises the
/// actual OS dialog for the **Camera & Photos** row.
///
/// **`POST_NOTIFICATIONS` was deliberately not declared**, and that decision
/// is unchanged by this file. Nothing in the app uses push yet — no
/// messaging plugin here, and so no device token to register. (`apps/api`
/// *does* now have the server half — a `DeviceToken` model, `POST`/`DELETE
/// /push/devices`, and a `pushService` wired into the real lead/sold/publish
/// triggers — but it is itself a no-op until `FCM_SERVER_KEY` is configured,
/// and has no caller in this app on purpose. See this app's README under
/// "Known gaps" for the four credentials a human must supply before any of
/// it can deliver a message.) Requesting a
/// permission with no manifest entry behind it doesn't raise a dialog, it
/// returns a permanently-denied-shaped answer instantly, which would look
/// exactly like a real prompt-and-refuse to this screen's state machine —
/// the worst outcome the honesty rule warns about, a control that *looks*
/// like it worked. So [PermissionHandlerGateway.request] and `.check` both
/// short-circuit [AppPermission.notifications] straight to
/// [PermissionOutcome.unavailable] without ever calling the plugin, and the
/// row keeps saying so plainly. When push infrastructure lands, that
/// feature adds the plugin, the manifest entry, and removes the
/// short-circuit — nothing else about this file has to change.
library;

import 'package:permission_handler/permission_handler.dart';

/// What a grant attempt, or a status check, actually found.
enum PermissionOutcome {
  granted,

  /// iOS 14+ (and Android 14+) "selected photos only" photo-library access.
  /// Kept distinct from [granted] rather than folded into it: the app *can*
  /// use the photos the user picked, but claiming "Allowed" outright would
  /// hide a real restriction from someone who might want to widen it. The
  /// row says so and offers Settings, same affordance as
  /// [permanentlyDenied].
  limited,

  /// The user said no this time. The OS may still show a prompt on the next
  /// [PermissionGateway.request] call — this is not a dead end.
  denied,

  /// No further in-app prompt is possible: iOS after two refusals, Android
  /// after "Don't ask again", or iOS `restricted` (parental controls, MDM —
  /// folded in here because it is the same dead end from this screen's
  /// point of view: nothing left to do but point at Settings, even though
  /// Settings may not help for a device-level restriction). The row must
  /// route to [PermissionStatusGateway.openSettings] instead of retrying.
  permanentlyDenied,

  /// No permission backend answers for this [AppPermission] in this build —
  /// see this file's doc comment. Distinct from [denied]: the user did not
  /// refuse anything, the app never asked.
  unavailable,
}

enum AppPermission { cameraAndPhotos, notifications }

abstract class PermissionGateway {
  /// Raises the OS prompt for [permission] (if one is still possible) and
  /// reports what happened.
  Future<PermissionOutcome> request(AppPermission permission);
}

/// The second half of the gateway seam: reading current status without
/// prompting, and opening OS Settings. Split out from [PermissionGateway]
/// rather than added to it, deliberately — other features already wire into
/// `permissionGatewayProvider` with a minimal fake that implements only
/// `request` (see `edit_profile_screen_test.dart`'s
/// `_CountingPermissionGateway`), to assert "this tap goes through the
/// gateway seam" without caring about the rest of the state machine. Forcing
/// every such fake to also grow `check`/`openSettings` bodies it never
/// exercises would be needless churn on files this slice does not own for a
/// capability those tests don't need. A gateway that has something real to
/// check or open — [PermissionHandlerGateway], the shipped default —
/// implements this too; the primer screen only uses it when present.
abstract class PermissionStatusGateway {
  /// Reads the current status for [permission] **without** raising a
  /// prompt. Used by the primer's foreground re-check: a user who leaves
  /// the app to grant access in Settings must see the row update on return
  /// without this screen ever calling `request` (which would either be a
  /// silent no-op or, worse, look like a fresh ask it never was).
  Future<PermissionOutcome> check(AppPermission permission);

  /// Opens this app's page in the OS Settings app. Returns whether the
  /// settings page could be opened at all — no platform reports back
  /// whether the user then changed anything, so that is never claimed.
  Future<bool> openSettings();
}

/// The default for permissions this build has no backend for. Asks
/// nothing, checks nothing, has nowhere to send the user, and says so.
class UnavailablePermissionGateway
    implements PermissionGateway, PermissionStatusGateway {
  const UnavailablePermissionGateway();

  @override
  Future<PermissionOutcome> request(AppPermission permission) async {
    return PermissionOutcome.unavailable;
  }

  @override
  Future<PermissionOutcome> check(AppPermission permission) async {
    return PermissionOutcome.unavailable;
  }

  @override
  Future<bool> openSettings() async => false;
}

/// The real implementation, backed by `permission_handler`.
///
/// Only [AppPermission.cameraAndPhotos] is ever actually asked — see this
/// file's doc comment for why [AppPermission.notifications] is
/// short-circuited instead of routed through the plugin.
class PermissionHandlerGateway
    implements PermissionGateway, PermissionStatusGateway {
  const PermissionHandlerGateway();

  /// Both permissions the single "Camera & Photos" row covers. `photos`
  /// (rather than `storage`) is deliberate: `permission_handler` picks the
  /// right underlying Android permission for the running SDK version
  /// (`READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO` on 33+, the legacy
  /// `READ_EXTERNAL_STORAGE` below it) from this one request, matching
  /// exactly what the manifest declares.
  static const List<Permission> _cameraAndPhotos = [
    Permission.camera,
    Permission.photos,
  ];

  @override
  Future<PermissionOutcome> request(AppPermission permission) async {
    if (permission == AppPermission.notifications) {
      return PermissionOutcome.unavailable;
    }
    final statuses = await _cameraAndPhotos.request();
    return _combine(statuses.values);
  }

  @override
  Future<PermissionOutcome> check(AppPermission permission) async {
    if (permission == AppPermission.notifications) {
      return PermissionOutcome.unavailable;
    }
    final statuses = await Future.wait(
      _cameraAndPhotos.map((permission) => permission.status),
    );
    return _combine(statuses);
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  /// The row shows one outcome for two permissions (camera, photos), so a
  /// mixed result has to collapse to a single answer. Worst-first: a dead
  /// end on either permission makes the whole row a dead end, because the
  /// row's only action ("Allow") can't fix just one of them.
  PermissionOutcome _combine(Iterable<PermissionStatus> statuses) {
    if (statuses.any(
      (status) =>
          status == PermissionStatus.permanentlyDenied ||
          status == PermissionStatus.restricted,
    )) {
      return PermissionOutcome.permanentlyDenied;
    }
    if (statuses.any((status) => status == PermissionStatus.limited)) {
      return PermissionOutcome.limited;
    }
    if (statuses.every((status) => status == PermissionStatus.granted)) {
      return PermissionOutcome.granted;
    }
    return PermissionOutcome.denied;
  }
}
