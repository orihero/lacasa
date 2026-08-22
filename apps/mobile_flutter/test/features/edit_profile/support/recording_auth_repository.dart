/// A minimal [AuthRepository] fake, purpose-built for this feature's own
/// tests, that *records* the exact arguments [updateProfile] was called
/// with — `test/features/auth/support/fake_auth_repository.dart` (owned by
/// the auth task) only counts calls and returns a canned result, which is
/// enough for `auth_session_test.dart` but not enough to prove
/// `edit_profile_screen.dart`'s "send only changed fields" rule, which is
/// this file's whole reason to exist. Every other [AuthRepository] method
/// is unreachable from `EditProfileScreen` (it never logs in, registers,
/// re-validates the session, or signs out) and throws if called, so a test
/// that accidentally exercises one of those paths fails loudly instead of
/// silently returning a stub value.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/data/auth_repository.dart';

class RecordingAuthRepository implements AuthRepository {
  RecordingAuthRepository({this.updateProfileResult, this.updateProfileError});

  AuthUser? updateProfileResult;
  Object? updateProfileError;

  int updateProfileCallCount = 0;

  /// The arguments of the most recent [updateProfile] call, exactly as
  /// received (including the `null`s a caller chose not to send) — the
  /// only way to assert "an unchanged field was omitted, not resent".
  ({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatar,
    String? password,
  })?
  lastUpdateProfileArgs;

  @override
  Future<AuthUser> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatar,
    String? password,
  }) async {
    updateProfileCallCount++;
    lastUpdateProfileArgs = (
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      avatar: avatar,
      password: password,
    );
    if (updateProfileError != null) throw updateProfileError!;
    return updateProfileResult!;
  }

  @override
  Future<AuthUser> login({required String email, required String password}) {
    throw UnimplementedError('EditProfileScreen never calls login');
  }

  @override
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    RealtorApplicationInput? realtor,
  }) {
    throw UnimplementedError('EditProfileScreen never calls register');
  }

  @override
  Future<AuthUser> currentUser() {
    throw UnimplementedError('EditProfileScreen never calls currentUser');
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError('EditProfileScreen never calls signOut');
  }
}
