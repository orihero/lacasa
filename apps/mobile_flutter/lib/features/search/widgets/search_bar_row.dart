/// SCREENS.md §3.4's header: "search input, placeholder 'Search city,
/// district, or title', cancel button." Debounces text input 300ms before
/// updating [searchQueryProvider] — build spec: "Debounce the query; do not
/// fire a request per keystroke." There is no actual network request behind
/// free-text search (see `search_repository.dart`), but debouncing still
/// avoids re-filtering/re-sorting the results list on every keystroke, and
/// matches the 300ms figure SCREENS.md §5 already uses for `filter-sheet`'s
/// field changes.
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
  const SearchBarRow({super.key, required this.controller, required this.focusNode});

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
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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

    return Row(
      children: [
        Expanded(
          child: GlassSurface(
            key: const ValueKey('searchInputSurface'),
            variant: GlassVariant.flatForm,
            borderRadius: BorderRadius.circular(AppRadii.control),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            height: 44,
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: colors.muted),
                const SizedBox(width: AppSpacing.sm),
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
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        GestureDetector(
          key: const ValueKey('searchCancelButton'),
          onTap: _onCancel,
          child: Text(
            l10n.searchCancelButtonLabel,
            style: type.rowTitle.copyWith(color: AppAccent.color),
          ),
        ),
      ],
    );
  }
}
