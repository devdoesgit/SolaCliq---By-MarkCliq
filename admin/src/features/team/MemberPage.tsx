import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { Member } from '../../api/types';
import type { components } from '../../api/schema';
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
  type IconName,
} from '../../components';
import { count, formatDate } from '../../lib/format';
import { MEMBER } from '../../lib/labels';
import { ROLE, roleText } from './roles';

type PayType = components['schemas']['PayType'];
type Staff = 'worker' | 'agent';

const PAY: Record<PayType, { name: string; does: string }> = {
  commission: { name: 'Commission', does: 'Types a commission on every customer. You review it.' },
  salary: { name: 'Salaried', does: 'No commission in the app. Marks attendance.' },
};

/** One person in the team: their role and pay (F21), the invite, removing them. */
export function MemberPage() {
  const { orgId, to } = useOrg();
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
        const staff = m.role === 'worker' || m.role === 'agent';
        return staff ? (
          // Keyed by what's saved, so a save or a change elsewhere starts it clean.
          <StaffPage key={`${m.role}-${m.pay_type ?? ''}`} member={m} />
        ) : (
          <>
            <PageHeader title={m.name} meta="Team / Admin" back={back} />
            <section className="card" aria-label="Member">
              <div className="claim-head">
                <Avatar name={m.name} size="lg" />
                <div className="cell-main">
                  <p className="claim-title">{m.name}</p>
                  <p className="cell-sub">{roleText(m)}</p>
                </div>
              </div>
              <Facts items={[['Email', m.email]]} />
            </section>
          </>
        );
      }}
    </QueryState>
  );
}

/*
  A worker or agent, as the member artboards: role and pay chosen in place,
  "Save changes" confirms what changes. Name, phone and email are the
  person's own (F21)
*/
function StaffPage({ member: m }: { member: Member }) {
  const { name, to } = useOrg();
  const [role, setRole] = useState<Staff>(m.role as Staff);
  const [pay, setPay] = useState<PayType | ''>(m.pay_type ?? '');
  const changed = role !== m.role || (role === 'agent' && pay !== (m.pay_type ?? ''));
  const shown = role === 'agent' ? `${ROLE.agent.name}${pay ? `, ${pay}` : ''}` : ROLE.worker.name;

  return (
    <>
      <PageHeader
        title={m.name}
        meta={`Team / ${roleText(m)}`}
        back={{ to: to('team'), label: 'Back to team' }}
        actions={
          <DialogButton
            label="Save changes"
            icon="check"
            variant="primary"
            compact
            disabled={!changed || (role === 'agent' && !pay)}
            dialog={(close) => (
              <SaveDialog member={m} role={role} pay={pay || undefined} onClose={close} />
            )}
          />
        }
      />
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
          <Choice
            legend="Role"
            value={role}
            options={(Object.keys(ROLE) as Staff[]).map((v) => ({
              value: v,
              name: ROLE[v].name,
              does: ROLE[v].does,
              icon: ROLE[v].icon,
            }))}
            onChange={(v) => setRole(v)}
          />
          {role === 'agent' && (
            <Choice
              legend="How is this person paid?"
              value={pay}
              options={(Object.keys(PAY) as PayType[]).map((v) => ({
                value: v,
                name: PAY[v].name,
                does: PAY[v].does,
              }))}
              onChange={(v) => setPay(v)}
            />
          )}
          {changed && (
            <p className="cell-sub" role="status">
              Not saved yet: {shown}. Press &ldquo;Save changes&rdquo;.
            </p>
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
          <p className="cell-sub">
            Their name, phone and email are theirs to change, in the app&apos;s Profile.
          </p>
        </section>
        <div className="col col-side">
          {m.status === 'invited' && (
            <Section title="Not set up yet">
              <p className="cell-sub">
                They haven&apos;t set a password. Send the email with the steps again.
              </p>
              <DialogButton
                label="Resend invite"
                icon="back"
                block
                dialog={(close) => <InviteDialog member={m} onClose={close} />}
              />
            </Section>
          )}
          <Section title={`Remove from ${name}`}>
            <p className="cell-sub">
              They keep their SolaCliq account. Their tasks, customers and history stay with you.
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
      </div>
    </>
  );
}

/** The artboards' picker: cards, one chosen. */
function Choice<T extends string>({
  legend,
  value,
  options,
  onChange,
}: {
  legend: string;
  value: T | '';
  options: { value: T; name: string; does: string; icon?: IconName }[];
  onChange: (value: T) => void;
}) {
  return (
    <fieldset className="lines">
      <legend className="field-label">{legend}</legend>
      <div className="form-grid">
        {options.map((o) => (
          <label key={o.value} className="role role-pick">
            <input
              type="radio"
              name={legend}
              className="visually-hidden"
              aria-label={o.name}
              checked={value === o.value}
              onChange={() => onChange(o.value)}
            />
            {o.icon && (
              <span className="row-icon">
                <Icon name={o.icon} size={17} />
              </span>
            )}
            <span className="cell-main">
              <span className="row-title">{o.name}</span>
              <span className="cell-sub">{o.does}</span>
            </span>
          </label>
        ))}
      </div>
    </fieldset>
  );
}

function SaveDialog({
  member: m,
  role,
  pay,
  onClose,
}: {
  member: Member;
  role: Staff;
  pay?: PayType;
  onClose: () => void;
}) {
  const { orgId } = useOrg();
  const first = m.name.split(' ')[0];
  const roleChange = role !== m.role;
  return (
    <ActionDialog
      title={
        roleChange
          ? `Make ${first} ${role === 'agent' ? 'a Sales Agent' : 'an EPC Installer'}?`
          : `Pay ${first} by ${pay === 'salary' ? 'salary' : 'commission'}?`
      }
      body={
        roleChange ? (
          <p>
            Their app shows the {role === 'agent' ? 'Sales Agent' : 'EPC Installer'} home the next
            time it opens. Their past work stays on record. If they still have open work,
            you&apos;ll be told what to finish first.
          </p>
        ) : (
          <p>
            From now on. Customers they already added keep their commission as it is.
            {pay === 'salary' ? ' They start marking attendance.' : ''}
          </p>
        )
      }
      confirm="Save changes"
      done="Saved."
      onClose={onClose}
      run={() =>
        unwrap(
          api.PATCH('/orgs/{org_id}/members/{user_id}', {
            params: { path: { org_id: orgId, user_id: m.user_id } },
            body: roleChange
              ? { role, pay_type: role === 'agent' ? pay : undefined }
              : { pay_type: pay },
          }),
        )
      }
    />
  );
}

function InviteDialog({ member: m, onClose }: { member: Member; onClose: () => void }) {
  const { orgId } = useOrg();
  return (
    <ActionDialog
      title={`Send ${m.name.split(' ')[0]}'s invite again?`}
      body={`To ${m.email}: how to get the app and set a password.`}
      confirm="Send"
      done="Invite sent."
      onClose={onClose}
      run={() =>
        unwrap(
          api.POST('/orgs/{org_id}/members/{user_id}/invite', {
            params: { path: { org_id: orgId, user_id: m.user_id } },
          }),
        )
      }
    />
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
