// Widget tests for step 3 "Photos" (SCREENS.md §26) — specifically the
// failed-tile overlay, whose two controls (Retry and Remove) share one
// 73dp square and must not share any pixels.
//
// These pump `PhotosStep` directly rather than walking `create-listing`'s
// wizard: the geometry under test only misbehaves at the app's *narrowest*
// grid cell, and the widget-test default surface (800×600) is more than
// twice that wide. Driving the step in isolation lets each case state the
// exact grid width it means — 320dp, i.e. a 360dp screen less its two
// `AppSpacing.screenGutter` gutters, which is the four-across cell this
// app's layout comments quote as 73dp.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_editor/widgets/form/listing_form_fields.dart';
import 'package:lacasa_mobile/features/listing_editor/widgets/form/photos_step.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/shared/platform/media_picker.dart';
import 'package:lacasa_mobile/shared/state/uploads_repository_provider.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../../shared/support/fake_uploads_repository.dart';

void main() {
  /// The narrowest `.phos` grid this app ever draws: a 360dp screen less
  /// the two 20dp screen gutters. Four across with 9dp gaps puts each cell
  /// at 73.25dp — the size every geometry comment in `photos_step.dart`
  /// reasons about.
  const double narrowestGridWidth = 320;

  PickedMedia pickedPhoto() => PickedMedia(
    bytes: Uint8List.fromList(const [1, 2, 3]),
    fileName: 'front.jpg',
    mimeType: 'image/jpeg',
  );

  /// Pumps the step showing exactly one photo tile that has already failed
  /// to upload, at [width]. Returns the field bag so a caller can assert on
  /// what survived a tap.
  Future<ListingFormFields> pumpFailedPhoto(
    WidgetTester tester, {
    required FakeUploadsRepository uploads,
    double width = narrowestGridWidth,
  }) async {
    final fields = ListingFormFields();
    addTearDown(fields.dispose);
    fields.media.add(
      ListingMediaUpload(id: 'p1', isVideo: false, source: pickedPhoto())
        ..status = MediaUploadStatus.failed
        ..errorMessage = 'No connection. Check your network and try again.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [uploadsRepositoryProvider.overrideWithValue(uploads)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: PhotosStep(
                    fields: fields,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fields;
  }

  group('a failed tile\'s Retry never triggers Remove', () {
    testWidgets('the retry glyph and the remove badge do not overlap at all', (
      tester,
    ) async {
      await pumpFailedPhoto(
        tester,
        uploads: FakeUploadsRepository(
          error: const NetworkException('offline'),
        ),
      );

      final retry = find.byKey(const ValueKey('newPhoto-retry-p1'));
      final remove = find.byKey(const ValueKey('newPhoto-remove-p1'));
      expect(retry, findsOneWidget);
      expect(remove, findsOneWidget);

      final retryRect = tester.getRect(retry);
      final removeRect = tester.getRect(remove);

      // `ListingPhotoRemoveBadge` pads a 22dp circle out to a 32dp target,
      // and that whole 32dp square is live: it is the tile `Stack`'s last
      // child, and a `Stack` hit-tests back to front, so it beats anything
      // painted under it. Pinned here because the overlap below is only a
      // hazard while this number is bigger than it looks.
      expect(removeRect.size, const Size(32, 32));

      // The regression: the retry glyph used to sit centred just below the
      // tile's top edge, putting ~29% of its 24dp circle inside that
      // square. Every pointer that landed there went to Remove — aiming for
      // "retry my failed upload" and clipping the corner destroyed the
      // picked file instead.
      expect(
        retryRect.overlaps(removeRect),
        isFalse,
        reason:
            'the retry glyph ($retryRect) reaches into the remove badge\'s '
            'tap target ($removeRect), where Remove wins the hit test',
      );
    });

    testWidgets('tapping the centre of the retry glyph re-fires the upload and '
        'keeps the photo', (tester) async {
      final uploads = FakeUploadsRepository(
        error: const NetworkException('offline'),
      );
      final fields = await pumpFailedPhoto(tester, uploads: uploads);
      final item = fields.media.single;

      await tester.tapAt(
        tester.getRect(find.byKey(const ValueKey('newPhoto-retry-p1'))).center,
      );
      await tester.pumpAndSettle();

      // Had the tap been swallowed by the remove badge, the item would be
      // gone from `media` and nothing would have been uploaded.
      expect(fields.media, hasLength(1));
      expect(identical(fields.media.single, item), isTrue);
      expect(uploads.uploadedMedia, hasLength(1));
      expect(identical(uploads.uploadedMedia.single, item.source), isTrue);
    });

    testWidgets('the error text stays clear of the remove badge, so the '
        'reason is readable', (tester) async {
      await pumpFailedPhoto(
        tester,
        uploads: FakeUploadsRepository(
          error: const NetworkException('offline'),
        ),
      );

      final message = find.text(
        'No connection. Check your network and try again.',
      );
      expect(message, findsOneWidget);

      final messageRect = tester.getRect(message);
      final removeRect = tester.getRect(
        find.byKey(const ValueKey('newPhoto-remove-p1')),
      );

      // The regression: bottom-aligning the overlay column fixed the *glyph*
      // (see the case above) but not the text over it. Two `caption` lines
      // start 13.75dp down the tile, squarely inside the remove badge's
      // 22dp circle — and the badge is the tile `Stack`'s last child, so it
      // painted straight over the first line. The one thing this overlay
      // exists to say was hidden behind a close button.
      expect(
        messageRect.overlaps(removeRect),
        isFalse,
        reason:
            'the failure reason ($messageRect) is painted under the remove '
            'badge ($removeRect), which draws on top of it',
      );

      // …and it is still a real text box, not squeezed out of existence by
      // the inset that keeps it clear.
      expect(messageRect.width, greaterThan(0));

      // The vertical budget the overlay's own comment reasons about:
      // 73.25 − 4 − 4 − 24 − 3 = 38.25dp, i.e. two 14.25dp lines and no
      // third. Pinned by asserting the text never leaves the tile, since a
      // third line would push it past the bottom edge.
      final tile = Rect.fromLTWH(
        removeRect.right - 73.25,
        removeRect.top,
        73.25,
        73.25,
      );
      expect(messageRect.top, greaterThanOrEqualTo(tile.top));
      expect(messageRect.bottom, lessThanOrEqualTo(tile.bottom));
    });

    testWidgets('the remove badge still removes', (tester) async {
      final uploads = FakeUploadsRepository(
        error: const NetworkException('offline'),
      );
      final fields = await pumpFailedPhoto(tester, uploads: uploads);

      await tester.tapAt(
        tester.getRect(find.byKey(const ValueKey('newPhoto-remove-p1'))).center,
      );
      await tester.pumpAndSettle();

      expect(fields.media, isEmpty);
      expect(uploads.uploadedMedia, isEmpty);
    });
  });
}
