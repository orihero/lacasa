/**
 * @lacasa/api-client — the platform-agnostic HTTP layer shared by apps/web
 * and (once it exists) apps/mobile. Depends only on @lacasa/domain: no
 * axios, no localStorage, no fetch assumptions baked into src/core (see
 * src/core/transport.ts). Each platform supplies a Transport + TokenStorage
 * and gets a fully-typed, resource-grouped client back from
 * createLaCasaApiClient().
 */
import { DOMAIN_PACKAGE_NAME } from '@lacasa/domain';
import { createApiClient, type CreateApiClientOptions } from './core/client';
import { createAdminResource } from './resources/admin';
import { createAdsResource } from './resources/ads';
import { createAgentsResource } from './resources/agents';
import { createAuthResource } from './resources/auth';
import { createContactResource } from './resources/contact';
import { createCoworkersResource } from './resources/coworkers';
import { createLeadsResource } from './resources/leads';
import { createPublishResource } from './resources/publish';
import { createSavedAdsResource } from './resources/savedAds';
import { createStatisticsResource } from './resources/statistics';
import { createUploadsResource } from './resources/uploads';
import { createUsersResource } from './resources/users';
import { createUtilsResource } from './resources/utils';

export * from './core/transport';
export * from './core/client';

export * from './resources/admin';
export * from './resources/ads';
export * from './resources/agents';
export * from './resources/auth';
export * from './resources/contact';
export * from './resources/coworkers';
export * from './resources/leads';
export * from './resources/publish';
export * from './resources/savedAds';
export * from './resources/statistics';
export * from './resources/uploads';
export * from './resources/users';
export * from './resources/utils';

export const API_CLIENT_PACKAGE_NAME = '@lacasa/api-client';

export function describeDependency(): string {
  return `${API_CLIENT_PACKAGE_NAME} depends on ${DOMAIN_PACKAGE_NAME}`;
}

export interface LaCasaApiClient {
  admin: ReturnType<typeof createAdminResource>;
  ads: ReturnType<typeof createAdsResource>;
  agents: ReturnType<typeof createAgentsResource>;
  auth: ReturnType<typeof createAuthResource>;
  contact: ReturnType<typeof createContactResource>;
  coworkers: ReturnType<typeof createCoworkersResource>;
  leads: ReturnType<typeof createLeadsResource>;
  publish: ReturnType<typeof createPublishResource>;
  savedAds: ReturnType<typeof createSavedAdsResource>;
  statistics: ReturnType<typeof createStatisticsResource>;
  uploads: ReturnType<typeof createUploadsResource>;
  users: ReturnType<typeof createUsersResource>;
  utils: ReturnType<typeof createUtilsResource>;
}

/**
 * Builds the full, resource-grouped client: `createLaCasaApiClient(...).ads.getAds(...)`,
 * `.leads.list()`, `.publish.publishInstagram(...)`, etc. Each resource
 * shares the single underlying ApiClient (and therefore the same injected
 * Transport + TokenStorage + baseUrl).
 */
export function createLaCasaApiClient(options: CreateApiClientOptions): LaCasaApiClient {
  const client = createApiClient(options);
  return {
    admin: createAdminResource(client),
    ads: createAdsResource(client),
    agents: createAgentsResource(client),
    auth: createAuthResource(client),
    contact: createContactResource(client),
    coworkers: createCoworkersResource(client),
    leads: createLeadsResource(client),
    publish: createPublishResource(client),
    savedAds: createSavedAdsResource(client),
    statistics: createStatisticsResource(client),
    uploads: createUploadsResource(client),
    users: createUsersResource(client),
    utils: createUtilsResource(client),
  };
}
