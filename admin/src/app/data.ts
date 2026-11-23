import { useInfiniteQuery, useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap } from '../api/problem';
import type { Member } from '../api/types';

// Signed file links last 15 minutes.
export const FILE_LINKS_MS = 10 * 60 * 1000;

interface Page<T> {
  items: T[];
  page: { next_cursor?: string | null };
}

/** A cursor-paged read of one company's list. */
export function usePages<T>(
  orgId: string,
  key: readonly unknown[],
  read: (cursor: string | undefined, signal: AbortSignal) => Promise<Page<T>>,
) {
  return useInfiniteQuery({
    queryKey: ['org', orgId, ...key],
    queryFn: ({ pageParam, signal }) => read(pageParam, signal),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (last) => last.page.next_cursor ?? undefined,
  });
}

/** Every installer still in the company, for choosing who gets a task. */
export function useInstallers(orgId: string) {
  return useEveryMember(orgId, 'worker');
}

/** Every Sales Agent still in the company, for handing out leads. */
export function useAgents(orgId: string) {
  return useEveryMember(orgId, 'agent');
}

/** The company's 7 stages, with what a new task at each asks for (F19). */
export function useStages(orgId: string) {
  return useQuery({
    queryKey: ['org', orgId, 'stages'],
    queryFn: async ({ signal }) =>
      (
        await unwrap(
          api.GET('/orgs/{org_id}/stages', { params: { path: { org_id: orgId } }, signal }),
        )
      ).stages,
  });
}

/** The whole team, or one role of it. */
export function useEveryMember(orgId: string, role?: 'worker' | 'agent') {
  return useQuery({
    queryKey: ['org', orgId, 'every-member', role ?? 'all'],
    queryFn: async ({ signal }) => {
      const all: Member[] = [];
      let cursor: string | undefined;
      do {
        const page = await unwrap(
          api.GET('/orgs/{org_id}/members', {
            params: { path: { org_id: orgId }, query: { role, limit: 100, cursor } },
            signal,
          }),
        );
        all.push(...page.items);
        cursor = page.page.next_cursor ?? undefined;
      } while (cursor);
      return all;
    },
  });
}

/** The totals behind the overview and the money lists' numbers. */
export function useOverview(orgId: string) {
  return useQuery({
    queryKey: ['org', orgId, 'overview'],
    queryFn: ({ signal }) =>
      unwrap(
        api.GET('/orgs/{org_id}/admin/overview', { params: { path: { org_id: orgId } }, signal }),
      ),
  });
}

/** The company's settings, with the stage names. */
export function useSettings(orgId: string) {
  return useQuery({
    queryKey: ['org', orgId, 'settings'],
    queryFn: ({ signal }) =>
      unwrap(
        api.GET('/orgs/{org_id}/admin/settings', { params: { path: { org_id: orgId } }, signal }),
      ),
  });
}
