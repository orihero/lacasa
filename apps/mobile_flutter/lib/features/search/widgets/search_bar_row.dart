/// SCREENS.md §3.4's header: "search input, placeholder 'Search city,
/// district, or title', cancel button." Debounces text input 300ms before
/// updating [searchQueryProvider] — build spec: "Debounce the query; do not
/// fire a request per keystroke." Each committed query is a real server
/// round trip (`GET /ads?q=`, page 1 — see `search_repository.dart` and
/// `search_providers.dart`'s [searchQueryProvider] note), so the debounce
/// is what keeps that to one request per pause rather than one per
/// keystroke; it also matches the 300ms figure SCREENS.md §5 already uses
/// for `filter-sheet`'s field changes.
///
/// This header used to claim the opposite — "there is no actual network
/// request behind free-text search" — from back when the query re-filtered
/// an already-fetched page in Dart. Nothing does that any more; the query
/// reaches `applySearch` in `apps/api/src/services/adService.js`.
///
/// On a debounced *non-empty* commit, the query is also recorded into
/// [recentSearchesProvider] — "Recent Searches" persists what the user
/// actually searched for, not every partial keystroke.
///
/// `/search` is a stateful-shell **tab root**, not a pushed screen, so
/// there is nothing to navigate back to — "Cancel" here clears the field
/// and drops focus rather than popping a route.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import '../state/search_providers.dart';

class SearchBarRow extends ConsumerStatefulWidget {
  const SearchBarRow({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  /// Owned by the parent screen, not this widget — a "Recent Searches" chip
  /// tap needs to write into the same field this row edits, which requires
  /// a controller the parent can also reach. See `search_screen.dart`.
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  ConsumerState<SearchBarRow> createState() => _SearchBarRowState();
}

class _SearchBarRowState extends ConsumerState<SearchBarRow> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // `.srch__x` only exists while the field has text (mockup's field is
    // rendered with a value), so this row has to rebuild on edits it did
    // not originate — a "Recent Searches" chip tap writes straight into
    // this controller from the parent screen.
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(SearchBarRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).setQuery(value);
      if (value.trim().isNotEmpty) {
        ref.read(recentSearchesProvider.notifier).addQuery(value);
      }
    });
  }

  /// `.srch__x` — empties the field but keeps the keyboard up, so the user
  /// can retype. Dropping focus is "Cancel"'s distinct job below.
  void _onClear() {
    _debounce?.cancel();
    widget.controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
  }

  void _onCancel() {
    _debounce?.cancel();
    widget.controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
    widget.focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    final hasText = widget.controller.text.isNotEmpty;

    return Row(
      children: [
        Expanded(
          // `.srch{height:50px;border-radius:25px;gap:9px;padding:0 8px 0 16px}`
          // — a true pill with asymmetric padding, so the clear button sits
          // 8px from the trailing edge.
          child: GlassSurface(
            key: const ValueKey('searchInputSurface'),
            variant: GlassVariant.flatForm,
            borderRadius: AppRadii.pill,
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.md,
            ),
            height: 50,
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: colors.muted),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    key: const ValueKey('searchInputField'),
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    onChanged: _onChanged,
                    style: type.body.copyWith(color: colors.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: l10n.searchInputHint,
                      hintStyle: type.body.copyWith(color: colors.faint),
                    ),
                  ),
                ),
                if (hasText)
                  GestureDetector(
                    key: const ValueKey('searchClearButton'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _onClear,
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.sunk,
                        borderRadius: AppRadii.pill,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: colors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // `.nav--stack{gap:11px}`.
        const SizedBox(width: 11),
        GestureDetector(
          key: const ValueKey('searchCancelButton'),
          onTap: _onCancel,
          // `.link--btn{font-weight:600;color:var(--ink-2)}` — the accent
          // variant (`.link--acc`) is a different class this screen never
          // uses.
          child: Text(
            l10n.searchCancelButtonLabel,
            style: type.rowTitle.copyWith(color: colors.ink2),
          ),
        ),
      ],
    );
  }
}
