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
/// agree on them.
///
/// **The 200-character message cap is the spec's, not the server's.**
/// `contactSchema` (`packages/domain/src/schemas/contact.ts`) allows 2000;
/// SCREENS.md §3.11 says "textarea, max 200 chars". The tighter of the two
/// is enforced here — a client that let a user type 500 characters only to
/// have the server accept them would be fine, but it would diverge from the
/// two sibling implementations building against the same spec. Flagged
/// rather than silently reconciled.
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
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../data/contact_prefill.dart';
import '../state/contact_repository_provider.dart';

/// SCREENS.md §3.11: "Message (textarea, max 200 chars)".
const int contactMessageMaxLength = 200;

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

    final name = _name.text.trim();
    final phone = _phone.text.trim();

    // Order matters and is the spec's: emptiness is reported before format,
    // so an empty phone reads as "required", not "invalid".
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = 'Required fields are not filled');
      return;
    }
    if (!Formatters.isValidUzPhone(phone)) {
      setState(() => _error = 'Invalid phone number format');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(e);
        _submitting = false;
      });
    }
  }

  /// Maps a typed failure to copy the user can act on. The three
  /// contact-specific server codes mean genuinely different things and are
  /// not collapsed into one "something went wrong".
  static String _messageFor(ApiException e) {
    if (e is ApiErrorException) {
      return switch (e.code) {
        ApiErrorCode.rateLimited =>
          'Too many messages just now. Please try again in a minute.',
        // Retrying cannot help: nobody is configured to receive this.
        ApiErrorCode.contactUnconfigured =>
          "The contact form isn't available right now. Please call the "
              'agent directly.',
        ApiErrorCode.contactRelayFailed =>
          "Couldn't send your message right now. Please try again.",
        ApiErrorCode.validation => e.message,
        _ => "Couldn't send your message right now. Please try again.",
      };
    }
    if (e is NetworkException) {
      return 'No connection. Check your network and try again.';
    }
    return "Couldn't send your message right now. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      // Lifts the sheet above the on-screen keyboard. Without this the
      // Message field is covered by the very keyboard used to fill it.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
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
              _grabHandle(colors),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Contact Us',
                      style: type.sheetTitle.copyWith(color: colors.ink),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We welcome all your concerns, issues, and suggestions. '
                'Feel free to get in touch with us at your most convenient '
                'time.',
                style: type.bodySmall.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.section),
              _Field(
                label: 'Full name',
                controller: _name,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: AppSpacing.base),
              _Field(
                label: 'Phone',
                controller: _phone,
                hintText: '+998901234567',
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
                label: 'Message',
                controller: _message,
                maxLines: 4,
                maxLength: contactMessageMaxLength,
                keyboardType: TextInputType.multiline,
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

/// A labelled input on the `.glf` flat-glass material — the one glass
/// variant meant to sit under text the user is reading and editing (see
/// [GlassVariant.flatForm]).
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
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
              // push its height around as the user types.
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
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
              : Text(
                  'Send message',
                  style: type.rowTitle.copyWith(color: Colors.white),
                ),
        ),
      ),
    );
  }
}
