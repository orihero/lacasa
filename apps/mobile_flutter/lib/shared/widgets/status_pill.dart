/// One glass-free status-chip primitive ([StatusPill]) plus three typed
/// wrappers over it — [AdStagePill], [LeadStatusPill], [PublishStatusPill]
/// — covering every status vocabulary the Work build renders: listing
/// stage (Active/Sold/Draft), lead pipeline stage (the 5 Kanban columns),
/// and per-channel publish status (PENDING/DRAFTED_AWAITING_REVIEW/
/// PUBLISHED/FAILED).
///
/// **One abstraction, not three**, because all three vocabularies reduce to
/// the exact same shape — a short label plus one of five tones — and
/// `apps/console/src/lib/labels.ts` assigns tones from literally the same
/// palette (`ok`/`info`/`warn`/`err`/`mute`) across all three enums. A
/// per-vocabulary pill class would just be [StatusPill] with the switch
/// statement copy-pasted three times; the three wrappers below exist only
/// so a call site can pass a typed enum (`AdStage`/`LeadStatus`/
/// `PublishStatus`) instead of pre-computing `(label, tone)` itself.
///
/// Colors come straight from [AppStatusColors] — flat, non-themed
/// constants, matching that file's own "hardcoded in source CSS" note —
/// except [StatusTone.mute], which pairs [LaCasaColors.muted]/
/// [LaCasaColors.sunk] instead, per [AppStatusColors.mutedStatusNote].
library;

import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';

enum StatusTone { ok, info, warn, err, mute, accent }

/// A compact rounded-pill label — the shared rendering primitive every
/// status vocabulary in the Work build should reduce to (see this file's
/// doc comment) rather than hand-rolling another `Container` + `Text` per
/// screen.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final (Color background, Color foreground) = switch (tone) {
      StatusTone.ok => (AppStatusColors.successBg, AppStatusColors.successText),
      StatusTone.info => (AppStatusColors.infoBg, AppStatusColors.infoText),
      StatusTone.warn => (
        AppStatusColors.warningBg,
        AppStatusColors.warningText,
      ),
      StatusTone.err => (AppStatusColors.errorBg, AppStatusColors.errorText),
      StatusTone.mute => (colors.sunk, colors.muted),
      StatusTone.accent => (AppStatusColors.accentStatusBg, AppAccent.color),
    };

    // `.st{height:23px;border-radius:12px;padding:0 10px;gap:5px;
    // font-size:9.5px;font-weight:600;letter-spacing:.2px}` with
    // `.st::before{width:5px;height:5px;border-radius:50%;
    // background:currentColor}` — the leading dot is on the base rule, so
    // every status vocabulary in the source carries it, not just one.
    // 9.5/600/+0.2 is exactly the `caption` role.
    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      // No `alignment:` — a Container given one expands to its parent's
      // width, and this pill is laid out beside text in Rows, Wraps and
      // Columns that all expect it to be as wide as its own label. The
      // Row below centres the content vertically by itself.
      decoration: BoxDecoration(color: background, borderRadius: AppRadii.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.caption.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// `AdStage` — Active (ok/green) / Sold (mute/grey) / Draft (warn/amber).
/// Active and Draft match `apps/console`'s tone assignment (see the
/// web/console survey's wire-format table); **Sold deliberately diverges**
/// from console's blue. The mobile mockup's only Sold pill is
/// `.st st--mute`, and it reserves `.st--info` for the lead "New" pill —
/// a sold listing is closed/inactive there, which grey says and blue does
/// not.
class AdStagePill extends StatelessWidget {
  const AdStagePill({super.key, required this.stage});

  final AdStage stage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, tone) = switch (stage) {
      AdStage.active => (l10n.sharedAdStageActiveLabel, StatusTone.ok),
      AdStage.sold => (l10n.sharedAdStageSoldLabel, StatusTone.mute),
      AdStage.draft => (l10n.sharedAdStageDraftLabel, StatusTone.warn),
      AdStage.unknown => (l10n.sharedStatusUnknownLabel, StatusTone.mute),
    };
    return StatusPill(label: label, tone: tone);
  }
}

/// `LeadStatus` — the 5 Kanban stages, tones per the web/console survey's
/// table (`info / mute / warn / err / ok`, in `LeadStatus.kanbanOrder`).
/// Labels are SCREENS.md §30's exact display strings, not console's
/// relabeled English (see the web/console survey's Kanban discrepancy
/// notes) — "Could Not Connect", not "Could not connect".
class LeadStatusPill extends StatelessWidget {
  const LeadStatusPill({super.key, required this.status});

  final LeadStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, tone) = switch (status) {
      LeadStatus.newLead => (l10n.sharedLeadStatusNewLabel, StatusTone.info),
      LeadStatus.couldNotConnect => (
        l10n.sharedLeadStatusCouldNotConnectLabel,
        StatusTone.mute,
      ),
      LeadStatus.needToCallBack => (
        l10n.sharedLeadStatusNeedToCallBackLabel,
        StatusTone.warn,
      ),
      LeadStatus.rejected => (
        l10n.sharedLeadStatusRejectedLabel,
        StatusTone.err,
      ),
      LeadStatus.accepted => (
        l10n.sharedLeadStatusAcceptedLabel,
        StatusTone.ok,
      ),
      LeadStatus.unknown => (l10n.sharedStatusUnknownLabel, StatusTone.mute),
    };
    return StatusPill(label: label, tone: tone);
  }
}

/// `PublishStatus` — labels/tones per SCREENS.md §29 and the web/console
/// survey's table: "Not published" (mute) / "Awaiting review" (warn) /
/// "Published" (ok) / "Failed" (err).
class PublishStatusPill extends StatelessWidget {
  const PublishStatusPill({super.key, required this.status});

  final PublishStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, tone) = switch (status) {
      PublishStatus.pending => (
        l10n.sharedPublishStatusPendingLabel,
        StatusTone.mute,
      ),
      PublishStatus.draftedAwaitingReview => (
        l10n.sharedPublishStatusAwaitingReviewLabel,
        StatusTone.warn,
      ),
      PublishStatus.published => (
        l10n.sharedPublishStatusPublishedLabel,
        StatusTone.ok,
      ),
      PublishStatus.failed => (
        l10n.sharedPublishStatusFailedLabel,
        StatusTone.err,
      ),
      PublishStatus.unknown => (l10n.sharedStatusUnknownLabel, StatusTone.mute),
    };
    return StatusPill(label: label, tone: tone);
  }
}
