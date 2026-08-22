/// The live result-count preview state SCREENS.md §5 calls for ("field
/// changes debounce 300ms and update a live result-count preview inside
/// the sheet"). `autoDispose` so every `showFilterSheet` call starts from
/// a clean slate rather than showing a stale count left over from the
/// previous time the sheet was opened.
///
/// Deliberately its own notifier rather than folded into the sheet's
/// widget-local draft state: the debounce timer needs a lifecycle
/// (`ref.onDispose`) independent of any one `setState` call, and keeping
/// the async count as `AsyncValue<int?>` gets `FilterSheetFooter` loading/
/// error rendering for free via `.when`, matching every other async
/// screen state in this app (`HomeFeedAdsNotifier`, `TopAgentsNotifier`).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'filter_repository_provider.dart';

class FilterCountNotifier extends AsyncNotifier<int?> {
  Timer? _debounce;

  @override
  FutureOr<int?> build() {
    ref.onDispose(() => _debounce?.cancel());
    // Unknown until the sheet's first recount (fired once, immediately,
    // right after the sheet seeds its initial draft) resolves.
    return null;
  }

  /// Recounts immediately, no debounce — used for the sheet's initial
  /// seed and for the explicit "Reset" action (a button press, not a
  /// stream of keystrokes/chip taps, so there is nothing to coalesce).
  Future<void> recountNow(AdFilters filters) async {
    _debounce?.cancel();
    state = const AsyncValue<int?>.loading();
    state = await AsyncValue.guard(
      () => ref.read(filterRepositoryProvider).countMatching(filters),
    );
  }

  /// Recounts after [debounce] of no further calls — every individual
  /// field edit (text input keystroke, chip tap) should call this, not
  /// [recountNow], per SCREENS.md §5's 300ms debounce rule.
  void scheduleRecount(
    AdFilters filters, {
    Duration debounce = const Duration(milliseconds: 300),
  }) {
    _debounce?.cancel();
    _debounce = Timer(debounce, () {
      // Guard against the notifier having been disposed (sheet closed)
      // while the timer was pending.
      if (ref.mounted) recountNow(filters);
    });
  }
}

final filterCountProvider = AsyncNotifierProvider.autoDispose<
  FilterCountNotifier,
  int?
>(FilterCountNotifier.new);
