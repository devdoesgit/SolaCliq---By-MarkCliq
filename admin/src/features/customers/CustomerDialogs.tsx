import { useState } from 'react';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { Customer, CustomerDocument } from '../../api/types';
import { useSettings } from '../../app/data';
import { useOrg } from '../../app/org';
import { ActionDialog, NoteDialog, SelectField, TextField, type Errors } from '../../components';
import { count, formatPaise, parseRupees, rupeesInput } from '../../lib/format';

interface Props {
  customer: Customer;
  onClose: () => void;
}

// The server's limits (`admin.rs`, check_price).
const MIN_TOTAL = 1000;
const MAX_TOTAL = 10_000_000_000;

function checkPrice(total: string, subsidy: string): Errors {
  const paise = parseRupees(total);
  const off = parseRupees(subsidy);
  const validTotal = paise !== undefined && paise >= MIN_TOTAL && paise <= MAX_TOTAL;
  return {
    total: validTotal ? undefined : 'Enter ₹10 up to ₹10 crore.',
    subsidy:
      off === undefined
        ? 'Enter an amount, or 0.'
        : validTotal && off > paise
          ? "It can't be more than the price."
          : undefined,
  };
}

function PriceFields({
  total,
  subsidy,
  setTotal,
  setSubsidy,
  errors,
  subsidyHelp,
}: {
  total: string;
  subsidy: string;
  setTotal: (value: string) => void;
  setSubsidy: (value: string) => void;
  errors: Errors;
  subsidyHelp?: string;
}) {
  const paise = parseRupees(total);
  return (
    <>
      <TextField
        label="System price, ₹"
        numeric
        autoFocus
        value={total}
        error={errors.total}
        help={paise === undefined ? 'The full price, before subsidy.' : formatPaise(paise)}
        onChange={(e) => setTotal(e.target.value)}
      />
      <TextField
        label="Subsidy, ₹"
        numeric
        value={subsidy}
        error={errors.subsidy}
        help={subsidyHelp}
        onChange={(e) => setSubsidy(e.target.value)}
      />
    </>
  );
}

export function VerifyDialog({ customer: c, onClose }: Props) {
  const { orgId } = useOrg();
  const [total, setTotal] = useState('');
  const [subsidy, setSubsidy] = useState(rupeesInput(c.suggested_subsidy));
  return (
    <ActionDialog
      title={`Verify ${c.name}`}
      body="All documents become verified and the install starts. The customer is asked for a 30% advance, due in 7 days."
      confirm="Verify"
      done="Verified."
      onClose={onClose}
      validate={() => checkPrice(total, subsidy)}
      run={() =>
        unwrap(
          api.POST('/orgs/{org_id}/customers/{customer_id}/verify', {
            params: { path: { org_id: orgId, customer_id: c.id } },
            body: { total: parseRupees(total)!, subsidy: parseRupees(subsidy)! },
          }),
        )
      }
    >
      {(errors) => (
        <PriceFields
          {...{ total, subsidy, setTotal, setSubsidy, errors }}
          subsidyHelp={
            c.subsidy_requested
              ? 'Filled from the PM Surya Ghar table. Change it if needed.'
              : "They didn't ask for a subsidy."
          }
        />
      )}
    </ActionDialog>
  );
}

export function PriceDialog({ customer: c, onClose }: Props) {
  const { orgId } = useOrg();
  const [total, setTotal] = useState(rupeesInput(c.price?.total ?? 0));
  const [subsidy, setSubsidy] = useState(rupeesInput(c.price?.subsidy ?? 0));
  const claimed = c.payments.find((p) => p.status === 'claimed');
  return (
    <ActionDialog
      title="Change price"
      confirm="Change price"
      done="Price changed."
      onClose={onClose}
      body={
        <>
          <p>The three payments are worked out again: 30%, 60% and 10%.</p>
          {claimed && (
            <p className="warn">
              The customer says they paid {formatPaise(claimed.amount)}. That goes back to due at
              the new amount. If the money came, confirm it instead of changing the price.
            </p>
          )}
        </>
      }
      validate={() => checkPrice(total, subsidy)}
      run={() =>
        unwrap(
          api.PUT('/orgs/{org_id}/admin/customers/{customer_id}/price', {
            params: { path: { org_id: orgId, customer_id: c.id } },
            body: { total: parseRupees(total)!, subsidy: parseRupees(subsidy)! },
          }),
        )
      }
    >
      {(errors) => <PriceFields {...{ total, subsidy, setTotal, setSubsidy, errors }} />}
    </ActionDialog>
  );
}

export function StageDialog({ customer: c, onClose }: Props) {
  const { orgId } = useOrg();
  const settings = useSettings(orgId);
  const current = c.stage?.index ?? 1;
  const [stage, setStage] = useState(String(current));
  return (
    <ActionDialog
      title="Move stage"
      body="For a step that needed no installer, or a correction. The customer sees it in the app."
      confirm="Move"
      done="Stage moved."
      onClose={onClose}
      validate={() => ({
        stage_index: Number(stage) === current ? 'Choose another stage.' : undefined,
      })}
      run={() =>
        unwrap(
          api.PUT('/orgs/{org_id}/admin/customers/{customer_id}/stage', {
            params: { path: { org_id: orgId, customer_id: c.id } },
            body: { stage_index: Number(stage) },
          }),
        )
      }
    >
      {(errors) => (
        <SelectField
          label="Stage"
          value={stage}
          error={errors.stage_index}
          onChange={(e) => setStage(e.target.value)}
        >
          {settings.data?.stages.map((name, i) => (
            <option key={name} value={i + 1}>
              {i + 1}. {name}
              {i + 1 === current ? ' (now)' : ''}
            </option>
          ))}
        </SelectField>
      )}
    </ActionDialog>
  );
}

export function HandoverDialog({ customer: c, onClose }: Props) {
  const { orgId } = useOrg();
  const unpaid = c.payments.filter((p) => p.status !== 'paid').length;
  return (
    <ActionDialog
      title={`Hand over to ${c.name}?`}
      confirm="Hand over"
      done="Handed over."
      onClose={onClose}
      body={
        <>
          <p>The install is finished as of today. This can&rsquo;t be undone.</p>
          {unpaid > 0 && (
            <p className="warn">
              {count(unpaid, 'payment')} {unpaid === 1 ? "isn't" : "aren't"} paid yet.
            </p>
          )}
        </>
      }
      run={() =>
        unwrap(
          api.POST('/orgs/{org_id}/customers/{customer_id}/handover', {
            params: { path: { org_id: orgId, customer_id: c.id } },
          }),
        )
      }
    />
  );
}

export function RejectDialog({ customer: c, onClose }: Props) {
  const { orgId } = useOrg();
  return (
    <NoteDialog
      title={`Don't take up ${c.name}?`}
      body="The registration closes and can't be reopened."
      label="Reason"
      help="The agent and the customer see this."
      danger
      confirm="Don't take up"
      done="Not taken up."
      onClose={onClose}
      send={(note) =>
        unwrap(
          api.POST('/orgs/{org_id}/customers/{customer_id}/reject', {
            params: { path: { org_id: orgId, customer_id: c.id } },
            body: { note },
          }),
        )
      }
    />
  );
}

export function ReturnDocumentDialog({
  customer: c,
  document,
  onClose,
}: Props & { document: CustomerDocument }) {
  const { orgId } = useOrg();
  return (
    <NoteDialog
      title={`Send ${document.title} back`}
      label="What's wrong"
      help="The agent sees this and sends it again."
      confirm="Send back"
      done="Sent back to the agent."
      onClose={onClose}
      send={(note) =>
        unwrap(
          api.POST('/orgs/{org_id}/customers/{customer_id}/documents/{kind}/return', {
            params: { path: { org_id: orgId, customer_id: c.id, kind: document.kind } },
            body: { note },
          }),
        )
      }
    />
  );
}
