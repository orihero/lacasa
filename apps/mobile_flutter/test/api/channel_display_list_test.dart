// The boundary between the two Channel lists, pinned.
//
// Channel.allChannels mirrors the server's ALL_CHANNELS constant driving
// GET /publish/ads/:adId/status, and the server synthesizes a PENDING
// placeholder row for every entry in it that has no publish attempt.
// Channel.publishSurfaceChannels is app-only render order for the publish
// surfaces and names four channels apps/api has never heard of.
//
// Merge the two — append a display-only channel to allChannels — and every
// ad grows a permanently-PENDING status row that nothing in the app can
// ever clear. That is not a cosmetic bug, and it is an easy one to
// introduce a year from now while adding channel number ten. This file is
// the tripwire: it fails the moment the wire list stops being exactly the
// server's four, or the display list starts naming something that isn't a
// real publish surface.

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';

void main() {
  group('Channel.allChannels (the wire contract)', () {
    test('is exactly the server ALL_CHANNELS four, in the server order', () {
      expect(Channel.allChannels, [
        Channel.telegram,
        Channel.instagram,
        Channel.youtube,
        Channel.olx,
      ]);
      // Spelled out separately from the list equality above so a failure
      // message says "5 rows" loudly rather than dumping two long lists:
      // the length IS the regression signal here.
      expect(Channel.allChannels.length, 4);
    });

    test('every member round-trips through wire/fromWire', () {
      for (final channel in Channel.allChannels) {
        expect(
          Channel.fromWire(channel.wire),
          channel,
          reason:
              '${channel.name} must survive the round trip — allChannels is '
              'only meaningful if each entry is a real server value',
        );
      }
    });

    test('holds no display-only channel', () {
      for (final channel in const [
        Channel.threads,
        Channel.facebookMarketplace,
        Channel.x,
        Channel.linkedin,
      ]) {
        expect(
          Channel.allChannels.contains(channel),
          isFalse,
          reason:
              'Appending ${channel.name} here gives every ad a PENDING '
              'publish-status row that can never clear — put it in '
              'Channel.publishSurfaceChannels instead',
        );
      }
    });
  });

  group('Channel.publishSurfaceChannels (app-side display order)', () {
    test('is the eight publish-surface rows, in render order', () {
      expect(Channel.publishSurfaceChannels, [
        Channel.instagram,
        Channel.telegram,
        Channel.youtube,
        Channel.olx,
        Channel.threads,
        Channel.facebookMarketplace,
        Channel.x,
        Channel.linkedin,
      ]);
    });

    test('excludes unknown (a decode fallback)', () {
      expect(Channel.publishSurfaceChannels, isNot(contains(Channel.unknown)));
    });

    test('only telegram and instagram claim a server publish path', () {
      final live = Channel.values.where((c) => c.hasServerPublishPath).toList();
      expect(live, [Channel.telegram, Channel.instagram]);
    });
  });

  group('display-only channels are unreachable from the wire', () {
    test('fromWire never produces one, whatever the server sends', () {
      for (final value in const [
        'THREADS',
        'X',
        'LINKEDIN',
        'FACEBOOK_MARKETPLACE',
      ]) {
        expect(
          Channel.fromWire(value),
          Channel.unknown,
          reason:
              "apps/api has no '$value' in its Channel enum; decoding one "
              'into a display-only member would make a FAILED/PENDING row '
              'for it reachable',
        );
      }
    });

    test('wire throws rather than inventing a string the API would 400 on', () {
      for (final channel in const [
        Channel.threads,
        Channel.facebookMarketplace,
        Channel.x,
        Channel.linkedin,
      ]) {
        expect(
          () => channel.wire,
          throwsStateError,
          reason: '${channel.name} has no server representation',
        );
      }
    });
  });
}
