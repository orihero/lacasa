import { describe, expect, it } from 'vitest';
import {
  ASSISTED_CHANNELS,
  EXT_SOURCE,
  PAGE_SOURCE,
  buildCrosspostPingMessage,
  buildCrosspostPongMessage,
  buildCrosspostRequestMessage,
  buildCrosspostResultMessage,
  isAssistedChannel,
  isCrosspostPingMessage,
  isCrosspostPongMessage,
  isCrosspostRequestMessage,
  isCrosspostResultMessage,
  isExtensionMessage,
  isPageMessage,
} from './messages';
import type { CrosspostPingMessage, CrosspostPongMessage, CrosspostRequestMessage, CrosspostResultMessage } from './messages';

describe('isAssistedChannel', () => {
  it('accepts every channel the extension can drive', () => {
    for (const channel of ASSISTED_CHANNELS) {
      expect(isAssistedChannel(channel)).toBe(true);
    }
  });

  it('rejects channels outside the assisted subset', () => {
    expect(isAssistedChannel('TELEGRAM')).toBe(false);
    expect(isAssistedChannel('YOUTUBE')).toBe(false);
  });

  it('rejects non-string input', () => {
    expect(isAssistedChannel(undefined)).toBe(false);
    expect(isAssistedChannel(42)).toBe(false);
    expect(isAssistedChannel(null)).toBe(false);
  });
});

describe('builders', () => {
  it('buildCrosspostRequestMessage tags source/type and passes fields through', () => {
    const msg = buildCrosspostRequestMessage({
      requestId: 'req-1',
      channel: 'OLX',
      adId: 'ad-1',
      ad: { title: 'Nice flat' },
      photoUrls: ['https://example.com/1.jpg'],
      token: 'tok',
      apiBase: 'https://api.example.com',
    });
    expect(msg).toEqual({
      source: PAGE_SOURCE,
      type: 'CROSSPOST_REQUEST',
      requestId: 'req-1',
      channel: 'OLX',
      adId: 'ad-1',
      ad: { title: 'Nice flat' },
      photoUrls: ['https://example.com/1.jpg'],
      token: 'tok',
      apiBase: 'https://api.example.com',
    });
  });

  it('buildCrosspostPingMessage', () => {
    expect(buildCrosspostPingMessage('ping-1')).toEqual({ source: PAGE_SOURCE, type: 'CROSSPOST_PING', id: 'ping-1' });
  });

  it('buildCrosspostPongMessage', () => {
    expect(buildCrosspostPongMessage('ping-1')).toEqual({ source: EXT_SOURCE, type: 'CROSSPOST_PONG', id: 'ping-1' });
  });

  it('buildCrosspostResultMessage propagates an error when not ok', () => {
    expect(buildCrosspostResultMessage({ requestId: 'req-1', ok: false, error: 'boom' })).toEqual({
      source: EXT_SOURCE,
      type: 'CROSSPOST_RESULT',
      requestId: 'req-1',
      ok: false,
      error: 'boom',
    });
  });

  it('buildCrosspostResultMessage omits error when ok', () => {
    const msg = buildCrosspostResultMessage({ requestId: 'req-1', ok: true });
    expect(msg.error).toBeUndefined();
    expect(msg.ok).toBe(true);
  });
});

describe('type guards', () => {
  const request: CrosspostRequestMessage = buildCrosspostRequestMessage({
    requestId: 'r',
    channel: 'INSTAGRAM',
    adId: 'a',
    ad: {},
    photoUrls: [],
    token: 't',
    apiBase: 'https://api.example.com',
  });
  const ping: CrosspostPingMessage = buildCrosspostPingMessage('p');
  const pong: CrosspostPongMessage = buildCrosspostPongMessage('p');
  const result: CrosspostResultMessage = buildCrosspostResultMessage({ requestId: 'r', ok: true });

  it('isPageMessage accepts page-sourced envelopes and rejects everything else', () => {
    expect(isPageMessage(request)).toBe(true);
    expect(isPageMessage(ping)).toBe(true);
    expect(isPageMessage(pong)).toBe(false);
    expect(isPageMessage(result)).toBe(false);
    expect(isPageMessage(null)).toBe(false);
    expect(isPageMessage('not an object')).toBe(false);
    expect(isPageMessage({ source: PAGE_SOURCE, type: 'SOMETHING_ELSE' })).toBe(false);
  });

  it('isExtensionMessage accepts extension-sourced envelopes and rejects everything else', () => {
    expect(isExtensionMessage(pong)).toBe(true);
    expect(isExtensionMessage(result)).toBe(true);
    expect(isExtensionMessage(request)).toBe(false);
    expect(isExtensionMessage(ping)).toBe(false);
    expect(isExtensionMessage(undefined)).toBe(false);
  });

  it('narrows to the exact message variant', () => {
    expect(isCrosspostRequestMessage(request)).toBe(true);
    expect(isCrosspostRequestMessage(ping)).toBe(false);

    expect(isCrosspostPingMessage(ping)).toBe(true);
    expect(isCrosspostPingMessage(request)).toBe(false);

    expect(isCrosspostPongMessage(pong)).toBe(true);
    expect(isCrosspostPongMessage(result)).toBe(false);

    expect(isCrosspostResultMessage(result)).toBe(true);
    expect(isCrosspostResultMessage(pong)).toBe(false);
  });

  it('an exhaustive switch over PostMessageEnvelope compiles and dispatches correctly', () => {
    function describeMsg(msg: CrosspostRequestMessage | CrosspostPingMessage | CrosspostPongMessage | CrosspostResultMessage): string {
      switch (msg.type) {
        case 'CROSSPOST_REQUEST':
          return `request:${msg.channel}`;
        case 'CROSSPOST_PING':
          return `ping:${msg.id}`;
        case 'CROSSPOST_PONG':
          return `pong:${msg.id}`;
        case 'CROSSPOST_RESULT':
          return `result:${msg.ok}`;
      }
    }
    expect(describeMsg(request)).toBe('request:INSTAGRAM');
    expect(describeMsg(ping)).toBe('ping:p');
    expect(describeMsg(pong)).toBe('pong:p');
    expect(describeMsg(result)).toBe('result:true');
  });
});
