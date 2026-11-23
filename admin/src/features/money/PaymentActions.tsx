import { useState } from 'react';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { Payment } from '../../api/types';
import { useOrg } from '../../app/org';
import { ActionDialog, DialogButton, NoteDialog, TextField } from '../../components';
import { formatDateTime, formatDay, formatPaise, indiaDay } from '../../lib/format';
import { METHOD } from '../../lib/labels';

/** When a payment is due, was claimed or was paid. */
export function PaymentWhen({ payment: p }: { payment: Payment }) {
  if (p.status === 'paid' && p.paid_on) return `Paid ${formatDay(p.paid_on)}`;
  if (p.status === 'claimed' && p.claimed_at) {
    const how = p.claimed_method ? `, ${METHOD[p.claimed_method]}` : '';
    return `Sent ${formatDateTime(p.claimed_at)}${how}`;
  }
  if (p.status === 'due' && p.due_on) return `Due ${formatDay(p.due_on)}`;
  return '–';
}

export function PaymentActions({ payment: p }: { payment: Payment }) {
  if (p.status === 'paid') return '–';
  return p.status === 'later' ? (
    <DialogButton
      key={`ask-${p.amount}`}
      label="Ask for it"
      compact
      dialog={(close) => <RequestDialog payment={p} onClose={close} />}
    />
  ) : (
    <span className="actions">
      {p.status === 'claimed' && (
        <DialogButton
          key={`not-received-${p.amount}`}
          label="Not received"
          compact
          dialog={(close) => <NotReceivedDialog payment={p} onClose={close} />}
        />
      )}
      <DialogButton
        key={`${p.status}-${p.amount}`}
        label={p.status === 'claimed' ? 'Confirm received' : 'Record as paid'}
        compact
        variant={p.status === 'claimed' ? 'primary' : undefined}
        dialog={(close) => <ConfirmDialog payment={p} onClose={close} />}
      />
    </span>
  );
}

function RequestDialog({ payment: p, onClose }: { payment: Payment; onClose: () => void }) {
  const { orgId } = useOrg();
  const [dueOn, setDueOn] = useState(() => indiaDay(7));
  return (
    <ActionDialog
      title={`Ask for ${formatPaise(p.amount)}`}
      body={`${p.label}. ${p.customer_name} is notified.`}
      confirm="Ask"
      done="Asked."
      onClose={onClose}
      validate={() => ({
        due_on: !dueOn ? 'Choose a day.' : dueOn < indiaDay() ? 'Today or later.' : undefined,
      })}
      run={() =>
        unwrap(
          api.POST('/orgs/{org_id}/payments/{payment_id}/request', {
            params: { path: { org_id: orgId, payment_id: p.id } },
            body: { due_on: dueOn },
          }),
        )
      }
    >
      {(errors) => (
        <TextField
          label="Due on"
          type="date"
          min={indiaDay()}
          value={dueOn}
          error={errors.due_on}
          onChange={(e) => setDueOn(e.target.value)}
        />
      )}
    </ActionDialog>
  );
}

function NotReceivedDialog({ payment: p, onClose }: { payment: Payment; onClose: () => void }) {
  const { orgId } = useOrg();
  return (
    <NoteDialog
      title={`${formatPaise(p.amount)} didn't arrive?`}
      body={`${p.label} is due again, and ${p.customer_name} can pay or say so again.`}
      label="What you checked"
      help="The customer sees this."
      confirm="Not received"
      done="Due again."
      onClose={onClose}
      send={(note) =>
        unwrap(
          api.POST('/orgs/{org_id}/payments/{payment_id}/not-received', {
            params: { path: { org_id: orgId, payment_id: p.id } },
            body: { note },
          }),
        )
      }
    />
  );
}

function ConfirmDialog({ payment: p, onClose }: { payment: Payment; onClose: () => void }) {
  const { orgId } = useOrg();
  return (
    <ActionDialog
      title={`${formatPaise(p.amount)} received from ${p.customer_name}?`}
      body={`${p.label}. Check the money reached you first: this can't be undone.`}
      confirm="Yes, received"
      done="Payment recorded."
      onClose={onClose}
      run={() =>
        unwrap(
          api.POST('/orgs/{org_id}/payments/{payment_id}/confirm', {
            params: { path: { org_id: orgId, payment_id: p.id } },
          }),
        )
      }
    />
  );
}
