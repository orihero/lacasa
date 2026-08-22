/// The brand tile every publish surface opens its rows with — the mockup's
/// `.chan__ic` (38×38, radius 13, a per-channel brand gradient, white
/// glyph) and its neutral sibling `.lrow__ic` (36×36, radius 12,
/// `--sunk`, ink glyph) used for OLX, which has no brand treatment
/// anywhere in the source.
///
/// Lives here rather than in `lib/shared/` because all three call sites —
/// `publish_channels_sheet.dart`, `publish_status_screen.dart` and
/// `create_listing_screen.dart`'s Step 4 — are inside this feature.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../theme/theme.dart';

/// `.chan__ic.ig{background:linear-gradient(135deg,#f9ce34,#ee2a7b 52%,#6228d7)}`
///
/// CSS 135° runs top-left → bottom-right (see [AppAccent.gradient]'s own
/// note on the angle conversion).
const Gradient kInstagramGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF9CE34), Color(0xFFEE2A7B), Color(0xFF6228D7)],
  stops: [0.0, 0.52, 1.0],
);

/// `.chan__ic.tg{background:linear-gradient(135deg,#41bce7,#1c93d2)}`
const Gradient kTelegramGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF41BCE7), Color(0xFF1C93D2)],
);

/// `.chan__ic.yt{background:linear-gradient(135deg,#f45b5b,#e02020)}`
const Gradient kYoutubeGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF45B5B), Color(0xFFE02020)],
);

/// Threads' monochrome brand pair, same 135° two-stop shape as
/// [kTelegramGradient]. The four gradients below belong to
/// display-only channels ([Channel.threads] and friends, ruling 7.13):
/// their rows are always rendered visibly disabled, so the tile is the only
/// place the brand shows up at all — the surrounding row is dimmed by its
/// own opacity, this gradient is not pre-dimmed here.
const Gradient kThreadsGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4E4E52), Color(0xFF101014)],
);

/// Facebook Marketplace — Facebook blue, dark stop.
const Gradient kFacebookMarketplaceGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1877F2), Color(0xFF0B5FD0)],
);

/// X (formerly Twitter) — near-black to black.
const Gradient kXGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF2B2B2B), Color(0xFF000000)],
);

/// LinkedIn — brand blue, dark stop.
const Gradient kLinkedinGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0A66C2), Color(0xFF004182)],
);

/// The Material stand-in glyph for each channel — this app bundles no
/// brand icon set, so each channel gets the nearest neutral glyph the
/// publish surfaces already used before they gained their brand tiles.
IconData channelGlyph(Channel channel) => switch (channel) {
  Channel.instagram => Icons.camera_alt_rounded,
  Channel.telegram => Icons.send_rounded,
  Channel.youtube => Icons.smart_display_rounded,
  Channel.olx => Icons.storefront_rounded,
  Channel.threads => Icons.alternate_email_rounded,
  Channel.facebookMarketplace => Icons.shopping_bag_rounded,
  // `Icons.close_rounded` is not a dismiss affordance here — the X in the
  // tile IS the brand wordmark (X, formerly Twitter), and the nearest glyph
  // this app's bundled icon set has for it is the round-cornered cross.
  // Safe to use because [ChannelIconTile] is decorative and
  // non-interactive: it never sits inside a tappable region of its own, and
  // every surface that shows the X row renders that row visibly disabled
  // (ruling 7.13), so there is nothing for a "close" reading to trigger.
  Channel.x => Icons.close_rounded,
  Channel.linkedin => Icons.business_center_rounded,
  Channel.unknown => Icons.public_rounded,
};

/// `null` for a channel with no brand gradient in the source — those render
/// as [ChannelIconTile]'s neutral `.lrow__ic` variant instead, which is
/// exactly the treatment OLX has always had.
///
/// Every member is enumerated explicitly rather than swept up by a `_ =>
/// null` catch-all: with the catch-all, adding a channel to [Channel]
/// silently gave it the neutral tile and nobody had to think about it. The
/// exhaustive form makes the compiler ask "brand tile or neutral tile?" the
/// moment a tenth member appears, which is the decision we actually want
/// forced.
Gradient? channelGradient(Channel channel) => switch (channel) {
  Channel.instagram => kInstagramGradient,
  Channel.telegram => kTelegramGradient,
  Channel.youtube => kYoutubeGradient,
  Channel.threads => kThreadsGradient,
  Channel.facebookMarketplace => kFacebookMarketplaceGradient,
  Channel.x => kXGradient,
  Channel.linkedin => kLinkedinGradient,
  // No brand treatment anywhere in the source for these three, and OLX's
  // neutral rendering is asserted on by the shipped publish-surface tests —
  // leave all three null.
  Channel.olx => null,
  Channel.unknown => null,
};

class ChannelIconTile extends StatelessWidget {
  const ChannelIconTile({super.key, required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final gradient = channelGradient(channel);
    final glyph = channelGlyph(channel);

    if (gradient == null) {
      // `.lrow__ic` — 36×36, radius 12, sunk fill, ink glyph.
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.sunk,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Icon(glyph, size: 17, color: colors.ink),
      );
    }

    // `.chan__ic` — 38×38, radius 13, brand gradient, white glyph.
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(glyph, size: 19, color: Colors.white),
    );
  }
}
