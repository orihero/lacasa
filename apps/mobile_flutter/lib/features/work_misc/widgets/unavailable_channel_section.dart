/// The four display-only halves of `connected-accounts` (§21) — Threads,
/// Facebook Marketplace, X and LinkedIn (ruling 7.13). None of them has a
/// backend: `apps/api` exposes no OAuth route, no token store and no publish
/// call for any of the four, and `Channel.fromWire` has no case for them, so
/// the server can never even name one back to us. They therefore get ruling
/// 7.10's visibly-disabled treatment — the same one `youtube_section.dart`
/// already gives YouTube and `channel_tile.dart` gives OLX: the channel is
/// *shown*, with its own brand tile and its own honest reason, and its status
/// switch is permanently off. Nothing here pretends a connect flow exists.
///
/// **Why one parameterized section rather than four files.** This codebase
/// does keep per-channel section files apart where the comments and the
/// structure genuinely differ — `instagram_accounts_section.dart` has a list
/// and a disconnect action, `telegram_section.dart` has a live count,
/// `youtube_section.dart` has two disabled buttons and the `.42`-opacity
/// treatment that goes with them. These four have none of that: each renders
/// exactly one [ChannelToggleRow] and stops, and everything that
/// distinguishes them — title, reason, glyph, gradient — is data, three of
/// which already live in the ARBs. Four files differing only in their
/// arguments would duplicate the *shape* while splitting the one doc comment
/// that actually explains the state, so the explanation lives here once and
/// the call sites stay declarative. YouTube keeps its own file precisely
/// because it is *not* this shape.
///
/// **No buttons, deliberately.** YouTube renders a disabled "Add account" /
/// "Sign out" pair because the mockup's YouTube card has two buttons to
/// disable. These four have no control to disable in the first place — there
/// is no account to add and none to sign out of — so rendering a dimmed pill
/// would be inventing an affordance rather than disabling one.
///
/// The brand gradients below are declared locally rather than imported from
/// `features/listing_editor/widgets/channel_tile.dart`, which holds the same
/// four hex pairs for the publish surfaces. That duplication is intentional
/// and already precedented by `kYoutubeBrandGradient`: per
/// `channel_toggle_row.dart`'s doc comment, brand gradients belong to those
/// companies rather than to Direction E's palette, so they stay const at each
/// call site instead of becoming a shared theme dependency across features.
library;

import 'package:flutter/material.dart';

import 'channel_toggle_row.dart';

/// `.chan__ic` for Threads — the app's monochrome pair, same 135°
/// (topLeft→bottomRight) two-stop shape as `kYoutubeBrandGradient`.
const LinearGradient kThreadsBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4E4E52), Color(0xFF101014)],
);

/// `.chan__ic` for Facebook Marketplace — Facebook blue into a darker stop.
const LinearGradient kFacebookMarketplaceBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1877F2), Color(0xFF0B5FD0)],
);

/// `.chan__ic` for X (formerly Twitter) — near-black into black.
const LinearGradient kXBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF2B2B2B), Color(0xFF000000)],
);

/// `.chan__ic` for LinkedIn — brand blue into a darker stop.
const LinearGradient kLinkedinBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0A66C2), Color(0xFF004182)],
);

/// One `connected-accounts` channel block for a channel this build cannot
/// connect to at all: a single [ChannelToggleRow] whose switch is hard-wired
/// off, and nothing else.
///
/// [note] lands in the mockup's `.lrow__s` slot under the title and must say
/// why *this* channel has no connect control — one of the four
/// `connectedAccounts<Name>UnavailableNoteMessage` strings, never a shared
/// "not available" line. A generic note would leave the reader unable to tell
/// "we haven't built it yet" apart from "the platform forbids it", which for
/// these four are two different, and both true, answers.
///
/// **Where the `ValueKey` goes.** `youtube_section.dart` keys its
/// [ChannelToggleRow] directly, because that section also holds two buttons
/// the key has to be told apart from. Here the section *is* the row — it
/// renders one child and nothing else — so the `connectedAccounts<Name>Toggle`
/// key sits on the section itself rather than being forwarded down.
/// Forwarding it would put the same [Key] on two nested widgets and make
/// every `find.byKey(...)` for it match twice.
class UnavailableChannelSection extends StatelessWidget {
  const UnavailableChannelSection({
    super.key,
    required this.title,
    required this.note,
    required this.icon,
    required this.iconGradient,
  });

  /// The channel's name — one of the four
  /// `connectedAccounts<Name>ToggleTitle` strings, already localized.
  final String title;

  /// The localized, channel-specific reason there is nothing to connect.
  final String note;

  /// Material stand-in glyph for the brand tile, matching the one
  /// `channel_tile.dart`'s `channelGlyph` gives this channel on the publish
  /// surfaces so the same channel reads the same on both screens.
  final IconData icon;

  /// The channel's own brand gradient — one of the four consts above.
  final Gradient iconGradient;

  @override
  Widget build(BuildContext context) {
    return ChannelToggleRow(
      title: title,
      subtitle: note,
      icon: icon,
      iconGradient: iconGradient,
      // Not state, and never derived from anything: there is no account, no
      // token and no route, so this switch has exactly one honest position.
      on: false,
    );
  }
}
