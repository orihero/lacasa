/// Barrel for `lib/features/permissions/` — SCREENS.md §3.2. Exports the
/// screen plus the gateway seam, since the feature that eventually needs a
/// real permission prompt (`create-listing`, or push) implements
/// [PermissionGateway] from outside this directory and overrides
/// `permissionGatewayProvider`.
library;

export 'data/permission_gateway.dart';
export 'state/permission_gateway_provider.dart';
export 'widgets/permissions_primer_screen.dart';
