import { useState } from 'react';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { LeadStatus, LeadSummary, Member } from '../../api/types';
import { useOrg } from '../../app/org';
import { ActionDialog, NoteDialog, SelectField } from '../../components';
import { LEAD } from '../../lib/labels';

type Change = { status?: LeadStatus; note?: string; agent_id?: string | null };

function useUpdate(leadId: string) {
  const { orgId } = useOrg();
  return (body: Change) =>
    unwrap(
      api.PATCH('/orgs/{org_id}/leads/{lead_id}', {
        params: { path: { org_id: orgId, lead_id: leadId } },
        body,
      }),
    );
}

/** Hand a lead to one Sales Agent, who is told in the app. */
export function GiveDialog({
  lead,
  agent,
  onClose,
}: {
  lead: LeadSummary;
  agent: Member;
  onClose: () => void;
}) {
  const update = useUpdate(lead.id);
  return (
    <ActionDialog
      title={`Give ${lead.name} to ${agent.name}?`}
      body={`${agent.name} gets a notification and sees the lead in the app, with a Call button.${
        lead.agent_name ? ` ${lead.agent_name} no longer has it.` : ''
      }`}
      confirm="Give lead"
      done={`Lead given to ${agent.name}.`}
      onClose={onClose}
      run={() => update({ agent_id: agent.user_id })}
    />
  );
}

/** Choose the agent from all of them (the detail page, or a big team). */
export function ChooseAgentDialog({
  lead,
  agents,
  onClose,
}: {
  lead: LeadSummary;
  agents: Member[];
  onClose: () => void;
}) {
  const update = useUpdate(lead.id);
  const [agentId, setAgentId] = useState('');
  const chosen = agents.find((a) => a.user_id === agentId);
  return (
    <ActionDialog
      title={`Give ${lead.name} to`}
      body="They get a notification and see the lead in the app, with a Call button."
      confirm="Give lead"
      done={chosen ? `Lead given to ${chosen.name}.` : 'Lead given.'}
      onClose={onClose}
      validate={() => ({ agent: agentId ? undefined : 'Choose a Sales Agent.' })}
      run={() => update({ agent_id: agentId })}
    >
      {(errors) => (
        <SelectField
          label="Sales Agent"
          value={agentId}
          error={errors.agent}
          onChange={(e) => setAgentId(e.target.value)}
        >
          <option value="">Choose</option>
          {agents
            .filter((a) => a.user_id !== lead.agent_id)
            .map((a) => (
              <option key={a.user_id} value={a.user_id}>
                {a.name}
              </option>
            ))}
        </SelectField>
      )}
    </ActionDialog>
  );
}

/** Take a lead back from its agent. */
export function TakeBackDialog({ lead, onClose }: { lead: LeadSummary; onClose: () => void }) {
  const update = useUpdate(lead.id);
  return (
    <ActionDialog
      title={`Take ${lead.name} back from ${lead.agent_name}?`}
      body="It leaves their app. You can give it to someone else."
      confirm="Take back"
      done="Lead taken back."
      onClose={onClose}
      run={() => update({ agent_id: null })}
    />
  );
}

/** Move a lead to another status. */
export function StatusDialog({
  lead,
  status,
  onClose,
}: {
  lead: LeadSummary;
  status: LeadStatus;
  onClose: () => void;
}) {
  const update = useUpdate(lead.id);
  const label = LEAD[status].label;
  return (
    <ActionDialog
      title={`Mark ${lead.name} as ${label.toLowerCase()}?`}
      body={
        status === 'won'
          ? 'Register them as a customer the usual way: an agent adds them in the app.'
          : undefined
      }
      confirm={`Mark ${label.toLowerCase()}`}
      done={`Marked ${label.toLowerCase()}.`}
      onClose={onClose}
      run={() => update({ status })}
    />
  );
}

/** Write or replace the note on a lead. */
export function LeadNoteDialog({ lead, onClose }: { lead: LeadSummary; onClose: () => void }) {
  const update = useUpdate(lead.id);
  return (
    <NoteDialog
      title={`Note on ${lead.name}`}
      label="Note"
      help="What was said, and what happens next. Replaces the note there."
      confirm="Save note"
      done="Note saved."
      onClose={onClose}
      send={(note) => update({ note })}
    />
  );
}

/** Delete a lead for good: for someone who asked to be forgotten. */
export function DeleteLeadDialog({
  lead,
  onClose,
  onDeleted,
}: {
  lead: LeadSummary;
  onClose: () => void;
  onDeleted: () => void;
}) {
  const { orgId } = useOrg();
  return (
    <ActionDialog
      title={`Delete ${lead.name}'s lead?`}
      body="Their details are gone for good, from you and their agent. Do this when someone asks to be forgotten."
      confirm="Delete lead"
      danger
      done="Lead deleted."
      onClose={onClose}
      run={async () => {
        await unwrap(
          api.DELETE('/orgs/{org_id}/leads/{lead_id}', {
            params: { path: { org_id: orgId, lead_id: lead.id } },
          }),
        );
        onDeleted();
      }}
    />
  );
}
