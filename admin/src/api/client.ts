import createClient from 'openapi-fetch';
import { API_BASE_URL } from '../config';
import type { paths } from './schema';

/**
 * The typed API client, generated from api/openapi.yaml. The admin website
 * signs in with a session cookie, so every request sends credentials.
 */
export const api = createClient<paths>({
  baseUrl: API_BASE_URL,
  credentials: 'include',
});

export type { components, paths } from './schema';
