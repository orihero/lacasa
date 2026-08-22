import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/features/photo_gallery/formatters/gallery_formatters.dart';

void main() {
  group('GalleryFormatters.pageCounter', () {
    test('formats 1-indexed n/total', () {
      expect(GalleryFormatters.pageCounter(index: 0, total: 5), '1/5');
      expect(GalleryFormatters.pageCounter(index: 4, total: 5), '5/5');
    });

    test('single-item gallery', () {
      expect(GalleryFormatters.pageCounter(index: 0, total: 1), '1/1');
    });

    test('total <= 0 degrades to 0/0 rather than dividing by nothing', () {
      expect(GalleryFormatters.pageCounter(index: 0, total: 0), '0/0');
    });
  });
}
