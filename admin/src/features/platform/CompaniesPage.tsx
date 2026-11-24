import { Link, useSearchParams } from 'react-router';
import type { OrgStatus, PlatformOrg } from '../../api/types';
import { Filters, PagedTable, PageHeader, Person, readFilter } from '../../components';
import { formatWhen } from '../../lib/format';
import { useCompanies, useWaiting } from './queries';

const EMPTY: Record<OrgStatus, string> = {
  pending: 'No companies waiting for review.',
  active: 'No active companies yet.',
  suspended: 'No suspended companies.',
  rejected: 'No companies turned down.',
};

/** F22: the companies, one status at a time; those waiting first. */
export function CompaniesPage() {
  const [params] = useSearchParams();
  const waiting = useWaiting();
  const filters: { value: OrgStatus; label: string }[] = [
    {
      value: 'pending',
      label: waiting.data && waiting.data !== '0' ? `Waiting · ${waiting.data}` : 'Waiting',
    },
    { value: 'active', label: 'Active' },
    { value: 'suspended', label: 'Suspended' },
    { value: 'rejected', label: 'Not approved' },
  ];
  // Every list is one status: the API reads them that way.
  const status = (readFilter(params.get('status'), filters, 'pending') || 'pending') as OrgStatus;
  const companies = useCompanies(status);

  return (
    <>
      <PageHeader title="Companies" meta="MarkCliq" />
      <div className="toolbar">
        <Filters name="status" label="Status" options={filters} value={status} />
      </div>
      <div className="card card-list card-requests">
        <p className="card-hint">
          {status === 'pending'
            ? 'Solar companies that registered. Call the owner and check the GSTIN, then decide.'
            : 'Open one to see its details.'}
        </p>
        <PagedTable
          query={companies}
          caption="Companies"
          rowKey={(c) => c.id}
          empty={EMPTY[status]}
          columns={[
            {
              label: 'Company',
              render: (c) => (
                <Person name={c.name} sub={c.legal_name !== c.name ? c.legal_name : undefined} />
              ),
            },
            { label: 'Place', render: (c) => [c.city, c.state].filter(Boolean).join(', ') },
            { label: 'GSTIN', render: (c) => c.gstin },
            { label: 'Owner', render: owner },
            { label: 'Registered', render: (c) => formatWhen(c.created_at) },
            {
              label: 'Open',
              end: true,
              render: (c) => (
                <Link
                  className={`sc-btn sc-btn-compact ${c.status === 'pending' ? 'sc-btn-primary' : 'sc-btn-secondary'}`}
                  to={`/platform/companies/${c.id}`}
                  aria-label={`${c.status === 'pending' ? 'Review' : 'Open'} ${c.name}`}
                >
                  <span>{c.status === 'pending' ? 'Review' : 'Open'}</span>
                </Link>
              ),
            },
          ]}
        />
      </div>
    </>
  );
}

const owner = (c: PlatformOrg) => c.owner?.name ?? 'No owner';
