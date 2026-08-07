// Widget tests for photo-gallery (SCREENS.md §3.8). PhotoGalleryScreen has
// no Riverpod provider dependencies (see photo_gallery.dart's doc comment
// for why) so these pump it directly inside a themed MaterialApp — no
// ProviderScope needed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/photo_gallery/photo_gallery.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/ad_fixtures.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    PhotoGalleryArgs args, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: PhotoGalleryScreen(args: args),
      ),
    );
    await tester.pumpAndSettle();
  }

  final threePhotoAd = Ad.fromJson(
    adJson(
      photos: const [
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
        'https://example.com/c.jpg',
      ],
    ),
  );

  testWidgets('populated gallery opens on the given start index', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      PhotoGalleryArgs(ad: threePhotoAd, startIndex: 1),
    );

    expect(find.text('2/3'), findsOneWidget);
    expect(find.byTooltip('Close gallery'), findsOneWidget);
  });

  testWidgets('out-of-range startIndex clamps instead of throwing', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      PhotoGalleryArgs(ad: threePhotoAd, startIndex: 99),
    );

    expect(find.text('3/3'), findsOneWidget);
  });

  testWidgets('swiping advances the counter', (tester) async {
    await pumpScreen(tester, PhotoGalleryArgs(ad: threePhotoAd));

    expect(find.text('1/3'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 800);
    await tester.pumpAndSettle();

    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets('tapping a thumbnail jumps to that slide', (tester) async {
    await pumpScreen(tester, PhotoGalleryArgs(ad: threePhotoAd));

    expect(find.text('1/3'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Photo 3 of 3'));
    await tester.pumpAndSettle();

    expect(find.text('3/3'), findsOneWidget);
  });

  testWidgets('close button pops back to the caller', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PhotoGalleryScreen(args: PhotoGalleryArgs(ad: threePhotoAd)),
                  ),
                ),
                child: const Text('Open gallery'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open gallery'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close gallery'), findsOneWidget);

    await tester.tap(find.byTooltip('Close gallery'));
    await tester.pumpAndSettle();

    expect(find.text('Open gallery'), findsOneWidget);
    expect(find.byTooltip('Close gallery'), findsNothing);
  });

  testWidgets('video slide renders an honest unsupported-media tile', (
    tester,
  ) async {
    final ad = Ad.fromJson(
      adJson(
        media: [
          mediaJson(
            url: 'https://example.com/clip.mp4',
            mediaType: 'video',
            position: 0,
          ),
        ],
      ),
    );

    await pumpScreen(tester, PhotoGalleryArgs(ad: ad));

    expect(
      find.text("Video preview isn't available in the gallery yet."),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.videocam_rounded), findsWidgets);
    // No attempt to load the video URL as an image.
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('empty gallery renders the honest empty state, not a crash', (
    tester,
  ) async {
    final ad = Ad.fromJson(adJson());

    await pumpScreen(tester, PhotoGalleryArgs(ad: ad));

    expect(
      find.text('No photos available for this listing.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Close gallery'), findsOneWidget);
    // No counter/thumbnail strip for a gallery with nothing to page.
    expect(find.textContaining('/'), findsNothing);
  });

  testWidgets('single-photo gallery hides dots/thumbnail strip', (
    tester,
  ) async {
    final ad = Ad.fromJson(
      adJson(photos: const ['https://example.com/only.jpg']),
    );

    await pumpScreen(tester, PhotoGalleryArgs(ad: ad));

    expect(find.text('1/1'), findsOneWidget);
    expect(find.bySemanticsLabel('Photo 1 of 1'), findsNothing);
  });

  testWidgets('lays out without overflow at phone width', (tester) async {
    await pumpScreen(
      tester,
      PhotoGalleryArgs(ad: threePhotoAd),
      size: const Size(360, 800),
    );

    expect(tester.takeException(), isNull);
  });
}
