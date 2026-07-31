import { describe, expect, it } from 'vitest';
import {
  BACKGROUND_REQUEST_TYPES,
  START_URLS,
  buildConfirmAction,
  buildCrosspostRequestAction,
  buildFetchPhotosAction,
  buildJobDoneAction,
  buildJobRequestAction,
  buildMapFieldsAction,
  err,
  isBackgroundRequest,
  isConfirmAction,
  isCrosspostRequestAction,
  isErrResponse,
  isFetchPhotosAction,
  isJobDoneAction,
  isJobRequestAction,
  isMapFieldsAction,
  isOkResponse,
  ok,
} from './background';
import type { BackgroundRequest } from './background';

const job = { channel: 'OLX' as const, adId: 'ad-1', ad: {}, photoUrls: [], token: 't', apiBase: 'https://api.example.com' };

describe('builders', () => {
  it('buildCrosspostRequestAction', () => {
    expect(buildCrosspostRequestAction(job)).toEqual({ type: 'CROSSPOST_REQUEST', job });
  });

  it('buildJobRequestAction', () => {
    expect(buildJobRequestAction()).toEqual({ type: 'JOB_REQUEST' });
  });

  it('buildMapFieldsAction', () => {
    const snapshot = [{ ref: 'r1', tag: 'input', path: [0] }];
    expect(buildMapFieldsAction('category', snapshot)).toEqual({ type: 'MAP_FIELDS', step: 'category', snapshot });
  });

  it('buildConfirmAction', () => {
    expect(buildConfirmAction({ event: 'published', externalId: 'ext-1' })).toEqual({
      type: 'CONFIRM',
      event: 'published',
      externalId: 'ext-1',
    });
  });

  it('buildFetchPhotosAction', () => {
    const urls = ['https://example.com/1.jpg'];
    expect(buildFetchPhotosAction(urls)).toEqual({ type: 'FETCH_PHOTOS', urls });
  });

  it('buildJobDoneAction', () => {
    expect(buildJobDoneAction()).toEqual({ type: 'JOB_DONE' });
  });
});

describe('response helpers', () => {
  it('ok() wraps data with ok: true', () => {
    const res = ok({ started: true as const });
    expect(res).toEqual({ ok: true, data: { started: true } });
    expect(isOkResponse(res)).toBe(true);
    expect(isErrResponse(res)).toBe(false);
  });

  it('err() wraps a message with ok: false', () => {
    const res = err('no active job');
    expect(res).toEqual({ ok: false, error: 'no active job' });
    expect(isErrResponse(res)).toBe(true);
    expect(isOkResponse(res)).toBe(false);
  });
});

describe('START_URLS', () => {
  it('has an entry for every assisted channel', () => {
    expect(START_URLS.OLX).toBe('https://www.olx.uz/d/add/');
    expect(START_URLS.INSTAGRAM).toBe('https://www.instagram.com/');
  });
});

describe('isBackgroundRequest', () => {
  it('accepts every known action type', () => {
    for (const type of BACKGROUND_REQUEST_TYPES) {
      expect(isBackgroundRequest({ type })).toBe(true);
    }
  });

  it('rejects unknown or malformed input', () => {
    expect(isBackgroundRequest({ type: 'NOT_A_REAL_ACTION' })).toBe(false);
    expect(isBackgroundRequest({})).toBe(false);
    expect(isBackgroundRequest(null)).toBe(false);
    expect(isBackgroundRequest('CROSSPOST_REQUEST')).toBe(false);
    expect(isBackgroundRequest(undefined)).toBe(false);
  });
});

describe('per-action type guards', () => {
  const requestAction = buildCrosspostRequestAction(job);
  const jobRequestAction = buildJobRequestAction();
  const mapFieldsAction = buildMapFieldsAction('caption', []);
  const confirmAction = buildConfirmAction({ event: 'drafted' });
  const fetchPhotosAction = buildFetchPhotosAction([]);
  const jobDoneAction = buildJobDoneAction();
  const all: BackgroundRequest[] = [requestAction, jobRequestAction, mapFieldsAction, confirmAction, fetchPhotosAction, jobDoneAction];

  it('isCrosspostRequestAction narrows only CROSSPOST_REQUEST', () => {
    expect(all.filter(isCrosspostRequestAction)).toEqual([requestAction]);
  });

  it('isJobRequestAction narrows only JOB_REQUEST', () => {
    expect(all.filter(isJobRequestAction)).toEqual([jobRequestAction]);
  });

  it('isMapFieldsAction narrows only MAP_FIELDS', () => {
    expect(all.filter(isMapFieldsAction)).toEqual([mapFieldsAction]);
  });

  it('isConfirmAction narrows only CONFIRM', () => {
    expect(all.filter(isConfirmAction)).toEqual([confirmAction]);
  });

  it('isFetchPhotosAction narrows only FETCH_PHOTOS', () => {
    expect(all.filter(isFetchPhotosAction)).toEqual([fetchPhotosAction]);
  });

  it('isJobDoneAction narrows only JOB_DONE', () => {
    expect(all.filter(isJobDoneAction)).toEqual([jobDoneAction]);
  });

  it('an exhaustive switch over BackgroundRequest compiles and dispatches correctly', () => {
    function describeAction(msg: BackgroundRequest): string {
      switch (msg.type) {
        case 'CROSSPOST_REQUEST':
          return `crosspost:${msg.job.channel}`;
        case 'JOB_REQUEST':
          return 'job-request';
        case 'MAP_FIELDS':
          return `map-fields:${msg.step}`;
        case 'CONFIRM':
          return `confirm:${msg.event}`;
        case 'FETCH_PHOTOS':
          return `fetch-photos:${msg.urls.length}`;
        case 'JOB_DONE':
          return 'job-done';
      }
    }
    expect(all.map(describeAction)).toEqual(['crosspost:OLX', 'job-request', 'map-fields:caption', 'confirm:drafted', 'fetch-photos:0', 'job-done']);
  });
});
