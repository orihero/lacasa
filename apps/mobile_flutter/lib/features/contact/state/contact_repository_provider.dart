/// Picks [FixtureContactRepository] or [LiveContactRepository] once, per
/// `contact_mode.dart`'s compile-time switch — and is the single point
/// widget tests override.
///
/// No provider holds the sheet's *form* state. Name, phone, message and the
/// in-flight flag all live in the sheet's own [State]: they are born and
/// die with one modal, and nothing outside it can read or act on them. A
/// Riverpod provider for that would outlive its only reader.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/contact_repository.dart';
import '../data/live_contact_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return LiveContactRepository(LaCasaApi.create());
});
