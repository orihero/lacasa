/// `create-listing` (SCREENS.md §26) — a top-level modal, reached from
/// `my-listings`' "+" button at `RoutePaths.createListing`. A 4-step
/// wizard: Basics → Details → Photos → Publish, matching §5's "Create-listing
/// step progression" rule verbatim:
///
/// - **Next** validates only the *current* step's required fields before
///   advancing, blocking with inline errors if invalid (steps 3/4 have no
///   required fields of their own, so Next always advances from them).
/// - **Back** never re-validates — and neither does a tap on a completed
///   step of the indicator, which is the same backward move made in one
///   gesture instead of three (see `form/step_indicator.dart`).
/// - **Create** exists only on the final step (Step 4) and submits the
///   whole collected form in one `POST /ads` call, against the read-only
///   recap [_SummaryCard] prints directly above it.
///
/// **Step 3 Photos is a real picker** — see `form/photos_step.dart`'s own
/// doc comment for the pick/upload/attach flow. [_submit] refuses to submit
/// (with a toast, landing back on step 3) while any picked photo/video is
/// still mid-upload **or has failed** — either way its URL is not going on
/// `photos[]`, and creating the ad without it behind a success toast is the
/// silent drop this app's honesty rule forbids. See [_submit]'s own
/// comments.
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
import '../../my_listings/state/my_listings_providers.dart';
import '../listing_editor_error_message.dart';
import '../state/listing_editor_repository_provider.dart';
import 'channel_tile.dart';
import 'form/basics_step.dart';
import 'form/details_step.dart';
import 'form/listing_form_fields.dart';
import 'form/photos_step.dart';
import 'form/publish_section.dart' show channelLabel, olxUnavailableHint;
import 'form/step_indicator.dart';
import 'form/wizard_footer.dart';
import 'publish_channels_sheet.dart' show kChannelRowGap;

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

  /// The step indicator's tap target (finding: the indicator was purely
  /// decorative, so fixing a typo'd Title from step 4 cost three Backs and
  /// three Nexts). Deliberately the same "never re-validates" contract
  /// **Back** has — the user is moving to a step they already passed, and
  /// §5 is explicit that only Next validates.
  ///
  /// Ignores anything that is not strictly backward, belt-and-braces on top
  /// of the indicator only offering completed steps: a forward jump would
  /// skip the very validation Next exists to run.
  void _goToStep(int step) {
    if (step >= _step) return;
    setState(() => _step = step);
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
    // A **failed** upload is the same silent drop with none of the "wait a
    // few seconds" excuse: it will never produce a URL, so it contributes
    // nothing to `photos[]` — and until this guard existed it sailed
    // straight past the check above, published an ad missing a photo the
    // user could still see sitting in the picker, and said "Successfully
    // created" while doing it. Landing back on step 3 is the point: the
    // message names a tile, so the tile has to be on screen.
    if (_fields.hasFailedUploads) {
      setState(() => _step = 2);
      LaCasaToast.showError(context, l10n.listingEditorFailedUploadsMessage);
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
        // Was `(_) => listingEditorGenericErrorMessage`, which threw the
        // typed exception away and reported "Something went wrong." for a
        // server validation rejection and for being offline alike — on the
        // app's longest form, where knowing which one it was decides
        // whether the user edits a field or moves to better signal. See
        // `listing_editor_error_message.dart`.
        errorMessage: (error) => listingEditorErrorMessage(l10n, error),
      );
      // `my-listings` and the dashboard's stat tiles/chart/workspace links
      // each cache an independent copy of the caller's ad list, and both
      // screens stay mounted across this modal's whole lifetime — without
      // this they would silently keep showing the pre-create data. See
      // `invalidateAdCaches`'s own doc comment (finding M4) for why this is
      // one call rather than one `ref.invalidate` per cache.
      invalidateAdCaches(ref);
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
              ListingWizardStepIndicator(
                currentStep: _step,
                // Backward only — [ListingWizardStepIndicator] hands this
                // callback nothing but already-completed steps, and
                // [_goToStep] re-asserts it. See §5's step-progression
                // rule: Next is what validates, so jumping *forward* over
                // an unvalidated step would be a way around it.
                onStepTapped: _goToStep,
              ),
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
                      _ => _PublishStep(fields: _fields),
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

/// Step 4 — a read-only recap of what is about to be submitted, then §26's
/// "buttons per connected channel (Instagram/Telegram/YouTube); OLX shown
/// disabled". Every channel row is rendered, matching the mockup's `.stack`
/// of `.lrow glf` rows, but **none of them is tappable**: publishing needs
/// an `Ad.id` (every `PublishResource` call requires one), which only exists
/// the moment **Create** is tapped. The leading hint says so in words rather
/// than leaving the rows to look merely broken; `edit-listing` is where the
/// same rows become live (see `form/publish_section.dart`).
///
/// **The [_SummaryCard] is why this step is not just four dead rows.** The
/// three steps behind it are gone from the screen by the time Create is
/// reachable, so the only thing the last, irreversible tap used to be
/// pressed against was memory. The card reprints the fields a mistake would
/// actually hurt in — title, where it is, what it costs, how big it is, how
/// many photos made it — so a wrong one is visible *before* the POST rather
/// than on `my-listings` afterwards. It is deliberately read-only: the step
/// indicator (now tappable, see [_CreateListingScreenState._goToStep]) is
/// how a wrong value gets fixed, so there is exactly one editor per field.
class _PublishStep extends StatelessWidget {
  const _PublishStep({required this.fields});

  final ListingFormFields fields;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(fields: fields),
        const SizedBox(height: AppSpacing.section),
        Text(
          l10n.listingEditorCreatePublishNoticeMessage,
          style: type.bodySmall.copyWith(color: colors.faint),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PublishChannelRow(
          channel: Channel.instagram,
          title: channelLabel(l10n, Channel.instagram),
        ),
        const SizedBox(height: kChannelRowGap),
        _PublishChannelRow(
          channel: Channel.telegram,
          title: channelLabel(l10n, Channel.telegram),
        ),
        const SizedBox(height: kChannelRowGap),
        _PublishChannelRow(
          channel: Channel.youtube,
          title: channelLabel(l10n, Channel.youtube),
          subtitle: l10n.listingEditorYoutubeUnavailableHint,
        ),
        const SizedBox(height: kChannelRowGap),
        _PublishChannelRow(
          channel: Channel.olx,
          title: channelLabel(l10n, Channel.olx),
          subtitle: olxUnavailableHint(l10n),
        ),
      ],
    );
  }
}

/// The read-only recap at the top of Step 4 — see [_PublishStep]'s own doc
/// comment for why it exists.
///
/// Every label here is the *same* ARB key the field's own editor uses
/// (`listingEditorTitleFieldLabel` and friends), never a summary-specific
/// paraphrase: a recap that renamed the fields would be a second vocabulary
/// for the user to map back onto steps 1–2. Only the two values with no
/// field of their own are composed here — the price preview (mirroring
/// `details_step.dart`'s own live preview, down to the currency suffix) and
/// the photo count.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.fields});

  final ListingFormFields fields;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      key: const ValueKey('createListing-summary'),
      variant: GlassVariant.flatForm,
      borderRadius: BorderRadius.circular(AppRadii.card),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.listingEditorSummaryCardTitle,
            style: type.panelHeading.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.base),
          _SummaryRow(
            rowKey: const ValueKey('createListing-summary-title'),
            label: l10n.listingEditorTitleFieldLabel,
            value: _orNull(fields.title.text),
          ),
          _SummaryRow(
            rowKey: const ValueKey('createListing-summary-city'),
            label: l10n.listingEditorCityFieldLabel,
            value: _orNull(fields.city.text),
          ),
          _SummaryRow(
            rowKey: const ValueKey('createListing-summary-district'),
            label: l10n.listingEditorDistrictFieldLabel,
            value: _orNull(fields.district.text),
          ),
          _SummaryRow(
            rowKey: const ValueKey('createListing-summary-price'),
            label: l10n.listingEditorPriceFieldLabel,
            value: _price(l10n),
          ),
          _SummaryRow(
            rowKey: const ValueKey('createListing-summary-rooms'),
            label: l10n.listingEditorRoomsFieldLabel,
            value: switch (int.tryParse(fields.rooms.text.trim())) {
              final rooms? => l10n.sharedRoomsCount(rooms),
              null => null,
            },
          ),
          _SummaryRow(
            rowKey: const ValueKey('createListing-summary-area'),
            label: l10n.listingEditorAreaFieldLabel,
            value: switch (double.tryParse(fields.area.text.trim())) {
              final area? =>
                '${Formatters.trimNum(area)} ${l10n.listingEditorAreaUnitSuffix}',
              null => null,
            },
          ),
          _SummaryRow(
            rowKey: const ValueKey('createListing-summary-photos'),
            label: l10n.listingEditorStepPhotosLabel,
            // Successful photo uploads only — a still-uploading or failed
            // tile is not going on `photos[]` (see
            // `ListingFormFields.uploadedMediaUrls`), and a count that
            // included one would be exactly the false reassurance this card
            // is here to remove. Video is excluded because §26 counts it
            // separately from the 5-photo cap.
            value: l10n.listingEditorSummaryPhotosCount(
              fields.media
                  .where(
                    (m) => !m.isVideo && m.status == MediaUploadStatus.done,
                  )
                  .length,
            ),
          ),
        ],
      ),
    );
  }

  /// Mirrors `details_step.dart`'s `_PricePreview` — same grouped numeral,
  /// same localized currency suffix, same "nothing typed yet" branch — so
  /// the recap can never disagree with the live preview the user just saw
  /// under the Price field.
  String? _price(AppLocalizations l10n) {
    final value = double.tryParse(fields.price.text.trim());
    if (value == null) return null;
    return l10n.listingEditorPricePreviewText(
      Formatters.groupedNumber(value),
      fields.priceType == CurrencyCode.uzs
          ? l10n.listingEditorPriceTypeUzsOption
          : l10n.listingEditorPriceTypeUsdOption,
    );
  }

  static String? _orNull(String text) =>
      text.trim().isEmpty ? null : text.trim();
}

/// One `label · value` line of [_SummaryCard]. A `null` [value] prints
/// `listingEditorSummaryNotSetLabel` in the value slot — never in the label
/// slot, and never by dropping the row: an optional field the user left
/// empty is information, and a silently missing row would read as "this
/// screen forgot about Rooms" rather than "Rooms is blank".
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.rowKey,
    required this.label,
    required this.value,
  });

  final Key rowKey;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final text = value;

    return Padding(
      key: rowKey,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: type.specMeta.copyWith(color: colors.muted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text ?? l10n.listingEditorSummaryNotSetLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: type.specMeta.copyWith(
                color: text == null ? colors.faint : colors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One `.lrow glf` row on Step 4 — brand tile, channel name, optional
/// subtitle. Dimmed and inert (see [_PublishStep]).
///
/// **No trailing chevron, on any row.** Three of the four used to draw one.
/// A chevron is this app's "tapping this goes somewhere" mark everywhere
/// else it appears (`_AddVideoRow`, `publish_section.dart`'s live rows),
/// and none of these rows goes anywhere — the `Opacity(0.5)` said "not yet"
/// while the chevron said "try me", and the chevron is the half that was
/// lying. `edit-listing`'s equivalent rows keep theirs because there they
/// are true.
class _PublishChannelRow extends StatelessWidget {
  const _PublishChannelRow({
    required this.channel,
    required this.title,
    this.subtitle,
  });

  final Channel channel;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Opacity(
      opacity: 0.5,
      child: GlassSurface(
        variant: GlassVariant.flatForm,
        borderRadius: BorderRadius.circular(AppRadii.card),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            ChannelIconTile(channel: channel),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: type.rowTitle.copyWith(color: colors.ink)),
                  if (subtitle case final s?) ...[
                    const SizedBox(height: 2),
                    Text(s, style: type.specMeta.copyWith(color: colors.muted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
