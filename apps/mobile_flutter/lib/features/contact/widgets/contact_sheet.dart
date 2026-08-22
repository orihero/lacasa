/// `contact-sheet` (SCREENS.md §3.11) — "Contact Us", a bottom sheet, not a
/// route. SCREENS.md §1 buckets it under "Bottom sheet (swipe-to-dismiss,
/// partial height)", so like `filter-sheet` it is opened with
/// [showContactSheet] from whichever screen needs it and never appears in
/// `app_router.dart`.
///
/// **Copy is fixed by the spec, character for character** — the title,
/// subtitle, the three field labels, both validation messages, the success
/// toast and the button label are all quoted from §3.11 rather than
/// paraphrased, because three independent implementations are meant to
/// agree on them. The one string §3.11 does *not* name is the Message
/// field's placeholder, which comes from the mockup instead: it is
/// instructional ("I'd like to view this apartment this week." — it tells
/// the user what to write), unlike Full name's, which is sample data
/// ("Dilnoza Yusupova") and is deliberately not ported.
///
/// **The 500-character message cap matches the spec and the server.**
/// `contactSchema` (`packages/domain/src/schemas/contact.ts`) and
/// SCREENS.md §3.11 ("textarea, max 500 chars") were reconciled onto the
/// same number: 200 was too tight for a realistic property enquiry
/// (move-in date, budget and a question already runs past 230), and 500
/// stays compact for reading in Telegram while sitting far under
/// `sendMessage`'s own 4096-char limit. Message length was never the abuse
/// guard anyway — the 5/min per-IP rate limiter is — so all three
/// implementations now agree on 500.
///
/// **Validation runs client-side before any request.** The server validates
/// too, but a round trip to be told a field is empty is a round trip that
/// didn't need to happen — and this endpoint is IP rate-limited at 5/minute,
/// so spending attempts on locally-detectable mistakes is actively
/// expensive.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../data/contact_prefill.dart';
import '../state/contact_repository_provider.dart';

/// SCREENS.md §3.11: "Message (textarea, max 500 chars)".
const int contactMessageMaxLength = 500;

/// Opens the sheet. Resolves when it closes — to `true` if a message was
/// actually sent, `false` or `null` otherwise, so a caller that wants to
/// react to a successful submit can, and one that doesn't can ignore it.
Future<bool?> showContactSheet(
  BuildContext context, {
  ContactPrefill prefill = const ContactPrefill(),
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // The sheet must clear the keyboard, which a bottom sheet does not do
    // for free — see the viewInsets padding inside _ContactSheet.
    useSafeArea: true,
    // Mounts above the floating tab bar — see tab_shell_scaffold.dart's doc
    // comment for why this is required, not optional, for every sheet
    // opened from inside a shell branch.
    useRootNavigator: true,
    builder: (context) => _ContactSheet(prefill: prefill),
  );
}

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet({required this.prefill});

  final ContactPrefill prefill;

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _message;

  /// The single validation line under the fields. One line, not per-field
  /// errors, because SCREENS.md specifies exactly two messages and both are
  /// form-level ("Required fields are not filled" doesn't say which).
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController();
    _message = TextEditingController(text: widget.prefill.message);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    // Captured once, up front — this method crosses an `await`, and every
    // later use is after either a `pop` or a `mounted` re-check, so the
    // lookup happens while `context` is unambiguously still attached (same
    // reasoning `agent_review_sheet.dart`'s `_submit` documents).
    final l10n = AppLocalizations.of(context);

    final name = _name.text.trim();
    final phone = _phone.text.trim();

    // Order matters and is the spec's: emptiness is reported before format,
    // so an empty phone reads as "required", not "invalid".
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = l10n.contactRequiredFieldsError);
      return;
    }
    if (!Formatters.isValidUzPhone(phone)) {
      setState(() => _error = l10n.contactInvalidPhoneError);
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    try {
      await ref
          .read(contactRepositoryProvider)
          .submit(
            ContactRequest(
              name: name,
              phone: phone,
              message: _message.text.trim(),
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      // The themed §5 toast rather than a bare SnackBar — floating, on
      // `colors.card`, with a success glyph. A raw `SnackBar` here rendered
      // Material's docked dark-grey default, which looks like a different
      // app from every other confirmation in the product.
      LaCasaToast.showSuccess(context, l10n.contactSendSuccessToast);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(l10n, e);
        _submitting = false;
      });
    }
  }

  /// Maps a typed failure to copy the user can act on. The three
  /// contact-specific server codes mean genuinely different things and are
  /// not collapsed into one "something went wrong". Takes [AppLocalizations]
  /// as a parameter rather than a `BuildContext` — see
  /// `agent_review_sheet.dart`'s identically-shaped `_messageFor` for why.
  static String _messageFor(AppLocalizations l10n, ApiException e) {
    if (e is ApiErrorException) {
      return switch (e.code) {
        ApiErrorCode.rateLimited => l10n.contactRateLimitedError,
        // Retrying cannot help: nobody is configured to receive this.
        ApiErrorCode.contactUnconfigured => l10n.contactUnconfiguredError,
        ApiErrorCode.contactRelayFailed => l10n.contactGenericErrorMessage,
        ApiErrorCode.validation => e.message,
        _ => l10n.contactGenericErrorMessage,
      };
    }
    if (e is NetworkException) {
      return l10n.contactNetworkErrorMessage;
    }
    return l10n.contactGenericErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Padding(
      // Lifts the sheet above the on-screen keyboard. Without this the
      // Message field is covered by the very keyboard used to fill it.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      // `.sh{left:8px;right:8px;bottom:8px;border-radius:34px;
      // padding:10px 18px 22px}` — the sheet floats inset from three edges
      // with all four corners rounded, not edge-to-edge with a rounded top.
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(34),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _grabHandle(colors),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.contactSheetTitle,
                      style: type.sheetTitle.copyWith(color: colors.ink),
                    ),
                  ),
                  // `.sh__h .rnd{width:34px;height:34px;font-size:16px;
                  // color:var(--ink);background:var(--sunk)}` — the painted
                  // chip keeps the mockup's 34px; [TapTarget] supplies the
                  // 48dp hit box it was 14dp short of, and the `button` +
                  // label semantics this used to hand-roll.
                  TapTarget(
                    key: const ValueKey('contactSheet-close'),
                    semanticsLabel: l10n.contactSheetCloseLabel,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.sunk,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.contactSheetSubtitle,
                style: type.bodySmall.copyWith(color: colors.muted),
              ),
              if (widget.prefill.hasContext)
                _PrefillCard(prefill: widget.prefill),
              const SizedBox(height: AppSpacing.section),
              _Field(
                label: l10n.contactFullNameFieldLabel,
                controller: _name,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: AppSpacing.base),
              _Field(
                label: l10n.contactPhoneFieldLabel,
                controller: _phone,
                hintText: '+998901234567',
                hint: l10n.contactPhoneFieldHint,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                // The wire pattern allows only a leading + and digits;
                // filtering at the keyboard stops a paste of "+998 90 123
                // 45 67" from failing validation for spacing alone.
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              _Field(
                label: l10n.contactMessageFieldLabel,
                controller: _message,
                // `<textarea class="ta glf" placeholder="I'd like to view
                // this apartment this week.">` — instructional example copy,
                // not demo data, which is why the Message field gets a
                // placeholder and Full name (whose mockup placeholder is a
                // person's name) does not.
                hintText: l10n.contactMessageFieldHintText,
                // `.ta{height:auto;min-height:96px}` — the empty box is a
                // fixed ~4-line panel, not a one-line field that grows.
                minLines: 4,
                maxLines: 4,
                maxLength: contactMessageMaxLength,
                keyboardType: TextInputType.multiline,
                // `<span class="hint">0 / 200</span>` — the count, at this
                // build's reconciled 500 cap (see this file's doc comment;
                // SCREENS.md §3.11 wins over the mockup on the number).
                showCounter: true,
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
                        style: type.bodySmall.copyWith(
                          color: AppStatusColors.errorText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              _SendButton(submitting: _submitting, onTap: _submit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grabHandle(LaCasaColors colors) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.line,
          borderRadius: AppRadii.pill,
        ),
      ),
    );
  }
}

/// `.prefill glf` — the context card between the subtitle and the first
/// field: a 28px avatar, the listing (or agent) title in ink, and the
/// "{agent} · {district}, {city}" meta line under it. It exists so the user
/// can see *what* they are writing about; a sheet opened from a bare
/// "Contact Us" link has no such context and renders no card at all.
class _PrefillCard extends StatelessWidget {
  const _PrefillCard({required this.prefill});

  final ContactPrefill prefill;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final subtitle = prefill.contextSubtitle;

    // `.prefill{margin-top:14px;border-radius:16px;padding:11px 13px;
    // gap:10px;font-size:10.5px;line-height:1.5;color:var(--muted)}`.
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GlassSurface(
        variant: GlassVariant.flatForm,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          children: [
            AgentAvatar(
              avatarUrl: prefill.contextAvatarUrl,
              fullName: prefill.contextAvatarName ?? '',
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // `.prefill b{font-size:11.5px;font-weight:600;
                  // color:var(--ink)}`.
                  Text(
                    prefill.contextTitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.rowTitle.copyWith(
                      fontSize: 11.5,
                      height: 1.5,
                      color: colors.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.specMeta.copyWith(
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: colors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled input on the `.glf` flat-glass material — the one glass
/// variant meant to sit under text the user is reading and editing (see
/// [GlassVariant.flatForm]).
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hintText,
    this.hint,
    this.showCounter = false,
    this.keyboardType,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;

  /// The static `.hint` helper line under the input — the Phone field's
  /// "+998 and nine digits" rule, stated before a failed submit rather
  /// than only after one. Mutually exclusive with [showCounter] in
  /// practice: no field in this sheet has both a rule and a counter.
  final String? hint;

  /// Renders a live `{length} / {maxLength}` count on the `.hint` line
  /// below the input.
  final bool showCounter;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// The field's resting height in lines. Left `null` on the single-line
  /// fields, where it would be redundant; the Message box sets it so the
  /// empty textarea is already `.ta`'s full-height panel rather than a
  /// one-line field that grows as the user types.
  final int? minLines;

  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `.field__l` — 10/600, uppercase applied at the call site since
        // TextStyle has no text-transform.
        Text(
          label.toUpperCase(),
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
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            minLines: minLines,
            maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            style: type.body.copyWith(color: colors.ink),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: hintText,
              hintStyle: type.body.copyWith(color: colors.faint),
              // The default counter would sit inside the glass panel and
              // push its height around as the user types; the `.hint` line
              // below carries it instead.
              counterText: '',
            ),
          ),
        ),
        // `.hint{margin-top:6px;padding-left:3px;font-size:10.5px;
        // line-height:1.5;color:var(--faint)}`.
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 3),
            child: Text(hint!, style: _hintStyle(type, colors)),
          ),
        if (showCounter && maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 3),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => Text(
                '${value.text.length} / $maxLength',
                style: _hintStyle(type, colors),
              ),
            ),
          ),
      ],
    );
  }

  TextStyle _hintStyle(LaCasaTypography type, LaCasaColors colors) => type
      .specMeta
      .copyWith(fontWeight: FontWeight.w400, height: 1.5, color: colors.faint);
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.submitting, required this.onTap});

  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: submitting ? null : onTap,
      child: Opacity(
        opacity: submitting ? 0.6 : 1,
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
          child: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              // `<i data-i="paper-plane-tilt-fill"></i>Send message` with
              // `.btn{gap:8px}` and `.btn .i{font-size:17px}`.
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.send_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      AppLocalizations.of(context).contactSendButtonLabel,
                      style: type.rowTitle.copyWith(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
