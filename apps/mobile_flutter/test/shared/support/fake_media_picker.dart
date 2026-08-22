/// A controllable [MediaPicker] fake — returns a fixed [PickedMedia], `null`
/// (simulating a user cancel), or throws a fixed [MediaPickerException]
/// (simulating a denied permission or other plugin failure), and records
/// which source/method a test's control asked for.
library;

import 'package:lacasa_mobile/shared/platform/media_picker.dart';

class FakeMediaPicker implements MediaPicker {
  FakeMediaPicker({this.imageResult, this.videoResult, this.error});

  /// Returned by [pickImage]; `null` simulates the user cancelling.
  final PickedMedia? imageResult;

  /// Returned by [pickVideo]; `null` simulates the user cancelling.
  final PickedMedia? videoResult;

  /// When set, both methods throw this instead of returning — simulates a
  /// denied permission or other genuine failure, distinct from a cancel.
  final MediaPickerException? error;

  final List<ImageSourceKind> imageRequests = [];
  final List<ImageSourceKind> videoRequests = [];

  @override
  Future<PickedMedia?> pickImage({required ImageSourceKind source}) async {
    imageRequests.add(source);
    if (error != null) throw error!;
    return imageResult;
  }

  @override
  Future<PickedMedia?> pickVideo({required ImageSourceKind source}) async {
    videoRequests.add(source);
    if (error != null) throw error!;
    return videoResult;
  }
}
