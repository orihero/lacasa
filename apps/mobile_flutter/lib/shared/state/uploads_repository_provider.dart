/// Supplies the [UploadsRepository] every photo/video/avatar upload control
/// reads through — see that interface's own doc comment for why this,
/// unlike every other feature's repository provider, has no fixture
/// branch. A test overrides this with a fake that resolves/rejects on
/// command instead of touching the network.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import 'live_uploads_repository.dart';
import 'uploads_repository.dart';

final uploadsRepositoryProvider = Provider<UploadsRepository>((ref) {
  return LiveUploadsRepository(LaCasaApi.create().uploads);
});
