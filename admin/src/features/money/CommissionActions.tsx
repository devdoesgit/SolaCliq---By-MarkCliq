import { useState } from 'react';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { Commission } from '../../api/types';
import { useOrg } from '../../app/org';
import {
  ActionDialog,
  DialogButton,
  Facts,
  Person,
  Section,
  StatusPill,
  TextArea,
  TextField,
} from '../../components';
import { formatDay, formatPaise, parseRupees, rupeesInput } from '../../lib/format';
import { COMMISSION } from '../../lib/labels';

// The server's limit (`admin.rs`, approve_commission).
const MAX_COMMISSION = 100_000_000;

export function CommissionActions({
  commission: c,
  wide = false,
}: {
  commission: Commission;
  /** The panel's one big button. */
  wide?: boolean;
}) {
  if (c.status === 'in_review') {
    return (
      <DialogButton
        key={`approve-${c.amount}`}
        label={wide ? `Approve ${formatPaise(c.amount)}` : 'Review'}
        icon={wide ? 'check' : undefined}
        compact={!wide}
        block={wide}
        variant="primary"
        dialog={(close) => <ApproveDialog commission={c} onClose={close} />}
      />
    );
  }
  if (c.status === 'payable') {
    return (
      <DialogButton
        key={`paid-${c.amount}`}
        label="Mark paid"
        compact={!wide}
        block={wide}
        variant="dark"
        dialog={(close) => <PaidDialog commission={c} onClose={close} />}
      />
    );
  }
  return c.status === 'paid' && c.paid_on ? (
    <span className="cell-sub">Paid {formatDay(c.paid_on)}</span>
  ) : (
    '–'
  );
}

/** Beside the customer: the amount, why, and the decision. */
export function CommissionPanel({ commission: c }: { commission: Commission }) {
  const actionable = c.status === 'in_review' || c.status === 'payable';
  const changed = c.proposed_amount != null && c.proposed_amount !== c.amount;
  return (
    <Section title="Commission" aside={<StatusPill {...COMMISSION[c.status]} />}>
      {c.agent_name && <Person name={c.agent_name} sub="Sales Agent, paid by commission" />}
      <p className="big-amount">{formatPaise(c.amount)}</p>
      {c.note && <p className="quote">&ldquo;{c.note}&rdquo;</p>}
      <Facts
        items={[
          ['Agent asked', changed ? formatPaise(c.proposed_amount!) : ''],
          ['Your note', c.admin_note],
          ['Account ending', c.payout_last4],
          ['Payable since', c.payable_since && formatDay(c.payable_since)],
          ['Paid', c.paid_on && formatDay(c.paid_on)],
        ]}
      />
      {actionable && <CommissionActions commission={c} wide />}
      {c.status === 'in_review' && (
        <p className="cell-sub">
          You can change the amount as you approve. It becomes payable when the customer pays the
          advance.
        </p>
      )}
    </Section>
  );
}

function ApproveDialog({
  commission: c,
  onClose,
}: {
  commission: Commission;
  onClose: () => void;
}) {
  const { orgId } = useOrg();
  const [amount, setAmount] = useState(rupeesInput(c.amount));
  const [note, setNote] = useState('');
  const paise = parseRupees(amount);
  return (
    <ActionDialog
      title="Approve commission"
      body={
        <>
          <p>
            {c.agent_name ?? 'The agent'} asked {formatPaise(c.amount)} for {c.customer_name}.{' '}
            {c.advance_paid
              ? 'The advance is paid, so it becomes payable now.'
              : "It becomes payable when the customer's advance is paid."}
          </p>
          {c.note && <p>&ldquo;{c.note}&rdquo;</p>}
        </>
      }
      confirm="Approve"
      done="Commission approved."
      onClose={onClose}
      validate={() => ({
        amount:
          paise === undefined || paise > MAX_COMMISSION ? 'Enter ₹0 to ₹10,00,000.' : undefined,
      })}
      run={() =>
        unwrap(
          api.POST('/orgs/{org_id}/customers/{customer_id}/commission', {
            params: { path: { org_id: orgId, customer_id: c.customer_id } },
            body: {
              amount: paise === c.amount ? undefined : paise,
              note: note.trim() || undefined,
            },
          }),
        )
      }
    >
      {(errors) => (
        <>
          <TextField
            label="Amount, ₹"
            numeric
            value={amount}
            error={errors.amount}
            help="The agent is told if you change it."
            onChange={(e) => setAmount(e.target.value)}
          />
          <TextArea
            label="Note for the agent (optional)"
            maxLength={500}
            value={note}
            error={errors.note}
            onChange={(e) => setNote(e.target.value)}
          />
        </>
      )}
    </ActionDialog>
  );
}

function PaidDialog({ commission: c, onClose }: { commission: Commission; onClose: () => void }) {
  const { orgId } = useOrg();
  return (
    <ActionDialog
      title={`${formatPaise(c.amount)} paid to ${c.agent_name ?? 'the agent'}?`}
      body={
        <p>
          SolaCliq doesn&rsquo;t send money: pay them first.{' '}
          {c.payout_last4
            ? `Their account ends ${c.payout_last4}.`
            : "They haven't added a bank account."}{' '}
          This can&rsquo;t be undone.
        </p>
      }
      confirm="Yes, paid"
      done="Commission marked paid."
      onClose={onClose}
      run={() =>
        unwrap(
          api.POST('/orgs/{org_id}/customers/{customer_id}/commission/paid', {
            params: { path: { org_id: orgId, customer_id: c.customer_id } },
          }),
        )
      }
    />
  );
}
