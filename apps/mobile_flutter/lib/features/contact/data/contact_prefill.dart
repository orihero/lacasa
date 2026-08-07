/// What `listing-detail` hands the contact sheet when its "Submit an
/// application" CTA opens it — SCREENS.md §3.7: "→ `contact-sheet`
/// pre-filled with listing title + agent".
///
/// Only the message is pre-filled. Name and phone are the user's own and
/// nothing on the buyer side of the app knows them yet (there is no signed-in
/// buyer profile wired up); guessing would be worse than an empty field.
library;

import '../../../shared/shared.dart';

/// The message text a sheet opens with, plus where it came from. A sheet
/// opened from a generic "Contact us" link passes none of this and starts
/// blank — hence every field being optional and the unnamed default.
class ContactPrefill {
  const ContactPrefill({this.message = ''});

  final String message;

  /// SCREENS.md caps the message field at 200 characters, so this stays
  /// well inside it: a long listing title is truncated rather than eating
  /// the whole allowance and leaving the user nothing to type in. The id
  /// badge (`Formatters.adIdBadge`'s `#` + 5 chars) is included because it
  /// is what the office searches on when the message reaches Telegram.
  factory ContactPrefill.forListing({
    required String title,
    required String adId,
    String? agentName,
  }) {
    final shortTitle = title.length <= 60
        ? title
        : '${title.substring(0, 57)}...';
    final badge = Formatters.adIdBadge(adId);
    final agentPart = (agentName == null || agentName.trim().isEmpty)
        ? ''
        : ' (agent: ${agentName.trim()})';

    return ContactPrefill(
      message: 'I would like to apply for "$shortTitle" $badge$agentPart.',
    );
  }
}
