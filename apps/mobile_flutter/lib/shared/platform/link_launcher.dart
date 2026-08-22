/// The seam between anything that opens a URL, dials a number, or hands
/// text to the OS share sheet, and the `url_launcher`/`share_plus` plugins
/// that actually do it.
///
/// ## Why this is a seam and not three separate plugin calls scattered
/// across widgets
///
/// Every other platform capability in this app goes through an interface
/// with a default implementation and a provider a test can override — see
/// `features/permissions/data/permission_gateway.dart`'s doc comment for
/// the fully worked argument. `url_launcher`/`share_plus` are no different:
/// a widget that calls `launchUrl`/`Share.share` directly can't be tested
/// without a real OS underneath it, and four features (agent "call" and
/// listing-detail "share" buttons, `create-listing`'s `tour3dLink`, the
/// Instagram-account OAuth link) would each end up writing a slightly
/// different wrapper around the same three operations. (The contact form —
/// `features/contact/` — posts to `POST /api/contact` directly and never
/// touches this seam; an earlier version of this comment claimed a
/// "contact-form fallback" through here that was never actually built.)
///
/// Unlike [PermissionGateway], this one ships with a real implementation
/// from day one — `url_launcher` and `share_plus` are both in `pubspec.yaml`
/// with the platform declarations they need (`AndroidManifest.xml`
/// `<queries>`, iOS `LSApplicationQueriesSchemes`) already in place. There
/// is no "unavailable" default here because there is nothing missing for
/// it to stand in for.
///
/// ## The bool contract
///
/// Every method returns `Future<bool>` for "did this actually happen",
/// never throws for the ordinary failure paths (no app registered for the
/// scheme, user has no dialer, user dismissed the share sheet) — those are
/// expected outcomes on a real device, not exceptional ones, and a caller
/// that gets `false` back is expected to show its own honest message
/// rather than let an unhandled exception take the screen down. A plugin
/// call that fails in a genuinely unexpected way (rare `PlatformException`
/// paths) is still caught and folded into `false` for the same reason.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

abstract class LinkLauncher {
  /// Opens [uri] in the appropriate external handler (browser for `https`,
  /// dialer for `tel`, ...). Returns `false` if nothing on the device can
  /// handle it or the OS declined to launch it — never throws.
  ///
  /// Only `https` and `tel` are declared as reachable — Android's `<queries>`
  /// block and iOS's `LSApplicationQueriesSchemes` both list exactly these
  /// two, because those are the only schemes any call site actually builds.
  /// A `mailto:` Uri would silently fail `canLaunchUrl` on both platforms
  /// today; add the scheme to both manifests first if a caller ever needs
  /// it.
  Future<bool> open(Uri uri);

  /// Convenience for the single most common [open] call in this app: a
  /// `tel:` link built from [phone] exactly as `Formatters.isValidUzPhone`
  /// validated it (E.164-ish, e.g. `+998901234567`).
  Future<bool> dial(String phone);

  /// Hands [text] (and an optional [subject], used by mail-based share
  /// targets and ignored by most others) to the OS share sheet. Returns
  /// `false` only for `ShareResultStatus.dismissed` — the user backed out
  /// without picking a target. `ShareResultStatus.unavailable` (desktop
  /// platforms mostly: the sheet opened and *something* happened, but the
  /// platform can't report which action the user took) counts as `true`
  /// here, not `false` — the share genuinely went somewhere, so a caller
  /// falling back to "link copied instead" for it would be showing a
  /// redundant, confusing message under a share sheet that just worked.
  Future<bool> share({required String text, String? subject});
}

/// The real, plugin-backed implementation — see this file's doc comment.
class UrlLauncherLinkLauncher implements LinkLauncher {
  const UrlLauncherLinkLauncher();

  @override
  Future<bool> open(Uri uri) async {
    try {
      if (!await url_launcher.canLaunchUrl(uri)) return false;
      return await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } on Exception catch (e, st) {
      // A device with no browser/dialer at all, or a plugin channel error —
      // both are "couldn't do it", not a crash. See this file's bool
      // contract note.
      debugPrint('LinkLauncher.open failed for $uri: $e\n$st');
      return false;
    }
  }

  @override
  Future<bool> dial(String phone) => open(Uri(scheme: 'tel', path: phone));

  @override
  Future<bool> share({required String text, String? subject}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject),
      );
      // `dismissed` is the one status that unambiguously means "did not
      // share"; `unavailable` means the platform can't say either way
      // (the sheet still opened) — see the interface doc comment.
      return result.status != ShareResultStatus.dismissed;
    } on Exception catch (e, st) {
      debugPrint('LinkLauncher.share failed: $e\n$st');
      return false;
    }
  }
}

/// Supplies the [LinkLauncher] every feature opens links, dials, and
/// shares through. A test overrides this with a fake that records calls
/// instead of touching the OS — see `test/shared/support/` for the
/// pattern once a fake lands there.
final linkLauncherProvider = Provider<LinkLauncher>((ref) {
  return const UrlLauncherLinkLauncher();
});
