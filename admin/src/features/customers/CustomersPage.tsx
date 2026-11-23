import { useState, type FormEvent } from 'react';
import { Link, useSearchParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { CustomerSummary, KycStatus } from '../../api/types';
import { usePages } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  Button,
  Filters,
  PagedTable,
  PageHeader,
  Person,
  readFilter,
  StatusPill,
  TextField,
} from '../../components';
import { formatPaise, formatWhen } from '../../lib/format';
import { KYC } from '../../lib/labels';
import { useReview } from '../inbox/queries';

/** W2: who the sales team sent in, new requests first. Verified ones open as projects. */
export function CustomersPage() {
  const { orgId, name, to } = useOrg();
  const [params, setParams] = useSearchParams();
  const review = useReview(orgId);
  const waiting = review.data?.registrations.length;
  const filters: { value: KycStatus | ''; label: string }[] = [
    { value: 'in_review', label: waiting ? `New requests · ${waiting}` : 'New requests' },
    { value: 'needs_fix', label: KYC.needs_fix.label },
    { value: 'approved', label: 'Active' },
    { value: 'rejected', label: KYC.rejected.label },
    { value: '', label: 'All' },
  ];
  const q = params.get('q') ?? '';
  // Searching looks through everyone, unless a filter was chosen.
  const status = readFilter(params.get('status'), filters, q ? '' : 'in_review');

  const customers = usePages(orgId, ['customers', status, q], (cursor, signal) =>
    unwrap(
      api.GET('/orgs/{org_id}/admin/customers', {
        params: {
          path: { org_id: orgId },
          query: { q: q || undefined, kyc_status: status || undefined, cursor },
        },
        signal,
      }),
    ),
  );

  function search(value: string) {
    const next = new URLSearchParams(params);
    if (value) next.set('q', value);
    else next.delete('q');
    setParams(next);
  }

  return (
    <>
      <PageHeader title="Customers" meta={name} />
      <div className="toolbar">
        <Filters name="status" label="Registration" options={filters} value={status} />
        <Search value={q} onSearch={search} />
      </div>
      <div className="card card-list card-requests">
        <p className="card-hint">
          Added by your sales team. Check documents and commission, then verify.
        </p>
        <PagedTable
          query={customers}
          caption="Customers"
          rowKey={(c) => c.id}
          empty={
            q
              ? `No customers match "${q}".`
              : status === 'in_review'
                ? 'No new requests.'
                : status
                  ? 'No customers like that.'
                  : 'No customers yet. Your sales agents register them in the app.'
          }
          columns={[
            { label: 'Customer', render: (c) => <Person name={c.name} sub={c.reference} /> },
            {
              label: 'System',
              render: (c) =>
                [c.system_kw && `${c.system_kw} kW`, c.place].filter(Boolean).join(' · '),
            },
            { label: 'Sold by', render: soldBy },
            { label: 'Added', render: (c) => formatWhen(c.created_at) },
            {
              label: 'Registration',
              end: true,
              render: (c) => (
                <span className="row-end">
                  {c.kyc_status !== 'in_review' && <StatusPill {...KYC[c.kyc_status]} />}
                  <Link
                    className={`sc-btn sc-btn-compact ${c.kyc_status === 'in_review' ? 'sc-btn-primary' : 'sc-btn-secondary'}`}
                    to={to(`${c.kyc_status === 'approved' ? 'projects' : 'customers'}/${c.id}`)}
                    aria-label={`${c.kyc_status === 'in_review' ? 'Review' : 'Open'} ${c.name}`}
                  >
                    <span>{c.kyc_status === 'in_review' ? 'Review' : 'Open'}</span>
                  </Link>
                </span>
              ),
            },
          ]}
        />
      </div>
    </>
  );
}

function soldBy(c: CustomerSummary): string {
  if (!c.agent_name) return 'No agent';
  return c.commission_amount == null
    ? c.agent_name
    : `${c.agent_name} · commission ${formatPaise(c.commission_amount)}`;
}

export function Search({
  value,
  onSearch,
  placeholder = 'Name, phone, email, SC- or consumer number',
}: {
  value: string;
  onSearch: (value: string) => void;
  placeholder?: string;
}) {
  const [text, setText] = useState(value);
  const [searched, setSearched] = useState(value);
  // Back puts the earlier words in the box, without rebuilding it.
  if (value !== searched) {
    setSearched(value);
    setText(value);
  }
  function submit(event: FormEvent) {
    event.preventDefault();
    onSearch(text.trim());
  }
  return (
    <form className="search" role="search" onSubmit={submit}>
      <TextField
        label="Search"
        type="search"
        maxLength={100}
        placeholder={placeholder}
        value={text}
        onChange={(e) => setText(e.target.value)}
      />
      <Button type="submit" compact>
        Search
      </Button>
    </form>
  );
}
