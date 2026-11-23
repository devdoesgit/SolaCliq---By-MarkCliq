import { useQuery } from '@tanstack/react-query';
import { useNavigate, useParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { LeadStatus } from '../../api/types';
import { useAgents } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  DialogButton,
  Facts,
  Icon,
  PageHeader,
  QueryState,
  Section,
  StatusPill,
} from '../../components';
import { formatDateTime, formatWhen } from '../../lib/format';
import { LEAD } from '../../lib/labels';
import {
  ChooseAgentDialog,
  DeleteLeadDialog,
  LeadNoteDialog,
  StatusDialog,
  TakeBackDialog,
} from './LeadDialogs';

const ORDER: LeadStatus[] = ['new', 'contacted', 'won', 'lost'];

/** F20: one lead, everything its form sent, and working it. */
export function LeadPage() {
  const { leadId = '' } = useParams();
  const { orgId, to } = useOrg();
  const navigate = useNavigate();
  const agents = useAgents(orgId);
  const lead = useQuery({
    queryKey: ['org', orgId, 'lead', leadId],
    queryFn: ({ signal }) =>
      unwrap(
        api.GET('/orgs/{org_id}/leads/{lead_id}', {
          params: { path: { org_id: orgId, lead_id: leadId } },
          signal,
        }),
      ),
  });

  return (
    <QueryState query={lead}>
      {(l) => (
        <>
          <PageHeader
            title={l.name}
            meta={`Leads / ${l.source} · ${formatWhen(l.received_at)}`}
            back={{ to: to('leads'), label: 'All leads' }}
          />
          <div className="split">
            <div className="col">
              <Section title="From the form">
                <Facts
                  items={[
                    ['Mobile', <a href={`tel:+91${l.phone}`}>{l.phone}</a>],
                    ['Email', l.email && <a href={`mailto:${l.email}`}>{l.email}</a>],
                    ['City', [l.city, l.pin_code].filter(Boolean).join(' · ') || undefined],
                    ['Monthly bill', l.monthly_bill],
                    ['Roof', l.roof_type],
                    ['Source', l.source],
                    ['Campaign', l.campaign],
                    ...Object.entries(l.extra).map(([q, a]): [string, string] => [q, a]),
                    ['Received', formatDateTime(l.received_at)],
                  ]}
                />
                {l.message && (
                  <blockquote className="lead-message">
                    <p className="eyebrow">Their message</p>
                    <p>{l.message}</p>
                  </blockquote>
                )}
                {l.page_url && <p className="cell-sub">From {l.page_url}</p>}
              </Section>
            </div>
            <div className="col col-side">
              <section className="card" aria-label="Where it stands">
                <div className="card-head">
                  <h2 className="card-title">Where it stands</h2>
                  <StatusPill {...LEAD[l.status]} />
                </div>
                <a className="sc-btn sc-btn-primary sc-btn-block" href={`tel:+91${l.phone}`}>
                  <Icon name="phone" size={16} />
                  <span>Call {l.phone}</span>
                </a>
                <div className="lead-moves" role="group" aria-label="Mark as">
                  {ORDER.filter((s) => s !== l.status).map((s) => (
                    <DialogButton
                      key={`${s}-${l.status}`}
                      label={s === 'new' ? 'Back to new' : `Mark ${LEAD[s].label.toLowerCase()}`}
                      compact
                      dialog={(close) => <StatusDialog lead={l} status={s} onClose={close} />}
                    />
                  ))}
                </div>
                <div className="lead-note">
                  <p className="eyebrow">Note</p>
                  <p>{l.note ?? 'No note yet.'}</p>
                  <DialogButton
                    key={l.note ?? ''}
                    label={l.note ? 'Change note' : 'Add note'}
                    variant="ghost"
                    compact
                    dialog={(close) => <LeadNoteDialog lead={l} onClose={close} />}
                  />
                </div>
              </section>
              <Section title="Sales Agent">
                <p>
                  {l.agent_name
                    ? `${l.agent_name} has it, and sees it in the app.`
                    : 'Nobody has it yet.'}
                </p>
                <div className="actions-row">
                  {agents.data?.length ? (
                    <DialogButton
                      key={l.agent_id ?? 'none'}
                      label={l.agent_name ? 'Give to someone else' : 'Give to an agent'}
                      variant={l.agent_name ? undefined : 'primary'}
                      compact
                      dialog={(close) => (
                        <ChooseAgentDialog lead={l} agents={agents.data} onClose={close} />
                      )}
                    />
                  ) : (
                    <p className="cell-sub">Add a Sales Agent in Team to hand out leads.</p>
                  )}
                  {l.agent_name && (
                    <DialogButton
                      key={`back-${l.agent_id}`}
                      label="Take back"
                      compact
                      dialog={(close) => <TakeBackDialog lead={l} onClose={close} />}
                    />
                  )}
                </div>
              </Section>
              <Section title="Delete">
                <p className="cell-sub">
                  When someone asks to be forgotten, delete their lead. It can&apos;t be undone.
                </p>
                <DialogButton
                  label="Delete lead"
                  variant="danger"
                  compact
                  dialog={(close) => (
                    <DeleteLeadDialog
                      lead={l}
                      onClose={close}
                      onDeleted={() => void navigate(to('leads'), { replace: true })}
                    />
                  )}
                />
              </Section>
            </div>
          </div>
        </>
      )}
    </QueryState>
  );
}
