/// A controllable [AuthRepository] fake for `auth_session_test.dart` — no
/// network, no [TokenStorage] dependency (the real token I/O is
/// [LiveAuthRepository]'s job and is covered by its own test file; this fake
/// exists purely to drive [AuthSessionNotifier] through every branch its
/// commands and startup-restore logic can take).
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/data/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginResult,
    this.loginError,
    this.registerResult,
    this.registerError,
    this.currentUserResult,
    this.currentUserError,
    this.updateProfileResult,
    this.updateProfileError,
    this.currentUserHold,
    this.signOutError,
  });

  AuthUser? loginResult;
  Object? loginError;
  AuthUser? registerResult;
  Object? registerError;
  AuthUser? currentUserResult;
  Object? currentUserError;
  AuthUser? updateProfileResult;
  Object? updateProfileError;

  /// When set, [currentUser] awaits this instead of returning/throwing
  /// immediately — how the timeout branch of the startup restore is
  /// exercised (a `Completer` that is never completed, combined with
  /// `package:fake_async` to fast-forward past the timeout without an
  /// actual multi-second wait).
  final Completer<void>? currentUserHold;

  /// When set, [signOut] throws this. Models the one realistic failure the
  /// real implementations have — `flutter_secure_storage`'s `delete` is a
  /// platform channel and a corrupted keystore makes it throw — which
  /// [AuthSessionNotifier.signOut] has an explicit contract for.
  final Object? signOutError;

  int loginCallCount = 0;
  int registerCallCount = 0;
  int currentUserCallCount = 0;
  int updateProfileCallCount = 0;
  int signOutCallCount = 0;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    loginCallCount++;
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    RealtorApplicationInput? realtor,
  }) async {
    registerCallCount++;
    if (registerError != null) throw registerError!;
    return registerResult!;
  }

  @override
  Future<AuthUser> currentUser() async {
    currentUserCallCount++;
    if (currentUserHold != null) await currentUserHold!.future;
    if (currentUserError != null) throw currentUserError!;
    return currentUserResult!;
  }

  @override
  Future<AuthUser> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatar,
    String? password,
  }) async {
    updateProfileCallCount++;
    if (updateProfileError != null) throw updateProfileError!;
    return updateProfileResult!;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    if (signOutError != null) throw signOutError!;
  }
}
