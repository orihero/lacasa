/// A minimal [WebViewPlatform] fake so `Tour3dViewScreen`'s widget tests
/// can exercise the real `webview_flutter` wiring — [WebViewController],
/// [NavigationDelegate] — without an Android/iOS webview engine, which
/// `flutter test` has no access to. This is the pattern
/// `webview_flutter`'s own test suite uses for the same reason (see its
/// `webview_widget_test.dart`), applied here instead of pulling in
/// `mockito` for four methods.
///
/// Records every URL [Tour3dViewScreen] asks the "engine" to load, and
/// captures the navigation-delegate callbacks it registers so a test can
/// invoke `onNavigationRequest` directly — simulating a redirect the way a
/// real engine would report one — and assert on the [NavigationDecision]
/// the screen made.
///
/// `webview_flutter_platform_interface` is not declared directly in
/// `pubspec.yaml` — it arrives transitively, pinned by `webview_flutter`'s
/// own constraint (2.15.1, see `pubspec.lock`). `webview_flutter` itself
/// re-exports the callback/params/enum types a normal caller ever needs,
/// but not the abstract `PlatformWebViewController`/
/// `PlatformNavigationDelegate`/`PlatformWebViewWidget` base classes a fake
/// *implementation* must extend — those exist only in this lower package.
/// Adding a direct dependency for one test-support file felt like the
/// wrong tradeoff versus a one-line, explained suppression here.
// ignore_for_file: depend_on_referenced_packages
library;

import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class FakeWebViewPlatform extends WebViewPlatform {
  final List<Uri> loadedUris = [];
  FakePlatformNavigationDelegate? delegate;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => FakePlatformWebViewController(params, this);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => delegate = FakePlatformNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => FakePlatformWebViewWidget(params);
}

class FakePlatformWebViewController extends PlatformWebViewController {
  FakePlatformWebViewController(super.params, this._platform)
    : super.implementation();

  final FakeWebViewPlatform _platform;

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    _platform.loadedUris.add(params.uri);
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}
}

class FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  FakePlatformNavigationDelegate(super.params) : super.implementation();

  NavigationRequestCallback? onNavigationRequest;
  PageEventCallback? onPageStarted;
  PageEventCallback? onPageFinished;
  WebResourceErrorCallback? onWebResourceError;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    this.onNavigationRequest = onNavigationRequest;
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    this.onPageStarted = onPageStarted;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    this.onPageFinished = onPageFinished;
  }

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {
    this.onWebResourceError = onWebResourceError;
  }
}

/// Renders as an empty, keyed box rather than throwing — `WebViewWidget`
/// needs a real widget tree to mount, but nothing under test looks at its
/// (nonexistent) content.
class FakePlatformWebViewWidget extends PlatformWebViewWidget {
  FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: ValueKey('fakeWebView'));
}
