import { Link, useSearchParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { CommissionStatus } from '../../api/types';
import { useOverview, usePages } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  Amount,
  Filters,
  PagedTable,
  PageHeader,
  Person,
  readFilter,
  Stat,
  StatusPill,
} from '../../components';
import { formatPaise } from '../../lib/format';
import { COMMISSION } from '../../lib/labels';
import { CommissionActions } from './CommissionActions';

const FILTERS: { value: CommissionStatus | ''; label: string }[] = [
  { value: '', label: 'All' },
  { value: 'in_review', label: 'Needs you' },
  { value: 'approved', label: 'Waiting for advance' },
  { value: 'payable', label: 'Payable' },
  { value: 'paid', label: 'Paid' },
];

/** W4: agents' commissions, to approve and then to pay. */
export function CommissionsPage() {
  const { orgId, to } = useOrg();
  const [params] = useSearchParams();
  const status = readFilter(params.get('status'), FILTERS, '');
  const overview = useOverview(orgId);
  const commissions = usePages(orgId, ['commissions', status], (cursor, signal) =>
    unwrap(
      api.GET('/orgs/{org_id}/admin/commissions', {
        params: { path: { org_id: orgId }, query: { status: status || undefined, cursor } },
        signal,
      }),
    ),
  );
  const totals = overview.data?.commissions;
  return (
    <>
      <PageHeader
        title="Commissions"
        meta="Agents paid by commission · payable once the advance is paid"
      />
      {totals && (
        <div className="stats stats-short">
          <Stat dot="tan" label="Needs you" value={formatPaise(totals.in_review)} />
          <Stat dot="quiet" label="Waiting for advance" value={formatPaise(totals.waiting)} />
          <Stat dot="sun" label="Payable now" value={formatPaise(totals.payable)} />
          <Stat dot="success" label="Paid this month" value={formatPaise(totals.paid_this_month)} />
        </div>
      )}
      <Filters name="status" label="Status" options={FILTERS} value={status} />
      <div className="card card-list">
        <PagedTable
          query={commissions}
          caption="Commissions"
          rowKey={(c) => c.customer_id}
          empty={
            status === 'in_review'
              ? 'No commissions to approve.'
              : status === 'payable'
                ? 'No commissions to pay.'
                : 'No commissions here.'
          }
          columns={[
            {
              label: 'Agent',
              render: (c) => (
                <Person
                  name={c.agent_name ?? 'No agent'}
                  sub={c.payout_last4 ? `Account ending ${c.payout_last4}` : undefined}
                />
              ),
            },
            {
              label: 'Customer',
              render: (c) => (
                <span className="cell-main">
                  <Link className="row-title row-link" to={to(`customers/${c.customer_id}`)}>
                    {c.customer_name}
                  </Link>
                  <span className="cell-sub">{c.customer_reference}</span>
                </span>
              ),
            },
            { label: 'Amount', render: (c) => <Amount paise={c.amount} /> },
            { label: 'Status', render: (c) => <StatusPill {...COMMISSION[c.status]} /> },
            { label: 'Advance', render: (c) => (c.advance_paid ? 'Paid' : 'Not paid') },
            { label: 'Action', end: true, render: (c) => <CommissionActions commission={c} /> },
          ]}
        />
      </div>
    </>
  );
}
