import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { ApiNotification } from '../../api/types';
import { usePages } from '../../app/data';
import { useOrg } from '../../app/org';
import { Button, Notice, PageHeader, QueryState } from '../../components';
import { formatDateTime } from '../../lib/format';
import { useUnread } from './queries';

function opens(n: ApiNotification): string | undefined {
  if (n.kind === 'payment_claimed') return 'payments?status=claimed';
  if (n.task_id) return `tasks/${n.task_id}`;
  if (n.expense_id) return `expenses/${n.expense_id}`;
  if (n.customer_id) return `customers/${n.customer_id}`;
  return undefined;
}

/** W5: what happened, newest first. */
export function NotificationsPage() {
  const { orgId, to } = useOrg();
  const client = useQueryClient();
  const unread = useUnread(orgId);
  const feed = usePages(orgId, ['notifications'], (cursor, signal) =>
    unwrap(
      api.GET('/orgs/{org_id}/notifications', {
        params: { path: { org_id: orgId }, query: { cursor } },
        signal,
      }),
    ),
  );
  // Not a decision, so no dialog.
  const readAll = useMutation({
    mutationFn: () =>
      unwrap(
        api.POST('/orgs/{org_id}/notifications/read', { params: { path: { org_id: orgId } } }),
      ),
    onSuccess: () => client.invalidateQueries({ queryKey: ['org', orgId] }),
  });
  return (
    <>
      <PageHeader
        title="Notifications"
        meta="What happened, newest first"
        actions={
          !!unread.data && (
            <Button compact disabled={readAll.isPending} onClick={() => readAll.mutate()}>
              Mark all read
            </Button>
          )
        }
      />
      {readAll.error && <Notice tone="danger" announce title="Couldn't mark them read" />}
      <QueryState query={feed}>
        {({ pages }) => {
          const items = pages.flatMap((page) => page.items);
          if (items.length === 0) return <p className="empty">No notifications yet.</p>;
          return (
            <>
              <ul className="inbox card" aria-label="Notifications">
                {items.map((n) => {
                  const path = opens(n);
                  const text = (
                    <span className="cell-main">
                      <span className="t-row-title">
                        {!n.read && <span className="visually-hidden">Unread: </span>}
                        {n.title}
                      </span>
                      <span>{n.body}</span>
                      <span className="cell-sub">{formatDateTime(n.at)}</span>
                    </span>
                  );
                  const look = n.read ? 'inbox-row' : 'inbox-row inbox-unread';
                  return (
                    <li key={n.id}>
                      {path ? (
                        <Link className={look} to={to(path)}>
                          {text}
                        </Link>
                      ) : (
                        <div className={look}>{text}</div>
                      )}
                    </li>
                  );
                })}
              </ul>
              {feed.hasNextPage && (
                <div className="more">
                  <Button
                    compact
                    disabled={feed.isFetchingNextPage}
                    onClick={() => void feed.fetchNextPage()}
                  >
                    Show more
                  </Button>
                </div>
              )}
            </>
          );
        }}
      </QueryState>
    </>
  );
}
