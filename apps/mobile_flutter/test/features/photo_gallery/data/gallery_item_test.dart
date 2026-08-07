import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/photo_gallery/data/gallery_item.dart';

import '../support/ad_fixtures.dart';

void main() {
  group('resolveGalleryItems', () {
    test('prefers media, sorted by position, over photos', () {
      final ad = Ad.fromJson(
        adJson(
          photos: const ['https://example.com/fallback.jpg'],
          media: [
            mediaJson(
              url: 'https://example.com/second.jpg',
              mediaType: 'photo',
              position: 1,
            ),
            mediaJson(
              url: 'https://example.com/first.jpg',
              mediaType: 'photo',
              position: 0,
            ),
          ],
        ),
      );

      final items = resolveGalleryItems(ad);

      expect(items, hasLength(2));
      expect(items[0].url, 'https://example.com/first.jpg');
      expect(items[1].url, 'https://example.com/second.jpg');
    });

    test('preserves mixed photo/video media types', () {
      final ad = Ad.fromJson(
        adJson(
          media: [
            mediaJson(
              url: 'https://example.com/photo.jpg',
              mediaType: 'photo',
              position: 0,
            ),
            mediaJson(
              url: 'https://example.com/video.mp4',
              mediaType: 'video',
              position: 1,
            ),
          ],
        ),
      );

      final items = resolveGalleryItems(ad);

      expect(items[0].mediaType, AdMediaType.photo);
      expect(items[0].isPhoto, isTrue);
      expect(items[1].mediaType, AdMediaType.video);
      expect(items[1].isPhoto, isFalse);
    });

    test('falls back to photos when media is empty', () {
      final ad = Ad.fromJson(
        adJson(
          photos: const [
            'https://example.com/a.jpg',
            'https://example.com/b.jpg',
          ],
        ),
      );

      final items = resolveGalleryItems(ad);

      expect(items, hasLength(2));
      expect(items[0].url, 'https://example.com/a.jpg');
      expect(items[0].mediaType, AdMediaType.photo);
      expect(items[1].url, 'https://example.com/b.jpg');
    });

    test('resolves to an empty list when neither is populated', () {
      final ad = Ad.fromJson(adJson());

      expect(resolveGalleryItems(ad), isEmpty);
    });
  });
}
