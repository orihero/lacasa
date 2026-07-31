import { describe, expect, it } from 'vitest';
import { CROSSPOST_PROTOCOL_PACKAGE_NAME, PAGE_SOURCE, buildCrosspostPingMessage, buildJobDoneAction } from './index';

describe('@lacasa/crosspost-protocol root entry point', () => {
  it('exposes its own package name', () => {
    expect(CROSSPOST_PROTOCOL_PACKAGE_NAME).toBe('@lacasa/crosspost-protocol');
  });

  it('re-exports the ./messages module', () => {
    expect(buildCrosspostPingMessage('abc')).toEqual({ source: PAGE_SOURCE, type: 'CROSSPOST_PING', id: 'abc' });
  });

  it('re-exports the ./background module', () => {
    expect(buildJobDoneAction()).toEqual({ type: 'JOB_DONE' });
  });
});
