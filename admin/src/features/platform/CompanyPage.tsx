import { useState } from 'react';
import { useParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { PlatformOrg } from '../../api/types';
import {
  ActionDialog,
  DialogButton,
  Facts,
  NoteDialog,
  Notice,
  PageHeader,
  Person,
  QueryState,
  Section,
  StatusPill,
  TextArea,
} from '../../components';
import { formatDateTime, formatWhen } from '../../lib/format';
import { BUSINESS, ORG } from '../../lib/labels';
import { PLATFORM, useCompany } from './queries';

// The server's limit for a review note (`OrgStatusChange.note`).
const NOTE_MAX = 1000;

type Change = { status: 'active' | 'rejected' | 'suspended'; note?: string };

const change = (orgId: string, body: Change) =>
  unwrap(api.POST('/platform/orgs/{org_id}/status', { params: { path: { org_id: orgId } }, body }));

/*
  F22: one company, as MarkCliq reviews it
  ----------------------------------------------------------------------
  - only its registration and its owner: what the platform scope allows
  - the actions its status allows (the API checks the move again):
    waiting → approve or reject, active → suspend, suspended → restore
*/
export function CompanyPage() {
  const { orgId = '' } = useParams();
  const company = useCompany(orgId);
  return (
    <QueryState query={company}>
      {(c) => (
        <>
          <PageHeader
            title={c.status === 'pending' ? `${c.name} · new company` : c.name}
            meta={['Companies', ORG[c.status].label, `registered ${formatWhen(c.created_at)}`].join(
              ' / ',
            )}
            back={{ to: `/platform/companies?status=${c.status}`, label: 'Back' }}
          />
          <div className="split">
            <div className="col">
              {c.status === 'rejected' && (
                <Notice tone="danger" title="Not approved" body={c.review_note} />
              )}
              {c.status === 'suspended' && (
                <Notice
                  tone="danger"
                  title="Suspended"
                  body={c.review_note ?? 'Its people see that it is suspended.'}
                />
              )}
              <Business company={c} />
              <Decision company={c} />
            </div>
            <div className="col col-side">
              <Owner company={c} />
            </div>
          </div>
        </>
      )}
    </QueryState>
  );
}

function Business({ company: c }: { company: PlatformOrg }) {
  return (
    <Section title="Business">
      <Facts
        items={[
          ['Legal name', c.legal_name],
          ['Trade name', c.name !== c.legal_name ? c.name : undefined],
          ['Type', BUSINESS[c.business_type]],
          ['GSTIN', c.gstin],
          ['PAN', c.pan],
          ['Phone', c.phone && <a href={`tel:+91${c.phone}`}>{c.phone}</a>],
          [
            'Address',
            [c.address_line_1, c.address_line_2, c.city, c.state, c.pin_code]
              .filter(Boolean)
              .join(', '),
          ],
          ['Registered', formatDateTime(c.created_at)],
          ['Reviewed', c.reviewed_at && formatDateTime(c.reviewed_at)],
        ]}
      />
    </Section>
  );
}

function Owner({ company: c }: { company: PlatformOrg }) {
  const o = c.owner;
  return (
    <Section title="Owner" className="owner-card">
      {o ? (
        <div className="stack">
          <Person name={o.name} sub="Owner, the company's first admin" />
          <Facts
            items={[
              ['Mobile', o.phone && <a href={`tel:+91${o.phone}`}>{o.phone}</a>],
              ['Email', <a href={`mailto:${o.email}`}>{o.email}</a>],
            ]}
          />
          {o.phone && (
            <a className="sc-btn sc-btn-secondary sc-btn-block" href={`tel:+91${o.phone}`}>
              <span>Call {o.name.split(' ')[0]}</span>
            </a>
          )}
        </div>
      ) : (
        <p className="cell-sub">No owner: their account was deleted.</p>
      )}
    </Section>
  );
}

function Decision({ company: c }: { company: PlatformOrg }) {
  if (c.status === 'rejected') return null;
  return (
    <Section
      title={c.status === 'pending' ? 'Decision' : 'Manage'}
      aside={<StatusPill {...ORG[c.status]} />}
    >
      {/* Keyed by status, so an open dialog can't become another one. */}
      <div className="actions" key={c.status}>
        {c.status === 'pending' && (
          <>
            <DialogButton
              label="Approve"
              icon="check"
              variant="primary"
              dialog={(close) => <ApproveDialog company={c} onClose={close} />}
            />
            <DialogButton
              label="Reject"
              variant="danger"
              dialog={(close) => <RejectDialog company={c} onClose={close} />}
            />
          </>
        )}
        {c.status === 'active' && (
          <DialogButton
            label="Suspend"
            variant="danger"
            dialog={(close) => <SuspendDialog company={c} onClose={close} />}
          />
        )}
        {c.status === 'suspended' && (
          <DialogButton
            label="Restore"
            variant="primary"
            dialog={(close) => <RestoreDialog company={c} onClose={close} />}
          />
        )}
      </div>
      <p className="cell-sub">
        {c.status === 'pending'
          ? 'Approving emails the owner how to log in. Rejecting emails them your reason.'
          : c.status === 'active'
            ? 'Suspending stops everyone in the company from using SolaCliq. Its data is kept.'
            : 'Restoring lets the company use SolaCliq again.'}
      </p>
    </Section>
  );
}

interface DialogProps {
  company: PlatformOrg;
  onClose: () => void;
}

function ApproveDialog({ company: c, onClose }: DialogProps) {
  return (
    <ActionDialog
      title={`Approve ${c.name}?`}
      body="The owner is emailed how to log in. Their company can use SolaCliq from now on."
      confirm="Approve"
      done={`${c.name} approved`}
      refresh={PLATFORM}
      run={() => change(c.id, { status: 'active' })}
      onClose={onClose}
    />
  );
}

function RejectDialog({ company: c, onClose }: DialogProps) {
  return (
    <NoteDialog
      title={`Reject ${c.name}?`}
      body="The owner is emailed this note. They can register again."
      label="Reason"
      help="Say what was wrong, for example the GSTIN didn't match."
      maxLength={NOTE_MAX}
      confirm="Reject"
      danger
      done={`${c.name} rejected`}
      refresh={PLATFORM}
      send={(note) => change(c.id, { status: 'rejected', note })}
      onClose={onClose}
    />
  );
}

function SuspendDialog({ company: c, onClose }: DialogProps) {
  const [note, setNote] = useState('');
  return (
    <ActionDialog
      title={`Suspend ${c.name}?`}
      body="Everyone in the company sees that it's suspended until you restore it. Nothing is deleted."
      confirm="Suspend"
      danger
      done={`${c.name} suspended`}
      refresh={PLATFORM}
      run={() => change(c.id, { status: 'suspended', note: note.trim() || undefined })}
      onClose={onClose}
    >
      {(errors) => (
        <TextArea
          label="Note, for MarkCliq (optional)"
          maxLength={NOTE_MAX}
          value={note}
          error={errors.note}
          onChange={(e) => setNote(e.target.value)}
        />
      )}
    </ActionDialog>
  );
}

function RestoreDialog({ company: c, onClose }: DialogProps) {
  return (
    <ActionDialog
      title={`Restore ${c.name}?`}
      body="The company can use SolaCliq again."
      confirm="Restore"
      done={`${c.name} restored`}
      refresh={PLATFORM}
      run={() => change(c.id, { status: 'active' })}
      onClose={onClose}
    />
  );
}
