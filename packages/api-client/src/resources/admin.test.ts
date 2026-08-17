import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createAdminResource } from './admin';

function setup(response: unknown = {}) {
  const { transport, calls } = createFakeTransport(response);
  const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage('t'), baseUrl: 'http://api.test' });
  return { admin: createAdminResource(client), calls };
}

/** The empty page every list test that doesn't care about the body resolves to. */
const emptyPage = { items: [], nextCursor: null };

describe('admin resource', () => {
  it('overview() requests GET /admin/overview', async () => {
    const { admin, calls } = setup({ users: { total: 0 } });

    await admin.overview();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/admin/overview' });
  });

  it('listApplications() requests GET /admin/applications and sends no query at all', async () => {
    const { admin, calls } = setup(emptyPage);

    await admin.listApplications();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/admin/applications' });
    // toEqual ignores undefined-valued keys, which is exactly the semantics
    // every Transport applies to QueryParams (apps/console's buildUrl skips
    // them, apps/web's axios does the same) — so this asserts nothing at all
    // reaches the wire, and in particular that `status` is absent rather
    // than sent empty. The server's own default (pending) has to win.
    expect(calls[0]!.query).toEqual({});
  });

  it('listApplications passes status and both pagination params through', async () => {
    const { admin, calls } = setup(emptyPage);

    await admin.listApplications({ status: 'approved', limit: 50, cursor: 'user-42' });

    expect(calls[0]!.query).toEqual({ status: 'approved', limit: 50, cursor: 'user-42' });
  });

  it('listApplications sends only the params it was given', async () => {
    const { admin, calls } = setup(emptyPage);

    await admin.listApplications({ cursor: 'user-42' });

    expect(calls[0]!.query).toEqual({ cursor: 'user-42' });
    expect(calls[0]!.query?.status).toBeUndefined();
    expect(calls[0]!.query?.limit).toBeUndefined();
  });

  it('approveApplication POSTs to /admin/applications/:userId/approve with no body', async () => {
    const { admin, calls } = setup({ user: { id: 'user-1', role: 'agent' } });

    await admin.approveApplication('user-1');

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/admin/applications/user-1/approve',
    });
    expect(calls[0]!.body).toBeUndefined();
  });

  it('rejectApplication POSTs to /admin/applications/:userId/reject', async () => {
    const { admin, calls } = setup({ user: { id: 'user-1', role: 'user' } });

    await admin.rejectApplication('user-1');

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/admin/applications/user-1/reject',
    });
  });

  it('listUsers() requests GET /admin/users with an empty query', async () => {
    const { admin, calls } = setup(emptyPage);

    await admin.listUsers();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/admin/users' });
    expect(calls[0]!.query).toEqual({});
  });

  it('listUsers passes the search term, both filters and the pagination params through', async () => {
    const { admin, calls } = setup(emptyPage);

    await admin.listUsers({
      q: 'jamshid',
      role: 'agent',
      realtorStatus: 'approved',
      limit: 100,
      cursor: 'user-9',
    });

    expect(calls[0]!.query).toEqual({
      q: 'jamshid',
      role: 'agent',
      realtorStatus: 'approved',
      limit: 100,
      cursor: 'user-9',
    });
  });

  it('listUsers omits the filters it was not given', async () => {
    const { admin, calls } = setup(emptyPage);

    await admin.listUsers({ q: 'jamshid' });

    expect(calls[0]!.query).toEqual({ q: 'jamshid' });
  });

  it('getUser requests GET /admin/users/:id', async () => {
    const { admin, calls } = setup({ user: { id: 'user-1' } });

    await admin.getUser('user-1');

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/admin/users/user-1' });
  });

  it('setUserRole PATCHes /admin/users/:id/role with the wire-format role key', async () => {
    const { admin, calls } = setup({ user: { id: 'user-1', role: 'admin' } });

    await admin.setUserRole('user-1', 'admin');

    expect(calls[0]).toMatchObject({
      method: 'PATCH',
      url: 'http://api.test/admin/users/user-1/role',
      body: { role: 'admin' },
    });
  });

  it('listAudit() requests GET /admin/audit with an empty query', async () => {
    const { admin, calls } = setup(emptyPage);

    await admin.listAudit();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/admin/audit' });
    expect(calls[0]!.query).toEqual({});
  });

  it('listAudit passes the type filter, agentId and the pagination params through', async () => {
    const { admin, calls } = setup(emptyPage);

    await admin.listAudit({ type: 'lead_status_changed', agentId: 'agent-3', limit: 25, cursor: 'ev-7' });

    expect(calls[0]!.query).toEqual({
      type: 'lead_status_changed',
      agentId: 'agent-3',
      limit: 25,
      cursor: 'ev-7',
    });
  });

  it('returns the paged envelope the server sent, cursor included', async () => {
    const { admin } = setup({ items: [{ id: 'ev-1' }], nextCursor: 'ev-1' });

    const page = await admin.listAudit();

    expect(page).toEqual({ items: [{ id: 'ev-1' }], nextCursor: 'ev-1' });
  });

  it('sends the admin token on every call — these endpoints are all authenticated', async () => {
    const { admin, calls } = setup(emptyPage);

    await admin.listUsers();

    expect(calls[0]!.headers?.Authorization).toBe('Bearer t');
  });
});
