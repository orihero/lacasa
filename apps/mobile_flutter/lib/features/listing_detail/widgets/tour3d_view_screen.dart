/// `tour-3d-view` — the full-screen webview `ListingTourSection` pushes to
/// (SCREENS.md §7: "embedded 3D tour iframe if `tour3dLink` present").
/// No-chrome, root-navigator route, alongside `photo-gallery`/`map-view` —
/// see `route_paths.dart`'s "No-chrome full-screen pages" group and
/// `app_router.dart`'s wiring for those two, which this follows exactly.
///
/// ## Security — validated at this boundary too, not only at the write one
///
/// `apps/api`'s `adService.js` already rejects a non-http(s) `tour3dLink`
/// before it is ever written (see `schema.prisma`'s comment on the
/// column). Trusting that alone here would mean this screen's safety
/// depends entirely on a constraint enforced in a *different codebase*,
/// which this run does not touch and cannot re-verify stayed correct: a
/// migration written before that check existed, a future relaxation of the
/// rule, or simply a bug there would flow straight into
/// `WebViewController.loadRequest` with nothing on this side to catch it.
/// [Tour3dViewArgs.url] is re-parsed and re-checked the moment it reaches
/// this screen — only `http`/`https` with a non-empty host survive
/// [_validate]; anything else (`javascript:`, `file:`, `data:`, a bare
/// string that isn't a URI at all) renders the same terminal error state
/// as a page that failed to load, and [WebViewController] is never
/// constructed at all for it.
///
/// ## Navigation is pinned to the tour's own origin
///
/// A 3D-tour embed has no legitimate reason to carry the user to a
/// different host — that is exactly the shape of a malicious or
/// compromised tour link (an ad injected into the tour host, a
/// redirect chain planted by whoever controls `tour3dLink`). Every
/// navigation request — a link tapped inside the tour, a redirect, the
/// initial load itself — is compared against the origin
/// [Tour3dViewArgs.url] was opened with in [NavigationDelegate.
/// onNavigationRequest]; anything whose scheme+host+port doesn't match is
/// blocked in place (`NavigationDecision.prevent`) rather than followed.
/// The user stays on the tour they opened, not wherever it redirects to.
library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../tour3d_view_args.dart';

class Tour3dViewScreen extends StatefulWidget {
  const Tour3dViewScreen({super.key, required this.args});

  final Tour3dViewArgs args;

  @override
  State<Tour3dViewScreen> createState() => _Tour3dViewScreenState();
}

class _Tour3dViewScreenState extends State<Tour3dViewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _failed = false;

  /// Set once, in [initState], when [_validate] rejects the URL outright.
  /// Kept separate from [_failed] (a page-load failure) because the two are
  /// different problems with different honest copy: "this link isn't a
  /// tour link" is not "the tour link is fine but the page didn't load",
  /// and conflating them would tell the user to Retry something retrying
  /// can never fix.
  bool _invalidLink = false;

  /// Only `http`/`https` with a real host survive — see this file's doc
  /// comment on why this check exists even though the server already
  /// makes it. `Uri.tryParse` alone is not enough: `Uri.tryParse
  /// ('javascript:alert(1)')` succeeds and reports scheme `javascript`,
  /// which is exactly the case this exists to catch.
  static Uri? _validate(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.host.isEmpty) return null;
    return uri;
  }

  /// Same-origin check backing the navigation policy this file's doc
  /// comment describes — scheme, host and port must all match the URL the
  /// screen was opened with. Sub-paths and query strings on the same host
  /// are fine (a tour host serving `/scene/1` then linking to `/scene/2` is
  /// normal); a different host, even a same-owner-looking one
  /// (`tours.lacasa.uz` vs `evil.tours.lacasa.uz`), is not.
  static bool _sameOrigin(Uri a, Uri b) =>
      a.scheme == b.scheme && a.host == b.host && a.port == b.port;

  @override
  void initState() {
    super.initState();
    final origin = _validate(widget.args.url);
    if (origin == null) {
      _invalidLink = true;
      _failed = true;
      _loading = false;
      return;
    }

    final controller = WebViewController()
      // The tour renderer itself (a Matterport/iGuide-style embed) needs
      // JS to run at all — this is the floor the tour needs, not a default
      // left switched on. File access and content-URL access are left at
      // their platform defaults (disabled on both webview_flutter
      // backends): nothing this screen shows is a local asset, so there is
      // no reason to widen that surface.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _setLoading(true),
          onPageFinished: (_) => _setLoading(false),
          onWebResourceError: (error) {
            // A sub-resource failing (a tracker, a missing icon inside an
            // otherwise-working tour) is not this screen's problem — only
            // the main frame failing is terminal. Some platforms leave
            // `isForMainFrame` unset for main-frame errors; treating null
            // as "assume main frame" is the safe direction to round a
            // missing signal, since the alternative silently swallows a
            // real failure.
            if (error.isForMainFrame ?? true) _setFailed();
          },
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            if (target == null || !_sameOrigin(origin, target)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(origin);

    _controller = controller;
  }

  void _setLoading(bool value) {
    if (!mounted || _loading == value) return;
    setState(() => _loading = value);
  }

  void _setFailed() {
    if (!mounted) return;
    setState(() {
      _failed = true;
      _loading = false;
    });
  }

  void _retry() {
    final origin = _validate(widget.args.url);
    final controller = _controller;
    if (origin == null || controller == null) return;
    setState(() {
      _failed = false;
      _loading = true;
    });
    controller.loadRequest(origin);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final l10n = AppLocalizations.of(context);
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            NavRow(
              title: l10n.listingTourSectionTitle,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _failed || controller == null
                  ? ColoredBox(
                      color: colors.screen,
                      child: Center(
                        child: FullWidthState(
                          icon: Icons.error_outline_rounded,
                          message: _invalidLink
                              ? l10n.listingTourInvalidLinkMessage
                              : l10n.listingTourLoadErrorMessage,
                          actionLabel: _invalidLink
                              ? null
                              : l10n.sharedRetryLabel,
                          onAction: _invalidLink ? null : _retry,
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        WebViewWidget(controller: controller),
                        if (_loading)
                          ColoredBox(
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(),
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
