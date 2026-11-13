import createClient from 'openapi-fetch';
import { API_BASE_URL } from '../config';
import { withRefresh } from './refresh';
import type { paths } from './schema';

/**
 * The typed API client, generated from api/openapi.yaml. The admin website
 * signs in with cookies, so every request sends credentials, and a 401
 * refreshes the cookies once and retries (see `refresh.ts`).
 */
export const api = createClient<paths>({
  baseUrl: API_BASE_URL,
  credentials: 'include',
  fetch: withRefresh(API_BASE_URL),
});

export type { components, paths } from './schema';
