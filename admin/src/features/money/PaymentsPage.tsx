import { Link, useSearchParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { PaymentStatus } from '../../api/types';
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
import { PAYMENT } from '../../lib/labels';
import { PaymentActions, PaymentWhen } from './PaymentActions';

const FILTERS: { value: PaymentStatus | ''; label: string }[] = [
  { value: 'claimed', label: PAYMENT.claimed.label },
  { value: 'due', label: PAYMENT.due.label },
  { value: 'later', label: PAYMENT.later.label },
  { value: 'paid', label: PAYMENT.paid.label },
  { value: '', label: 'All' },
];

/** W4: what customers owe, say they paid, and paid. */
export function PaymentsPage() {
  const { orgId, to } = useOrg();
  const [params] = useSearchParams();
  const status = readFilter(params.get('status'), FILTERS, 'claimed');
  const overview = useOverview(orgId);
  const payments = usePages(orgId, ['payments', status], (cursor, signal) =>
    unwrap(
      api.GET('/orgs/{org_id}/admin/payments', {
        params: { path: { org_id: orgId }, query: { status: status || undefined, cursor } },
        signal,
      }),
    ),
  );
  return (
    <>
      <PageHeader
        title="Payments"
        meta="Customers pay the company directly · confirm what reached you"
      />
      {overview.data && (
        <div className="stats stats-short">
          <Stat dot="tan" label="To collect" value={formatPaise(overview.data.to_collect)} />
          <Stat
            dot="success"
            label="Collected this month"
            value={formatPaise(overview.data.collected_this_month)}
          />
        </div>
      )}
      <Filters name="status" label="Status" options={FILTERS} value={status} />
      <PagedTable
        query={payments}
        caption="Payments"
        rowKey={(p) => p.id}
        empty={status === 'claimed' ? 'No payments to confirm.' : 'No payments here.'}
        columns={[
          {
            label: 'Customer',
            render: (p) => (
              <Link className="person-link" to={to(`customers/${p.customer_id}`)}>
                <Person name={p.customer_name} sub={p.customer_reference} />
              </Link>
            ),
          },
          { label: 'Payment', render: (p) => p.label },
          { label: 'Status', render: (p) => <StatusPill {...PAYMENT[p.status]} /> },
          { label: 'When', render: (p) => <PaymentWhen payment={p} /> },
          { label: 'Amount', end: true, render: (p) => <Amount paise={p.amount} /> },
          { label: 'Actions', end: true, render: (p) => <PaymentActions payment={p} /> },
        ]}
      />
    </>
  );
}
