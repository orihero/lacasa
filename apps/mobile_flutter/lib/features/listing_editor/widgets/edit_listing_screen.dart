/// `edit-listing` (SCREENS.md §27) — pushed from `my-listings`' row edit
/// icon at `RoutePaths.workEditListing` (`:id` → [adId]). Same Basics +
/// Details field set as `create-listing` (minus Hashtags, per §27), plus
/// the existing-photo grid with per-photo delete, `create-listing`'s own
/// [PhotosStep] reused as §27's "new-upload picker" (separate control,
/// same [ListingFormFields.media] machinery — see that file's doc
/// comment), and the real [PublishSection] (channel buttons + "Publish
/// Status" link) that `create-listing`'s Step 4 can't offer yet.
///
/// **No step wizard here** — §5: "`edit-listing` uses a real submit
/// ('Save') from any point since all fields are already valid/pre-filled."
/// **Save** re-validates the same required-field set `create-listing`'s
/// Steps 1–2 do (the spec gives no reason edit's fields would be less
/// required than create's) and shows inline errors without navigating away
/// from wherever the user is scrolled to.
///
/// **Discard confirmation** (§5, `edit-listing` named explicitly): the
/// header back arrow and system back gesture both funnel through
/// [confirmDiscardChanges] whenever the fetched ad has been edited.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../my_listings/state/my_listings_providers.dart';
import '../state/listing_editor_providers.dart';
import '../state/listing_editor_repository_provider.dart';
import 'form/basics_step.dart';
import 'form/details_step.dart';
import 'form/existing_photos_grid.dart';
import 'form/listing_form_fields.dart';
import 'form/photos_step.dart';
import 'form/publish_section.dart';

class EditListingScreen extends ConsumerStatefulWidget {
  const EditListingScreen({super.key, required this.adId});

  final String adId;

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _fields = ListingFormFields();
  List<String> _photos = [];
  bool _seeded = false;
  bool _touched = false;
  bool _submitting = false;
  bool _deleting = false;

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  void _seed(Ad ad) {
    if (_seeded) return;
    _fields.seedFrom(ad);
    _photos = List.of(ad.photos);
    _seeded = true;
  }

  void _onFieldChanged() {
    setState(() => _touched = true);
  }

  Future<bool> _confirmDiscard() async {
    if (!_touched) return true;
    return confirmDiscardChanges(context);
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.workMyListings);
    }
  }

  Future<void> _handleBack() async {
    if (await _confirmDiscard()) {
      if (!mounted) return;
      _leave();
    }
  }

  Future<void> _save() async {
    if (_submitting || _deleting) return;
    final l10n = AppLocalizations.of(context);
    if (!_fields.validateAll(l10n)) {
      setState(() {});
      return;
    }
    // See `create_listing_screen.dart`'s identical guard — a still-
    // uploading photo/video has no URL yet to persist.
    if (_fields.hasPendingUploads) {
      LaCasaToast.showError(context, l10n.listingEditorPendingUploadsMessage);
      return;
    }

    setState(() => _submitting = true);
    try {
      await LaCasaToast.run<Ad>(
        context: context,
        action: () => ref
            .read(listingEditorRepositoryProvider)
            .update(
              widget.adId,
              _fields.toWriteInput(
                includeHashtags: false,
                photos: [..._photos, ..._fields.uploadedMediaUrls],
              ),
            ),
        pending: l10n.listingEditorUpdatePendingLabel,
        success: l10n.listingEditorUpdateSuccessMessage,
        errorMessage: (_) => l10n.listingEditorGenericErrorMessage,
      );
      if (!mounted) return;
      setState(() => _touched = false);
      ref.invalidate(editListingAdProvider(widget.adId));
      // See `create_listing_screen.dart`'s identical call — `my-listings`
      // and the dashboard both cache an independent copy of this ad.
      invalidateAdCaches(ref);
      _leave();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    if (_submitting || _deleting) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDelete(
      context,
      subject: l10n.listingEditorDeleteConfirmSubject,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await LaCasaToast.run<void>(
        context: context,
        action: () =>
            ref.read(listingEditorRepositoryProvider).delete(widget.adId),
        pending: l10n.listingEditorDeletePendingLabel,
        success: l10n.listingEditorDeleteSuccessMessage,
        errorMessage: (_) => l10n.listingEditorGenericErrorMessage,
      );
      // See `create_listing_screen.dart`'s identical call — the deleted ad
      // must disappear from `my-listings` and every dashboard cache too.
      invalidateAdCaches(ref);
      if (!mounted) return;
      context.go(RoutePaths.workMyListings);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final adAsync = ref.watch(editListingAdProvider(widget.adId));
    // `AgentAdsResource.delete` is AGENT only server-side (see that
    // method's own doc comment) — hide Delete for a coworker session
    // rather than let it 403 as a surprise, matching this repository's own
    // "the caller is responsible for hiding/disabling Delete" contract.
    final canDelete = ref.watch(authSessionProvider).role != UserRole.coworker;

    return PopScope(
      canPop: !_touched,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) _leave();
      },
      child: Scaffold(
        backgroundColor: colors.screen,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NavRow(
                title: l10n.listingEditorEditNavTitle,
                onBack: _handleBack,
                backKey: const ValueKey('editListing-back'),
              ),
              Expanded(
                child: adAsync.when(
                  loading: () => const _LoadingBody(),
                  error: (error, stackTrace) => _ErrorBody(
                    onRetry: () =>
                        ref.invalidate(editListingAdProvider(widget.adId)),
                  ),
                  data: (ad) {
                    _seed(ad);
                    return _FormBody(
                      fields: _fields,
                      photos: _photos,
                      onFieldChanged: _onFieldChanged,
                      onPhotosChanged: (next) {
                        setState(() {
                          _photos = next;
                          _touched = true;
                        });
                      },
                      ad: ad,
                      submitting: _submitting,
                      deleting: _deleting,
                      canDelete: canDelete,
                      onSave: _save,
                      onDelete: _delete,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
          vertical: AppSpacing.base,
        ),
        children: [
          ShimmerBox(
            height: 52,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          const SizedBox(height: AppSpacing.lg),
          ShimmerBox(
            height: 52,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          const SizedBox(height: AppSpacing.lg),
          ShimmerBox(
            height: 52,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          const SizedBox(height: AppSpacing.lg),
          ShimmerBox(
            height: 120,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FullWidthState(
      icon: Icons.error_outline_rounded,
      message: l10n.listingEditorLoadErrorMessage,
      actionLabel: l10n.sharedRetryLabel,
      onAction: onRetry,
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.fields,
    required this.photos,
    required this.onFieldChanged,
    required this.onPhotosChanged,
    required this.ad,
    required this.submitting,
    required this.deleting,
    required this.canDelete,
    required this.onSave,
    required this.onDelete,
  });

  final ListingFormFields fields;
  final List<String> photos;
  final VoidCallback onFieldChanged;
  final ValueChanged<List<String>> onPhotosChanged;
  final Ad ad;
  final bool submitting;
  final bool deleting;
  final bool canDelete;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.base,
          AppSpacing.screenGutter,
          MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BasicsStep(fields: fields, onChanged: onFieldChanged),
            const SizedBox(height: AppSpacing.section),
            DetailsStep(
              fields: fields,
              onChanged: onFieldChanged,
              showHashtags: false,
            ),
            const SizedBox(height: AppSpacing.section),
            FieldLabel(l10n.listingEditorExistingPhotosLabel),
            ExistingPhotosGrid(photos: photos, onChanged: onPhotosChanged),
            const SizedBox(height: AppSpacing.section),
            FieldLabel(l10n.listingEditorAddPhotosLabel),
            PhotosStep(
              fields: fields,
              onChanged: onFieldChanged,
              existingPhotoCount: photos.length,
            ),
            const SizedBox(height: AppSpacing.section),
            PublishSection(ad: ad, showPublishStatusLink: true),
            const SizedBox(height: AppSpacing.section),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    key: const ValueKey('editListing-save'),
                    onTap: submitting || deleting ? null : onSave,
                    child: Opacity(
                      opacity: submitting || deleting ? 0.6 : 1,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppAccent.gradient,
                          borderRadius: BorderRadius.circular(
                            AppRadii.pillButton,
                          ),
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                l10n.listingEditorSaveButtonLabel,
                                style: type.rowTitle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (canDelete) ...[
              const SizedBox(height: AppSpacing.base),
              GestureDetector(
                key: const ValueKey('editListing-delete'),
                onTap: submitting || deleting ? null : onDelete,
                child: Opacity(
                  opacity: submitting || deleting ? 0.6 : 1,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.pillButton),
                      border: Border.all(
                        color: AppStatusColors.dangerBorder,
                        width: 1.5,
                      ),
                    ),
                    child: deleting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppStatusColors.errorText,
                              ),
                            ),
                          )
                        : Text(
                            l10n.listingEditorDeleteButtonLabel,
                            style: type.rowTitle.copyWith(
                              color: AppStatusColors.errorText,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
