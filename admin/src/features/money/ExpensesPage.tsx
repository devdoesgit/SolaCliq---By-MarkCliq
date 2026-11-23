import { useState } from 'react';
import { Link, useParams, useSearchParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { ExpenseStatus } from '../../api/types';
import { usePages } from '../../app/data';
import { useOrg } from '../../app/org';
import { Button, Icon, PageHeader, QueryState, readFilter } from '../../components';
import { formatDay, formatPaise } from '../../lib/format';
import { CATEGORY, EXPENSE } from '../../lib/labels';
import { ExpenseDetail } from './ExpenseDetail';

const FILTERS: { value: ExpenseStatus | ''; label: string }[] = [
  { value: 'in_review', label: 'Pending' },
  { value: 'approved', label: EXPENSE.approved.label },
  { value: 'needs_fix', label: EXPENSE.needs_fix.label },
  { value: 'paid', label: EXPENSE.paid.label },
  { value: 'rejected', label: EXPENSE.rejected.label },
  { value: '', label: 'All' },
];

/** W4: everyone's expenses: the list, and the one being decided beside it. */
export function ExpensesPage() {
  const { expenseId } = useParams();
  const [params] = useSearchParams();
  // An opened one can have any status, so the list beside it shows them all.
  const status = readFilter(params.get('status'), FILTERS, expenseId ? '' : 'in_review');
  return (
    <>
      <PageHeader title="Expenses" meta="Installers and sales log expenses with a bill photo" />
      <Claims key={status || 'all'} status={status} openId={expenseId} />
    </>
  );
}

/*
  The list and the open claim
  ----------------------------------------------------------------------
  - with none chosen the first opens, and stays: a claim arriving on top
    mustn't change what is under the admin's cursor
*/
function Claims({ status, openId }: { status: ExpenseStatus | ''; openId?: string }) {
  const { orgId, to } = useOrg();
  const expenses = usePages(orgId, ['expenses', status], (cursor, signal) =>
    unwrap(
      api.GET('/orgs/{org_id}/admin/expenses', {
        params: { path: { org_id: orgId }, query: { status: status || undefined, cursor } },
        signal,
      }),
    ),
  );
  const items = expenses.data?.pages.flatMap((page) => page.items);
  const [first, setFirst] = useState('');
  if (!openId && !first && items?.length) setFirst(items[0].id);
  const shown = openId ?? first;
  const query = `?status=${status || 'all'}`;

  return (
    <>
      {/* On the list's address, so a filter starts from its first claim. */}
      <nav className="chips" aria-label="Status">
        {FILTERS.map((option) => (
          <Link
            key={option.value || 'all'}
            className="chip"
            to={`${to('expenses')}?status=${option.value || 'all'}`}
            aria-current={option.value === status ? 'true' : undefined}
          >
            {option.label}
          </Link>
        ))}
      </nav>
      <div className={openId ? 'master master-open' : 'master'}>
        <div className="master-list">
          <QueryState query={expenses}>
            {() =>
              !items?.length ? (
                <p className="empty">
                  {status === 'in_review'
                    ? 'No expenses to approve.'
                    : status === 'approved'
                      ? 'No expenses to pay.'
                      : 'No expenses here.'}
                </p>
              ) : (
                <>
                  <ul className="claims">
                    {items.map((e) => (
                      <li key={e.id}>
                        <Link
                          className="claim-card"
                          to={`${to(`expenses/${e.id}`)}${query}`}
                          aria-current={e.id === shown ? 'true' : undefined}
                        >
                          <span className="pay-line">
                            <span className="row-title">{e.note || CATEGORY[e.category]}</span>
                            <span className="t-num">{formatPaise(e.amount)}</span>
                          </span>
                          <span className="cell-sub">
                            {e.owner_name} · {formatDay(e.spent_on)}
                            {!status && ` · ${EXPENSE[e.status].label}`}
                            {e.has_receipt ? '' : ' · no receipt'}
                          </span>
                        </Link>
                      </li>
                    ))}
                  </ul>
                  {expenses.hasNextPage && (
                    <div className="more">
                      <Button
                        compact
                        disabled={expenses.isFetchingNextPage}
                        onClick={() => void expenses.fetchNextPage()}
                      >
                        Show more
                      </Button>
                    </div>
                  )}
                </>
              )
            }
          </QueryState>
        </div>
        {shown && (
          <div className="master-detail">
            {openId && (
              <Link
                className="sc-btn sc-btn-outline sc-btn-compact master-back"
                to={`${to('expenses')}${query}`}
              >
                <Icon name="back" size={16} />
                <span>All expenses</span>
              </Link>
            )}
            <ExpenseDetail key={shown} expenseId={shown} />
          </div>
        )}
      </div>
    </>
  );
}
