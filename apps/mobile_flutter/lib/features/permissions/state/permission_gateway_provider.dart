/// Supplies the [PermissionGateway] `permissions-primer` requests through.
/// Defaults to [UnavailablePermissionGateway] — see
/// `permission_gateway.dart` for why there is no real implementation yet
/// and what has to happen for one to exist.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/permission_gateway.dart';

final permissionGatewayProvider = Provider<PermissionGateway>((ref) {
  return const UnavailablePermissionGateway();
});
