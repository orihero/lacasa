/// An [UploadsRepository] that uploads nothing and succeeds anyway.
///
/// **Why this exists.** `uploadsRepositoryProvider` unconditionally builds
/// `LiveUploadsRepository(LaCasaApi.create().uploads)` — there is no longer a
/// fixture half to fall back to under `flutter test` (see the interface's own
/// doc comment for why uploads never had one, and
/// `test/support/ambient_repository_overrides.dart` for why the rest of the
/// fixtures are gone). Any test that mounts a screen carrying a picker
/// control — the listing editor's photo/video step, either avatar control —
/// therefore has a provider wired to real HTTP. Override it with this and the
/// wiring resolves to something that can never reach the network.
///
/// **What "inert" means here.** [upload] returns a handle whose [result] is
/// *already complete* with the empty string, and whose [cancel] is a no-op.
/// Completing immediately is the deliberate choice: a handle that never
/// settles would leave the caller's progress ring spinning, and an
/// indeterminate `CircularProgressIndicator` animates forever, so
/// `pumpAndSettle` would time out — exactly the failure this class exists to
/// prevent. [onProgress] is never called, because a fake upload has no
/// honest progress to report; a control that shows a ring simply goes from
/// "started" to "done" in one pump.
///
/// The empty URL is inert on purpose too: nothing renders it as an image
/// (a network image would be the next thing to hang), and a test asserting on
/// what got uploaded should not be able to accidentally pass against it.
///
/// **Do not build an upload test on this.** A test that actually cares about
/// upload behaviour — progress ticks, cancellation, [describeUploadError]
/// mapping, size rejection — must override `uploadsRepositoryProvider` with a
/// purpose-built fake from `test/features/<feature>/support/` that records
/// its calls and lets the test drive the completer. This class is only for
/// the screens that happen to have a picker on them while the test is about
/// something else.
library;

import 'package:lacasa_mobile/shared/platform/media_picker.dart';
import 'package:lacasa_mobile/shared/state/uploads_repository.dart';

/// See this library's doc comment.
class InertUploadsRepository implements UploadsRepository {
  const InertUploadsRepository();

  @override
  UploadHandle upload({
    required PickedMedia media,
    required String scope,
    void Function(double progress)? onProgress,
  }) => UploadHandle(result: Future<String>.value(''), cancel: () {});
}
