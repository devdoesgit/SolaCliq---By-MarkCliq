import { useQuery } from '@tanstack/react-query';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';

// People act in the app while the admin works: the counts follow them.
const FOLLOW_MS = 60 * 1000;

/** Everything waiting for the admin: the inbox and its count. */
export function useReview(orgId: string, enabled = true) {
  return useQuery({
    queryKey: ['org', orgId, 'review'],
    enabled,
    refetchInterval: FOLLOW_MS,
    queryFn: ({ signal }) =>
      unwrap(api.GET('/orgs/{org_id}/review', { params: { path: { org_id: orgId } }, signal })),
  });
}

/** How many notifications are unread. */
export function useUnread(orgId: string, enabled = true) {
  return useQuery({
    queryKey: ['org', orgId, 'unread'],
    enabled,
    refetchInterval: FOLLOW_MS,
    queryFn: async ({ signal }) => {
      const feed = await unwrap(
        api.GET('/orgs/{org_id}/notifications', {
          params: { path: { org_id: orgId }, query: { limit: 1 } },
          signal,
        }),
      );
      return feed.unread_count;
    },
  });
}
