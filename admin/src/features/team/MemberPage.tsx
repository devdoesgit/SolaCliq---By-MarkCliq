import { Link, useNavigate, useParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { Member } from '../../api/types';
import { useEveryMember } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  ActionDialog,
  Avatar,
  DialogButton,
  Facts,
  Icon,
  Notice,
  PageHeader,
  QueryState,
  Section,
  StatusPill,
} from '../../components';
import { count, formatDate } from '../../lib/format';
import { MEMBER } from '../../lib/labels';
import { ROLE, roleText } from './roles';

/** One person in the team, and removing them. */
export function MemberPage() {
  const { orgId, name, to } = useOrg();
  const { userId = '' } = useParams();
  const team = useEveryMember(orgId);
  return (
    <QueryState query={team}>
      {(all) => {
        const m = all.find((member) => member.user_id === userId);
        const back = { to: to('team'), label: 'Back to team' };
        if (!m) {
          return (
            <>
              <PageHeader title="Team" back={back} />
              <Notice tone="info" title="They aren't in the team" />
            </>
          );
        }
        const role = m.role === 'worker' || m.role === 'agent' ? ROLE[m.role] : null;
        return (
          <>
            <PageHeader title={m.name} meta={`Team / ${role?.name ?? 'Admin'}`} back={back} />
            <div className="split">
              <section className="card" aria-label="Member">
                <div className="claim-head">
                  <Avatar name={m.name} size="lg" />
                  <div className="cell-main">
                    <p className="claim-title">{m.name}</p>
                    <p className="cell-sub">
                      {m.role === 'worker' && `${count(m.open_tasks ?? 0, 'open task')} · `}
                      {m.role === 'agent' && `${count(m.customers ?? 0, 'customer')} · `}
                      joined {formatDate(m.added_at)}
                    </p>
                  </div>
                  <StatusPill {...MEMBER[m.status]} />
                </div>
                {role && (
                  <div className="role">
                    <span className="row-icon">
                      <Icon name={role.icon} size={17} />
                    </span>
                    <span className="cell-main">
                      <span className="row-title">{roleText(m)}</span>
                      <span className="cell-sub">{role.does}</span>
                    </span>
                  </div>
                )}
                <Facts
                  items={[
                    ['Email', m.email],
                    [
                      'Open tasks',
                      m.open_tasks ? (
                        <Link to={`${to('tasks')}?assignee=${m.user_id}`}>{m.open_tasks}</Link>
                      ) : undefined,
                    ],
                  ]}
                />
              </section>
              {role && (
                <div className="col col-side">
                  <Section title={`Remove from ${name}`}>
                    <p className="cell-sub">
                      They keep their SolaCliq account. Their tasks, customers and history stay with
                      you.
                    </p>
                    <DialogButton
                      label="Remove"
                      icon="close"
                      variant="danger"
                      block
                      dialog={(close) => <RemoveDialog member={m} onClose={close} />}
                    />
                  </Section>
                </div>
              )}
            </div>
          </>
        );
      }}
    </QueryState>
  );
}

function RemoveDialog({ member, onClose }: { member: Member; onClose: () => void }) {
  const { orgId, name, to } = useOrg();
  const navigate = useNavigate();
  const open = member.open_tasks ?? 0;
  return (
    <ActionDialog
      title={`Remove ${member.name}?`}
      danger
      confirm="Remove"
      done="Removed."
      onClose={onClose}
      body={
        <>
          <p>They lose access to {name} at once. Their past work stays on record.</p>
          {open > 0 && (
            <p className="warn">
              <strong>{count(open, 'open task')}</strong> will stay with them until you give{' '}
              {open === 1 ? 'it' : 'them'} to another installer. In Tasks they are marked
              &ldquo;Removed&rdquo;.
            </p>
          )}
        </>
      }
      run={async () => {
        await unwrap(
          api.DELETE('/orgs/{org_id}/members/{user_id}', {
            params: { path: { org_id: orgId, user_id: member.user_id } },
          }),
        );
        void navigate(to('team'), { replace: true });
      }}
    />
  );
}
