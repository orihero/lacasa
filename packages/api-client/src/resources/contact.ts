/**
 * @lacasa/api-client/resources/contact — the marketing site's public contact
 * form (apps/web/src/routes/aboutPageNew/components/ContactUs.jsx), ported
 * off its hardcoded-token direct Telegram call onto POST /api/contact
 * (see apps/api/src/routes/contact.js). Its own resource file rather than
 * folding into resources/utils.ts: unlike the currency/nearby-places reads
 * there, this is a write with its own request body type from @lacasa/domain.
 */
import type { ContactInput } from '@lacasa/domain';
import type { ApiClient } from '../core/client';

export function createContactResource(client: ApiClient) {
  return {
    /** POST /api/contact — public, unauthenticated, rate-limited server-side. */
    submit(input: ContactInput) {
      return client.request<{ ok: boolean }>({ method: 'POST', path: '/contact', body: input });
    },
  };
}

export type ContactResource = ReturnType<typeof createContactResource>;
