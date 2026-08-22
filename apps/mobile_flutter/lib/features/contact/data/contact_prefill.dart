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
  const ContactPrefill({
    this.message = '',
    this.contextTitle,
    this.contextSubtitle,
    this.contextAvatarUrl,
    this.contextAvatarName,
  });

  final String message;

  /// The `.prefill` context card the mockup floats between the subtitle and
  /// the first field: `<b>{listing title}</b><br>{agent} · {district},
  /// {city}` beside a 28px avatar. All three are null for a sheet opened
  /// from a bare "Contact Us" link, and the card is not rendered at all in
  /// that case — there is no context to show and inventing one would be a
  /// lie about what the office will receive.
  final String? contextTitle;
  final String? contextSubtitle;
  final String? contextAvatarUrl;

  /// Whose face the avatar is — the agent, not the listing. Kept separate
  /// from [contextTitle] so the initials fallback spells the agent's
  /// initials rather than the first letters of a property headline.
  final String? contextAvatarName;

  /// True when there is enough context to be worth a card. The subtitle
  /// alone is not: the card leads with the title.
  bool get hasContext =>
      contextTitle != null && contextTitle!.trim().isNotEmpty;

  /// SCREENS.md caps the message field at 500 characters, so this stays
  /// well inside it: a long listing title is truncated rather than eating
  /// the whole allowance and leaving the user nothing to type in. The id
  /// badge (`Formatters.adIdBadge`'s `#` + 5 chars) is included because it
  /// is what the office searches on when the message reaches Telegram.
  factory ContactPrefill.forListing({
    required String title,
    required String adId,
    String? agentName,
    String? location,
    String? agentAvatarUrl,
  }) {
    final shortTitle = title.length <= 60
        ? title
        : '${title.substring(0, 57)}...';
    final badge = Formatters.adIdBadge(adId);
    final agent = agentName?.trim();
    final agentPart = (agent == null || agent.isEmpty)
        ? ''
        : ' (agent: $agent)';

    // "{agent} · {district}, {city}", with either half dropped when the
    // screen couldn't resolve it, rather than a stray separator.
    final place = location?.trim();
    final subtitle = [
      if (agent != null && agent.isNotEmpty) agent,
      if (place != null && place.isNotEmpty) place,
    ].join(' · ');

    return ContactPrefill(
      message: 'I would like to apply for "$shortTitle" $badge$agentPart.',
      contextTitle: title,
      contextSubtitle: subtitle.isEmpty ? null : subtitle,
      contextAvatarUrl: agentAvatarUrl,
      contextAvatarName: agent,
    );
  }

  /// SCREENS.md §3.10's "message icon → `contact-sheet` pre-filled", from
  /// `agent-profile`. Names the agent because that is the only thing the
  /// screen knows and the only thing the office needs to route the message;
  /// there is no listing in context here, so no title or id badge to carry.
  factory ContactPrefill.forAgent({
    required String agentName,
    String? agentAvatarUrl,
  }) {
    final name = agentName.trim();
    if (name.isEmpty) return const ContactPrefill();
    return ContactPrefill(
      message: 'I would like to get in touch with $name.',
      contextTitle: name,
      contextAvatarUrl: agentAvatarUrl,
      contextAvatarName: name,
    );
  }
}
