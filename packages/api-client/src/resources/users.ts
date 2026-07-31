/**
 * @lacasa/api-client/resources/users — ports the PATCH /users/me call
 * inlined in apps/web's profileUpdatePage.jsx and ProfileSetting.jsx.
 */
import type { UserUpdateInput } from '@lacasa/domain';
import type { ApiClient } from '../core/client';
import type { AuthUser } from './auth';

export interface UpdateMeResponse {
  user: AuthUser;
}

export function createUsersResource(client: ApiClient) {
  return {
    updateMe(input: UserUpdateInput) {
      return client.request<UpdateMeResponse>({ method: 'PATCH', path: '/users/me', body: input });
    },
  };
}

export type UsersResource = ReturnType<typeof createUsersResource>;
