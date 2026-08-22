/// A controllable [UploadsRepository] fake — resolves with a fixed URL,
/// rejects with a fixed error, or (via [hold]) stays pending until the test
/// completes a [Completer], so a test can observe an in-flight upload's
/// progress/cancel behaviour before it settles. Same pattern as
/// `test/shared/support/fake_media_picker.dart`.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/shared/platform/media_picker.dart';
import 'package:lacasa_mobile/shared/state/uploads_repository.dart';

class FakeUploadsRepository implements UploadsRepository {
  FakeUploadsRepository({this.result, this.error, this.hold});

  /// Returned by [upload] once resolved, if [error] is unset.
  final String? result;

  /// Thrown by [upload] instead of resolving, if set.
  final Object? error;

  /// When set, [upload]'s result future waits on this before resolving/
  /// rejecting — lets a test observe the "uploading" state (progress ticks,
  /// a cancel tap) before letting it settle.
  final Completer<void>? hold;

  final List<PickedMedia> uploadedMedia = [];
  final List<String> uploadedScopes = [];
  int cancelCallCount = 0;

  /// Every progress fraction reported across every call, in order — a test
  /// asserting "progress increases" reads this rather than the argument
  /// passed to a specific call.
  final List<double> reportedProgress = [];

  @override
  UploadHandle upload({
    required PickedMedia media,
    required String scope,
    void Function(double progress)? onProgress,
  }) {
    uploadedMedia.add(media);
    uploadedScopes.add(scope);
    var cancelled = false;

    Future<String> run() async {
      if (onProgress != null) {
        onProgress(0.5);
        reportedProgress.add(0.5);
      }
      if (hold != null) await hold!.future;
      if (cancelled) throw const UploadCancelled();
      if (error != null) throw error!;
      if (onProgress != null) {
        onProgress(1);
        reportedProgress.add(1);
      }
      return result ?? 'https://example.test/uploaded.jpg';
    }

    return UploadHandle(
      result: run(),
      cancel: () {
        cancelled = true;
        cancelCallCount++;
      },
    );
  }
}
