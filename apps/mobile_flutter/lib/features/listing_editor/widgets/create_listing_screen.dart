/// `create-listing` (SCREENS.md §26) — a top-level modal, reached from
/// `my-listings`' "+" button at `RoutePaths.createListing`. A 4-step
/// wizard: Basics → Details → Photos → Publish, matching §5's "Create-listing
/// step progression" rule verbatim:
///
/// - **Next** validates only the *current* step's required fields before
///   advancing, blocking with inline errors if invalid (steps 3/4 have no
///   required fields of their own, so Next always advances from them).
/// - **Back** never re-validates.
/// - **Create** exists only on the final step (Step 4) and submits the
///   whole collected form in one `POST /ads` call.
///
/// **Step 3 Photos is a real picker** — see `form/photos_step.dart`'s own
/// doc comment for the pick/upload/attach flow. [_submit] blocks (with a
/// toast, landing back on step 3) rather than submit while a photo/video is
/// still mid-upload — see its own comment.
///
/// **Discard confirmation** (§5's unsaved-form-dismissal rule, `
/// create-listing` named explicitly): the header close "X" and the system
/// back gesture both funnel through [confirmDiscardChanges] whenever any
/// field has been touched away from this class's own defaults.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../work_dashboard/state/dashboard_providers.dart';
import '../state/listing_editor_repository_provider.dart';
import 'form/basics_step.dart';
import 'form/details_step.dart';
import 'form/listing_form_fields.dart';
import 'form/photos_step.dart';
import 'form/step_indicator.dart';
import 'form/wizard_footer.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _fields = ListingFormFields();
  int _step = 0;
  bool _submitting = false;
  bool _touched = false;

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() => _touched = true);
  }

  void _next() {
    final l10n = AppLocalizations.of(context);
    if (_step == 0) {
      if (!_fields.validateBasics(l10n)) {
        setState(() {});
        return;
      }
    } else if (_step == 1) {
      if (!_fields.validateDescription(l10n)) {
        setState(() {});
        return;
      }
    }
    setState(() => _step += 1);
  }

  void _back() {
    setState(() => _step -= 1);
  }

  Future<bool> _confirmDiscard() async {
    if (!_touched) return true;
    return confirmDiscardChanges(context);
  }

  Future<void> _handleClose() async {
    if (await _confirmDiscard()) {
      if (!mounted) return;
      _close();
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.workMyListings);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context);
    // Re-validate everything (not just the two required-field steps) so a
    // user who somehow reached step 4 without ever tripping Next's checks
    // (e.g. a restored/hot-reloaded state) can't submit an invalid ad.
    if (!_fields.validateAll(l10n)) {
      setState(() {
        // Land back on whichever step actually failed, so the errors are
        // visible rather than sitting on a step already scrolled past.
        _step =
            (_fields.titleError ??
                    _fields.cityError ??
                    _fields.districtError ??
                    _fields.addressError ??
                    _fields.referenceError) !=
                null
            ? 0
            : 1;
      });
      return;
    }
    // A photo/video still mid-upload has no URL yet to put on `photos[]` —
    // submitting now would silently create the ad without it rather than
    // waiting the extra few seconds, which this app's honesty rule treats
    // as worse than a blocking message.
    if (_fields.hasPendingUploads) {
      setState(() => _step = 2);
      LaCasaToast.showError(context, l10n.listingEditorPendingUploadsMessage);
      return;
    }

    setState(() => _submitting = true);
    try {
      await LaCasaToast.run<Ad>(
        context: context,
        action: () => ref
            .read(listingEditorRepositoryProvider)
            .create(
              _fields.toWriteInput(
                includeHashtags: true,
                photos: _fields.uploadedMediaUrls,
              ),
            ),
        pending: l10n.listingEditorCreatePendingLabel,
        success: l10n.listingEditorCreateSuccessMessage,
        errorMessage: (_) => l10n.listingEditorGenericErrorMessage,
      );
      // Dashboard owns an independent copy of the caller's full ad list
      // (`dashboardAdsProvider`) and stays mounted for the whole Work-tab
      // session — without this it would silently keep showing the
      // pre-create list/stat tiles.
      ref.invalidate(dashboardAdsProvider);
      if (!mounted) return;
      context.go(RoutePaths.workMyListings);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return PopScope(
      canPop: !_touched,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && mounted) _close();
      },
      child: Scaffold(
        backgroundColor: colors.screen,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NavRow(
                title: l10n.listingEditorCreateNavTitle,
                onClose: _handleClose,
                closeKey: const ValueKey('createListing-close'),
              ),
              ListingWizardStepIndicator(currentStep: _step),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    overscroll: false,
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey('createListing-step-$_step'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenGutter,
                      vertical: AppSpacing.base,
                    ),
                    child: switch (_step) {
                      0 => BasicsStep(
                        fields: _fields,
                        onChanged: _onFieldChanged,
                      ),
                      1 => DetailsStep(
                        fields: _fields,
                        onChanged: _onFieldChanged,
                      ),
                      2 => PhotosStep(
                        fields: _fields,
                        onChanged: _onFieldChanged,
                      ),
                      _ => const _PublishStepNotice(),
                    },
                  ),
                ),
              ),
              ListingWizardFooter(
                onBack: _step == 0 ? null : _back,
                primaryLabel: _step == 3
                    ? l10n.listingEditorWizardCreateLabel
                    : l10n.listingEditorWizardNextLabel,
                submitting: _submitting,
                onPrimary: _step == 3 ? _submit : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 4's own copy — an honest stand-in for the real per-channel publish
/// buttons §26 describes: publishing only becomes possible once this ad
/// exists server-side (`Ad.id` is required by every `PublishResource` call),
/// which happens the moment **Create** is tapped, not before. `edit-listing`
/// is where the real `PublishSection` (buttons that open
/// `publish-channels-sheet`) lives, for exactly this reason.
class _PublishStepNotice extends StatelessWidget {
  const _PublishStepNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.campaign_outlined, size: 26, color: colors.faint),
        const SizedBox(height: AppSpacing.base),
        Text(
          AppLocalizations.of(context).listingEditorCreatePublishNoticeMessage,
          style: type.body.copyWith(color: colors.ink2),
        ),
      ],
    );
  }
}
