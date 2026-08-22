/// A [PermissionGateway] that answers with a fixed outcome and records what
/// it was asked for — enough to drive every branch of the primer's row state
/// machine, including the two the shipped default can never produce.
library;

import 'package:lacasa_mobile/features/permissions/permissions.dart';

class FakePermissionGateway implements PermissionGateway {
  FakePermissionGateway(this.outcome);

  final PermissionOutcome outcome;

  /// Every permission [request] was called with, in order — so a test can
  /// assert a row asks for its own permission and not the other one.
  final List<AppPermission> requested = [];

  @override
  Future<PermissionOutcome> request(AppPermission permission) async {
    requested.add(permission);
    return outcome;
  }
}
