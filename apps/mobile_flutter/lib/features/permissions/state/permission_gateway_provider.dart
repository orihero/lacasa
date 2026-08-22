/// Supplies the [PermissionGateway] `permissions-primer` requests through.
///
/// Defaults to [PermissionHandlerGateway] — real for the Camera & Photos
/// row, since the platform phase added the plugin and the manifest/Info.plist
/// declarations it needs. It still answers [PermissionOutcome.unavailable]
/// for [AppPermission.notifications] without touching the plugin — see
/// `permission_gateway.dart` for why. Tests override this provider with a
/// fake gateway rather than exercise the real plugin, which needs a device
/// or emulator to answer at all.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/permission_gateway.dart';

final permissionGatewayProvider = Provider<PermissionGateway>((ref) {
  return const PermissionHandlerGateway();
});
