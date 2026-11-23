import { MutationCache, QueryCache, QueryClient } from '@tanstack/react-query';
import { ApiProblem } from '../api/problem';
import { meQueryKey } from '../features/auth/session';

/** The company stopped being this person's: what `/me` says now decides. */
const COMPANY_CHANGED = new Set([
  'org.not_member',
  'org.role_not_allowed',
  'org.pending',
  'org.suspended',
  'org.rejected',
]);

export function createQueryClient(): QueryClient {
  const onError = (error: Error) => {
    if (!(error instanceof ApiProblem)) return;
    // Only after a refresh failed: the login is over.
    if (error.status === 401) client.setQueryData(meQueryKey, null);
    if (COMPANY_CHANGED.has(error.code)) void client.invalidateQueries({ queryKey: meQueryKey });
  };
  const client: QueryClient = new QueryClient({
    queryCache: new QueryCache({ onError }),
    mutationCache: new MutationCache({ onError }),
    defaultOptions: {
      queries: {
        // Installers, agents and customers act while the admin works, so every
        // screen opened and every return to the tab reads again (no staleTime).
        refetchOnWindowFocus: true,
        retry: (count, error) =>
          count < 1 && !(error instanceof ApiProblem && error.status >= 400 && error.status < 500),
      },
    },
  });
  return client;
}
