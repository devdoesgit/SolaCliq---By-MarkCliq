import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import { FILE_LINKS_MS } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  ActionDialog,
  Avatar,
  DialogButton,
  Facts,
  FileView,
  NoteDialog,
  QueryState,
  StatusPill,
} from '../../components';
import { formatDay, formatPaise, formatWhen } from '../../lib/format';
import { CATEGORY, EXPENSE } from '../../lib/labels';

/** W4: one expense with its bill, beside the list. */
export function ExpenseDetail({ expenseId }: { expenseId: string }) {
  const { orgId, to } = useOrg();
  const path = { org_id: orgId, expense_id: expenseId };
  const expense = useQuery({
    queryKey: ['org', orgId, 'expense', expenseId],
    queryFn: ({ signal }) =>
      unwrap(api.GET('/orgs/{org_id}/admin/expenses/{expense_id}', { params: { path }, signal })),
    // Its receipt link expires.
    refetchInterval: FILE_LINKS_MS,
  });

  return (
    <QueryState query={expense}>
      {(e) => (
        <section className="card claim" aria-label="Expense">
          <header className="claim-head">
            <Avatar name={e.owner_name} size="lg" />
            <div className="cell-main">
              <h2 className="claim-title">
                {CATEGORY[e.category]} · {formatPaise(e.amount)}
              </h2>
              <p className="cell-sub">
                From {e.owner_name} · {formatWhen(e.created_at)} · {e.reference}
              </p>
            </div>
            <StatusPill {...EXPENSE[e.status]} />
          </header>
          <div className="claim-body">
            <div className="claim-bill">
              {e.receipt ? (
                <FileView file={e.receipt} name="the receipt" />
              ) : (
                <p className="file-missing">No receipt was sent.</p>
              )}
            </div>
            <Facts
              items={[
                ['Task', e.task && <Link to={to(`tasks/${e.task.id}`)}>{e.task.title}</Link>],
                ['Customer', e.task?.customer_name],
                ['Their note', e.note],
                ['Spent on', formatDay(e.spent_on)],
                [
                  e.status === 'rejected' ? 'Not accepted because' : 'Sent back because',
                  e.admin_note,
                ],
                ['Their note on the new receipt', e.fix_note],
                ['Decided by', e.admin_name],
                ['Account ending', e.payout_last4],
              ]}
            />
          </div>
          <div className="claim-actions">
            {(e.status === 'in_review' || e.status === 'needs_fix') && (
              <DialogButton
                key={`reject-${e.status}`}
                label="Don't accept"
                variant="danger"
                dialog={(close) => (
                  <NoteDialog
                    title={`Don't accept ${formatPaise(e.amount)}?`}
                    body="It's closed and won't be paid. This can't be undone."
                    label="Reason"
                    help="They see this."
                    danger
                    confirm="Don't accept"
                    done="Not accepted."
                    onClose={close}
                    send={(note) =>
                      unwrap(
                        api.POST('/orgs/{org_id}/expenses/{expense_id}/reject', {
                          params: { path },
                          body: { note },
                        }),
                      )
                    }
                  />
                )}
              />
            )}
            {e.status === 'in_review' && (
              <>
                <DialogButton
                  label="Send back"
                  dialog={(close) => (
                    <NoteDialog
                      title="Send back"
                      label="What's wrong"
                      help="They see this and send a new receipt."
                      confirm="Send back"
                      done="Sent back."
                      onClose={close}
                      send={(note) =>
                        unwrap(
                          api.POST('/orgs/{org_id}/expenses/{expense_id}/return', {
                            params: { path },
                            body: { note },
                          }),
                        )
                      }
                    />
                  )}
                />
                <DialogButton
                  label={`Approve ${formatPaise(e.amount)}`}
                  icon="check"
                  variant="primary"
                  dialog={(close) => (
                    <ActionDialog
                      title={`Approve ${formatPaise(e.amount)}?`}
                      body={`${e.owner_name} is told. It then waits under To pay.`}
                      confirm="Approve"
                      done="Expense approved."
                      onClose={close}
                      run={() =>
                        unwrap(
                          api.POST('/orgs/{org_id}/expenses/{expense_id}/approve', {
                            params: { path },
                          }),
                        )
                      }
                    />
                  )}
                />
              </>
            )}
            {e.status === 'approved' && (
              <DialogButton
                label="Mark paid"
                variant="dark"
                dialog={(close) => (
                  <ActionDialog
                    title={`${formatPaise(e.amount)} paid to ${e.owner_name}?`}
                    body={`SolaCliq doesn't send money: pay them first. ${
                      e.payout_last4
                        ? `Their account ends ${e.payout_last4}.`
                        : "They haven't added a bank account."
                    } This can't be undone.`}
                    confirm="Yes, paid"
                    done="Expense marked paid."
                    onClose={close}
                    run={() =>
                      unwrap(
                        api.POST('/orgs/{org_id}/expenses/{expense_id}/paid', {
                          params: { path },
                        }),
                      )
                    }
                  />
                )}
              />
            )}
          </div>
        </section>
      )}
    </QueryState>
  );
}
