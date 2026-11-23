import { Link, useSearchParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import { useOverview, usePages, useSettings } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  Icon,
  PagedTable,
  PageHeader,
  Person,
  SelectField,
  StageBar,
  StatusPill,
} from '../../components';
import { ADVANCE } from '../../lib/labels';
import { Search } from './CustomersPage';

/** The verified customers as installs: where each is, and whether it's paid for. */
export function ProjectsPage() {
  const { orgId, to } = useOrg();
  const [params, setParams] = useSearchParams();
  const settings = useSettings(orgId);
  const overview = useOverview(orgId);
  const q = params.get('q') ?? '';
  const stageNumber = Number(params.get('stage'));
  const stage = stageNumber >= 1 && stageNumber <= 7 ? Math.floor(stageNumber) : undefined;
  const projects = usePages(orgId, ['projects', q, stage], (cursor, signal) =>
    unwrap(
      api.GET('/orgs/{org_id}/admin/customers', {
        params: {
          path: { org_id: orgId },
          query: { kyc_status: 'approved', q: q || undefined, stage, cursor },
        },
        signal,
      }),
    ),
  );

  function set(key: string, value: string) {
    const next = new URLSearchParams(params);
    if (value) next.set(key, value);
    else next.delete(key);
    setParams(next);
  }

  return (
    <>
      <PageHeader
        title="Projects"
        meta={overview.data ? `${overview.data.installs_running} running` : 'Installs'}
      />
      <div className="toolbar">
        <SelectField
          label="Stage"
          value={stage ?? ''}
          onChange={(e) => set('stage', e.target.value)}
        >
          <option value="">Any stage</option>
          {settings.data?.stages.map((name, i) => (
            <option key={name} value={i + 1}>
              {i + 1}. {name}
            </option>
          ))}
        </SelectField>
        <Search value={q} onSearch={(value) => set('q', value)} />
      </div>
      <div className="card card-list card-projects">
        <PagedTable
          query={projects}
          caption="Projects"
          rowKey={(c) => c.id}
          empty={
            q
              ? `No projects match "${q}".`
              : stage
                ? 'No projects at that stage.'
                : 'No projects yet. A verified customer becomes one.'
          }
          columns={[
            {
              label: 'Customer',
              render: (c) => (
                <Link className="person-link" to={to(`projects/${c.id}`)}>
                  <Person
                    name={c.name}
                    sub={[c.system_kw && `${c.system_kw} kW`, c.place].filter(Boolean).join(' · ')}
                  />
                </Link>
              ),
            },
            {
              label: 'Stage',
              render: (c) =>
                c.stage ? (
                  <span className="stage-cell">
                    <span>
                      S{c.stage.index} · {c.stage.name}
                    </span>
                    <StageBar index={c.stage.index} count={c.stage.count} />
                  </span>
                ) : (
                  '–'
                ),
            },
            { label: 'Sold by', render: (c) => c.agent_name ?? 'No agent' },
            {
              label: 'Payment',
              render: (c) =>
                c.advance_status ? <StatusPill {...ADVANCE[c.advance_status]} /> : 'No price',
            },
            {
              label: 'Open',
              end: true,
              render: (c) => (
                <Link
                  className="row-chevron"
                  to={to(`projects/${c.id}`)}
                  aria-label={`Open ${c.name}`}
                >
                  <Icon name="chevron" />
                </Link>
              ),
            },
          ]}
        />
      </div>
    </>
  );
}
