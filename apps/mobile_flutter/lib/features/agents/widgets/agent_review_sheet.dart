/// `agent-review-sheet` — a bottom sheet, not a route, for the
/// leave/edit/delete-a-review flow the agent block gets in this run.
///
/// **This surface is not in SCREENS.md.** §3.9 only asks for the
/// `"Review: {rating}/5"` *display*; the review-submission form did not
/// exist when the spec was written (there was no review table to submit
/// into). It is built here to match the app's existing form/bottom-sheet
/// idiom — `contact_sheet.dart`'s grab handle, title row with a close "X",
/// glass-surface fields, and single gradient submit button — rather than
/// inventing a new visual language for one screen. Flagged so
/// `mockups/SCREENS.md` can be updated to describe it explicitly.
///
/// **Requires an authenticated caller, but does not check that itself.**
/// [showAgentReviewSheet] assumes whoever calls it already gated on
/// `authSessionProvider.isSignedIn` and has a non-null
/// `AuthSessionState.user` — see `agent_reviews_section.dart`, the only
/// caller, which shows this app's existing sign-in prompt instead of
/// opening this sheet at all for a signed-out visitor. Opening this sheet
/// signed out would build a `ReviewAuthor` from a null user and crash, which
/// is deliberate: a screen that reaches that state has a bug in its own
/// gating, not a case this sheet should silently paper over.
///
/// **Upsert, not create-then-stack.** [existingReview] pre-fills the rating
/// and comment when the signed-in caller already has one (SCREENS.md-style
/// requirement carried over from the API's own upsert-on-`(agentId,
/// authorId)` contract) — posting again edits it in place, and a visible
/// "Delete review" action (via `DELETE /agents/:id/reviews/me`) is only
/// offered when there is something to delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/agents_repository_provider.dart';
import 'rating_input.dart';

/// Opens the sheet. Resolves to `true` if the review was posted, updated,
/// or deleted — a caller that wants to refresh the reviews list/rating on
/// a real change can react to that, and one that doesn't can ignore it.
Future<bool?> showAgentReviewSheet(
  BuildContext context, {
  required String agentId,
  required String agentName,
  AgentReview? existingReview,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) => _AgentReviewSheet(
      agentId: agentId,
      agentName: agentName,
      existingReview: existingReview,
    ),
  );
}

class _AgentReviewSheet extends ConsumerStatefulWidget {
  const _AgentReviewSheet({
    required this.agentId,
    required this.agentName,
    required this.existingReview,
  });

  final String agentId;
  final String agentName;
  final AgentReview? existingReview;

  @override
  ConsumerState<_AgentReviewSheet> createState() => _AgentReviewSheetState();
}

class _AgentReviewSheetState extends ConsumerState<_AgentReviewSheet> {
  late int _rating;
  late final TextEditingController _comment;

  String? _error;
  bool _submitting = false;
  bool _deleting = false;

  bool get _isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 0;
    _comment = TextEditingController(text: widget.existingReview?.comment ?? '');
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _deleting) return;

    // Captured once, up front — this method crosses an `await`, and every
    // later use is after either a `pop` or a `mounted` re-check, so the
    // lookup is done while `context` is unambiguously still attached to the
    // tree, matching the file's own `colors`/`type` capture-at-top-of-build
    // convention rather than re-querying `.of(context)` after navigation.
    final l10n = AppLocalizations.of(context);

    if (_rating < 1) {
      setState(() => _error = l10n.reviewsRatingRequiredError);
      return;
    }

    // Guaranteed non-null by this sheet's own contract — see the file doc
    // comment. Not defended against further: a caller that reached here
    // signed out has a bug in its gating, not a case to degrade gracefully
    // from.
    final user = ref.read(authSessionProvider).user!;

    setState(() {
      _error = null;
      _submitting = true;
    });

    final comment = _comment.text.trim();
    try {
      await ref
          .read(agentsRepositoryProvider)
          .postAgentReview(
            widget.agentId,
            rating: _rating,
            comment: comment.isEmpty ? null : comment,
            actingAs: ReviewAuthor(
              id: user.id,
              fullName: user.fullName,
              avatar: user.avatar,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      LaCasaToast.showSuccess(
        context,
        _isEditing ? l10n.reviewsUpdateSuccessToast : l10n.reviewsPostSuccessToast,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(l10n, error);
        _submitting = false;
      });
    }
  }

  Future<void> _delete() async {
    final existing = widget.existingReview;
    if (existing == null || _submitting || _deleting) return;

    final l10n = AppLocalizations.of(context);

    final confirmed = await confirmDelete(context, subject: 'review');
    if (!confirmed || !mounted) return;

    final user = ref.read(authSessionProvider).user!;
    setState(() => _deleting = true);

    try {
      await ref
          .read(agentsRepositoryProvider)
          .deleteMyAgentReview(
            widget.agentId,
            actingAs: ReviewAuthor(
              id: user.id,
              fullName: user.fullName,
              avatar: user.avatar,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      LaCasaToast.showSuccess(context, l10n.reviewsDeleteSuccessToast);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      LaCasaToast.showError(context, _messageFor(l10n, error));
    }
  }

  /// The three codes `AgentsRepository.postAgentReview`'s doc comment
  /// documents, plus the generic transport fallbacks `contact_sheet.dart`'s
  /// own `_messageFor` uses. Takes [AppLocalizations] as a parameter rather
  /// than a `BuildContext` — this stays a pure function callable from both
  /// `_submit`/`_delete` with whichever `l10n` each already captured up
  /// front (see those methods' own comment on why), rather than re-deriving
  /// it here from a context that may be stale by the time an error lands.
  static String _messageFor(AppLocalizations l10n, Object error) {
    if (error is ApiErrorException) {
      return switch (error.code) {
        ApiErrorCode.forbidden => l10n.reviewsSelfReviewForbiddenError,
        ApiErrorCode.notFound => l10n.reviewsAgentNotFoundError,
        ApiErrorCode.validation => error.message,
        _ => l10n.reviewsSaveGenericErrorMessage,
      };
    }
    if (error is NetworkException) {
      return l10n.reviewsNetworkErrorMessage;
    }
    return l10n.reviewsSaveGenericErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);
    final busy = _submitting || _deleting;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.base,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(color: colors.line, borderRadius: AppRadii.pill),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? l10n.reviewsSheetEditTitle : l10n.reviewsSheetLeaveTitle,
                      style: type.sheetTitle.copyWith(color: colors.ink),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.reviewsSheetCloseLabel,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close_rounded, size: 20, color: colors.ink2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.reviewsSheetPromptMessage(widget.agentName),
                style: type.bodySmall.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.section),
              Center(
                child: RatingInput(
                  value: _rating,
                  onChanged: busy ? (_) {} : (value) => setState(() => _rating = value),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              Text(
                l10n.reviewsSheetCommentLabel,
                style: type.label.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              GlassSurface(
                variant: GlassVariant.flatForm,
                borderRadius: BorderRadius.circular(AppRadii.control),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.base,
                ),
                child: TextField(
                  controller: _comment,
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !busy,
                  style: type.body.copyWith(color: colors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: l10n.reviewsSheetCommentHint,
                    hintStyle: type.body.copyWith(color: colors.faint),
                    counterText: '',
                  ),
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: AppSpacing.base),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 15,
                      color: AppStatusColors.errorText,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        error,
                        style: type.bodySmall.copyWith(color: AppStatusColors.errorText),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: busy ? null : _submit,
                child: Opacity(
                  opacity: busy ? 0.6 : 1,
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppAccent.gradient,
                      borderRadius: BorderRadius.circular(AppRadii.pillButton),
                      boxShadow: const [
                        BoxShadow(
                          color: AppAccent.shadowColor,
                          blurRadius: 22,
                          spreadRadius: -8,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            _isEditing
                                ? l10n.reviewsSheetUpdateButtonLabel
                                : l10n.reviewsSheetPostButtonLabel,
                            style: type.rowTitle.copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.base),
                Center(
                  child: GestureDetector(
                    onTap: busy ? null : _delete,
                    child: Opacity(
                      opacity: busy ? 0.6 : 1,
                      child: Text(
                        _deleting
                            ? l10n.reviewsSheetDeletingLabel
                            : l10n.reviewsSheetDeleteButtonLabel,
                        style: type.label.copyWith(color: AppStatusColors.errorText),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
