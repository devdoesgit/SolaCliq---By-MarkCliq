import { Link, useSearchParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { Member } from '../../api/types';
import { usePages } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  Button,
  Filters,
  Icon,
  PageHeader,
  Person,
  QueryState,
  readFilter,
  StatusPill,
} from '../../components';
import { count } from '../../lib/format';
import { MEMBER } from '../../lib/labels';
import { roleText } from './roles';

type Role = 'worker' | 'agent';

const FILTERS: { value: Role | ''; label: string }[] = [
  { value: '', label: 'Everyone' },
  { value: 'worker', label: 'EPC Installers' },
  { value: 'agent', label: 'Sales Agents' },
];

function load(m: Member): string {
  if (m.role === 'worker') return count(m.open_tasks ?? 0, 'open task');
  return m.role === 'agent' ? count(m.customers ?? 0, 'customer') : '';
}

/** W1 (F3): the admin, installers and agents. */
export function TeamPage() {
  const { orgId, name, to } = useOrg();
  const [params] = useSearchParams();
  const role = readFilter(params.get('role'), FILTERS, '');
  const members = usePages(orgId, ['members', role], (cursor, signal) =>
    unwrap(
      api.GET('/orgs/{org_id}/members', {
        params: { path: { org_id: orgId }, query: { role: role || undefined, cursor } },
        signal,
      }),
    ),
  );
  const items = members.data?.pages.flatMap((page) => page.items) ?? [];

  return (
    <>
      <PageHeader
        title="Team"
        meta={items.length && !members.hasNextPage ? count(items.length, 'member') : name}
        actions={
          <Link className="sc-btn sc-btn-primary sc-btn-compact" to={to('team/add')}>
            <Icon name="plus" size={16} />
            <span>Add member</span>
          </Link>
        }
      />
      <Filters name="role" label="Role" options={FILTERS} value={role} />
      <QueryState query={members}>
        {() =>
          items.length === 0 ? (
            <p className="empty">Nobody here yet. Add your installers and sales agents.</p>
          ) : (
            <>
              <ul className="card rows rows-team" aria-label="Team">
                {items.map((m) => (
                  <li key={m.user_id}>
                    <Link className="row team-row" to={to(`team/${m.user_id}`)}>
                      <Person name={m.name} sub={m.email} />
                      <span className="team-role">{roleText(m)}</span>
                      <span className="team-load">
                        {load(m)}
                        {m.status === 'invited' && <StatusPill {...MEMBER.invited} />}
                      </span>
                      <span className="row-chevron">
                        <Icon name="chevron" />
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
              {members.hasNextPage && (
                <div className="more">
                  <Button
                    compact
                    disabled={members.isFetchingNextPage}
                    onClick={() => void members.fetchNextPage()}
                  >
                    Show more
                  </Button>
                </div>
              )}
            </>
          )
        }
      </QueryState>
    </>
  );
}
