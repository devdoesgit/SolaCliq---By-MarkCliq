import { useInfiniteQuery, useQuery } from '@tanstack/react-query';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { OrgStatus } from '../../api/types';

/*
  MarkCliq's reads (F22), under their own key: a company's decisions
  read the company's data again, these MarkCliq's (`ActionDialog`'s
  `refresh`).
*/
export const PLATFORM = ['platform'] as const;

/** The companies with one status, newest first, a page at a time. */
export function useCompanies(status: OrgStatus) {
  return useInfiniteQuery({
    queryKey: [...PLATFORM, 'companies', status],
    queryFn: ({ pageParam, signal }) =>
      unwrap(
        api.GET('/platform/orgs', { params: { query: { status, cursor: pageParam } }, signal }),
      ),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (last) => last.page.next_cursor ?? undefined,
  });
}

// A full page of the largest size: past it, the count reads "100+".
const COUNTED = 100;

/** How many are waiting for review, for the home card and the tab. */
export function useWaiting(enabled = true) {
  return useQuery({
    queryKey: [...PLATFORM, 'waiting'],
    enabled,
    queryFn: async ({ signal }) => {
      const page = await unwrap(
        api.GET('/platform/orgs', {
          params: { query: { status: 'pending', limit: COUNTED } },
          signal,
        }),
      );
      return page.page.next_cursor ? `${COUNTED}+` : String(page.items.length);
    },
  });
}

export function useCompany(orgId: string) {
  return useQuery({
    queryKey: [...PLATFORM, 'company', orgId],
    queryFn: ({ signal }) =>
      unwrap(api.GET('/platform/orgs/{org_id}', { params: { path: { org_id: orgId } }, signal })),
  });
}
