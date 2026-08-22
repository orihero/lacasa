// Covers `TileCompositingPrimer`, the Android/Impeller tile-compositing
// workaround `mapTileLayerProvider` wraps every real `TileLayer` in — see
// that class's doc comment in `map_tile_layer_provider.dart` for the full
// device-sweep evidence behind it (a plain tap left tiles grey, a small
// drag painted them instantly, which is why the fix drives the camera
// through a real multi-frame transform change rather than just pumping
// frames the way a first, reverted attempt did).
//
// This suite pumps `TileCompositingPrimer` directly with an inert test
// child — never `mapTileLayerProvider`'s actual output — because the real
// `TileLayer` it wraps in production fires genuine HTTP requests at
// OpenStreetMap the instant it's built (see `map_tile_layer_provider.dart`'s
// top doc comment on why every test in this app avoids that). An earlier
// version of this guard test lived in `map_view_screen_test.dart`, whose
// `pumpMap` helper overrides `mapTileLayerProvider` with a plain coloured
// box on every run — meaning that test was asserting a `Ticker` guard on
// code that was never actually in the pumped tree. It passed unconditionally
// regardless of whether the guard worked, which is exactly the kind of
// green-but-meaningless test this fix pass exists to stop shipping.
// `TileCompositingPrimer` is public specifically so this suite can reach
// the real class, wired into a real `FlutterMap` (so `MapController.of`
// genuinely resolves), without needing a real tile layer underneath it.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:lacasa_mobile/shared/map/map_tile_layer_provider.dart';

void main() {
  Future<void> pumpPrimer(WidgetTester tester, {Key? childKey}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(41.2995, 69.2401),
            initialZoom: 12,
          ),
          children: [
            TileCompositingPrimer(
              child: ColoredBox(
                key: childKey,
                color: const Color(0xFFEFEFEF),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders its child untouched', (tester) async {
    const childKey = Key('primed-child');
    await pumpPrimer(tester, childKey: childKey);

    expect(find.byKey(childKey), findsOneWidget);
  });

  testWidgets(
    'stays off under flutter test even with a real MapController available',
    (tester) async {
      // `flutter test`'s binding never touches a real GPU/Impeller surface,
      // so `isRunningUnderFlutterTest` must keep this primer's `Ticker` from
      // ever starting — regardless of a genuine `MapController` being
      // reachable via `MapController.of`, which this pump (unlike the old,
      // misleading test) actually provides. `transientCallbackCount` is the
      // same signal Flutter's own binding uses to know whether a frame
      // callback is still pending; a regression that dropped the guard
      // would leave this above zero instead of failing with a real device
      // symptom, which is the whole point of asserting it here.
      await pumpPrimer(tester);
      expect(tester.binding.transientCallbackCount, 0);

      // And popping/disposing the map leaves nothing dangling either.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
