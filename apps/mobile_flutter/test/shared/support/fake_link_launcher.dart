/// A controllable [LinkLauncher] fake — records every call so a test can
/// assert a control opens/dials/shares the right thing, and returns a
/// fixed outcome instead of touching a real OS. Same pattern as
/// `test/features/permissions/support/fake_permission_gateway.dart`.
library;

import 'package:lacasa_mobile/shared/platform/link_launcher.dart';

class FakeLinkLauncher implements LinkLauncher {
  FakeLinkLauncher({this.result = true});

  /// What every call resolves with. A test that needs one call to fail and
  /// another to succeed should construct a second fake rather than mutate
  /// this mid-test.
  final bool result;

  final List<Uri> opened = [];
  final List<String> dialed = [];
  final List<({String text, String? subject})> shared = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return result;
  }

  @override
  Future<bool> dial(String phone) async {
    dialed.add(phone);
    return result;
  }

  @override
  Future<bool> share({required String text, String? subject}) async {
    shared.add((text: text, subject: subject));
    return result;
  }
}
