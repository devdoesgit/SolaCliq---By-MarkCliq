import { Link, useSearchParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { LeadStatus, LeadSummary, Member } from '../../api/types';
import { useAgents, usePages } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  Button,
  DialogButton,
  Icon,
  PageHeader,
  QueryState,
  StatusPill,
  readFilter,
} from '../../components';
import { formatWhen } from '../../lib/format';
import { LEAD } from '../../lib/labels';
import { Search } from '../customers/CustomersPage';
import { ChooseAgentDialog, GiveDialog } from './LeadDialogs';

const FILTERS: { value: LeadStatus | ''; label: string }[] = [
  { value: 'new', label: LEAD.new.label },
  { value: 'contacted', label: LEAD.contacted.label },
  { value: 'won', label: LEAD.won.label },
  { value: 'lost', label: LEAD.lost.label },
  { value: '', label: 'All' },
];

// More agents than this, and "Give to" opens a list instead of chips.
const AGENT_CHIPS = 4;

/** F20: the company's landing-page leads, newest first. */
export function LeadsPage() {
  const { orgId, to } = useOrg();
  const [params, setParams] = useSearchParams();
  const status = readFilter(params.get('status'), FILTERS, 'new');
  const q = params.get('q') ?? '';
  const agents = useAgents(orgId);
  const leads = usePages(orgId, ['leads', status, q], (cursor, signal) =>
    unwrap(
      api.GET('/orgs/{org_id}/leads', {
        params: {
          path: { org_id: orgId },
          query: { status: status || undefined, q: q || undefined, cursor },
        },
        signal,
      }),
    ),
  );
  const items = leads.data?.pages.flatMap((page) => page.items);

  function search(value: string) {
    const next = new URLSearchParams(params);
    if (value) next.set('q', value);
    else next.delete('q');
    setParams(next);
  }

  return (
    <>
      <PageHeader title="Leads" meta="From your landing page" />
      <div className="toolbar">
        <nav className="chips" aria-label="Status">
          {FILTERS.map((option) => (
            <Link
              key={option.value || 'all'}
              className="chip"
              to={`${to('leads')}?status=${option.value || 'all'}`}
              aria-current={option.value === status ? 'true' : undefined}
            >
              {option.label}
            </Link>
          ))}
        </nav>
        <Search value={q} onSearch={search} placeholder="Name, phone, email or city" />
      </div>
      <QueryState query={leads}>
        {() =>
          !items?.length ? (
            <p className="empty">
              {q
                ? 'No lead matches that.'
                : status === 'new'
                  ? 'No new leads. They arrive here the moment someone fills your landing page.'
                  : 'No leads here.'}
            </p>
          ) : (
            <>
              <ul className="leads">
                {items.map((lead) => (
                  <LeadCard key={lead.id} lead={lead} agents={agents.data ?? []} />
                ))}
              </ul>
              {leads.hasNextPage && (
                <div className="more">
                  <Button
                    compact
                    disabled={leads.isFetchingNextPage}
                    onClick={() => void leads.fetchNextPage()}
                  >
                    Show more
                  </Button>
                </div>
              )}
            </>
          )
        }
      </QueryState>
      <p className="list-hint">
        Each lead comes from your landing page with the key in{' '}
        <Link to={to('settings')}>Settings</Link>. Give it to a Sales Agent and they call from the
        app.
      </p>
    </>
  );
}

function LeadCard({ lead, agents }: { lead: LeadSummary; agents: Member[] }) {
  const { to } = useOrg();
  const status = LEAD[lead.status];
  return (
    <li className="card lead-card">
      <div className="lead-head">
        <div className="lead-who">
          <Link className="row-title row-link" to={to(`leads/${lead.id}`)}>
            {lead.name}
          </Link>
          <span className="cell-sub">{formatWhen(lead.received_at)}</span>
        </div>
        <StatusPill label={status.label} tone={status.tone} />
      </div>
      <p className="cell-sub">{[lead.city, lead.source].filter(Boolean).join(' · ')}</p>
      <div className="lead-band">
        <a className="sc-btn sc-btn-compact" href={`tel:+91${lead.phone}`}>
          <Icon name="phone" size={16} />
          <span>Call {lead.phone}</span>
        </a>
        <GiveTo lead={lead} agents={agents} />
      </div>
    </li>
  );
}

/** The design's "Give to" chips, one per agent; the one who has it is marked. */
function GiveTo({ lead, agents }: { lead: LeadSummary; agents: Member[] }) {
  if (!agents.length) {
    return <span className="cell-sub">Add a Sales Agent in Team to hand out leads.</span>;
  }
  return (
    <div className="give-to" role="group" aria-label={`Give ${lead.name} to`}>
      <span className="cell-sub">{lead.agent_name ? 'With' : 'Give to'}</span>
      {agents.length > AGENT_CHIPS ? (
        <DialogButton
          label={lead.agent_name ?? 'Choose an agent'}
          compact
          dialog={(close) => <ChooseAgentDialog lead={lead} agents={agents} onClose={close} />}
        />
      ) : (
        agents.map((agent) =>
          agent.user_id === lead.agent_id ? (
            <span key={agent.user_id} className="chip give-chip" aria-current="true">
              {agent.name.split(' ')[0]}
            </span>
          ) : (
            <DialogButton
              key={`${agent.user_id}-${lead.agent_id ?? ''}`}
              label={agent.name.split(' ')[0]}
              compact
              dialog={(close) => <GiveDialog lead={lead} agent={agent} onClose={close} />}
            />
          ),
        )
      )}
    </div>
  );
}
