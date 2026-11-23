import { useState } from 'react';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { Task } from '../../api/types';
import { useInstallers } from '../../app/data';
import { useOrg } from '../../app/org';
import { ActionDialog, NoteDialog, SelectField, TextArea, TextField } from '../../components';
import { fromIndiaInput, toIndiaInput } from '../../lib/format';

interface Props {
  task: Task;
  onClose: () => void;
}

export function ApproveDialog({ task: t, onClose }: Props) {
  const { orgId } = useOrg();
  return (
    <ActionDialog
      title={`Approve "${t.title}"?`}
      body={
        t.stage.index < t.stage.count
          ? `${t.customer_name} moves on to stage ${t.stage.index + 1}, unless already further. It can't be undone.`
          : "The install waits for your handover. This can't be undone."
      }
      confirm="Approve"
      done="Task approved."
      onClose={onClose}
      run={() =>
        unwrap(
          api.POST('/orgs/{org_id}/tasks/{task_id}/approve', {
            params: { path: { org_id: orgId, task_id: t.id } },
          }),
        )
      }
    />
  );
}

export function ReturnDialog({ task: t, onClose }: Props) {
  const { orgId } = useOrg();
  const [note, setNote] = useState('');
  const [retake, setRetake] = useState<string[]>([]);
  return (
    <ActionDialog
      title="Send back"
      confirm="Send back"
      done="Sent back to the installer."
      onClose={onClose}
      validate={() => ({ note: note.trim() ? undefined : 'Write a few words.' })}
      run={() =>
        unwrap(
          api.POST('/orgs/{org_id}/tasks/{task_id}/return', {
            params: { path: { org_id: orgId, task_id: t.id } },
            body: { note: note.trim(), retake },
          }),
        )
      }
    >
      {(errors) => (
        <>
          <TextArea
            label="What needs doing"
            help="The installer sees this."
            maxLength={500}
            autoFocus
            value={note}
            error={errors.note}
            onChange={(e) => setNote(e.target.value)}
          />
          {t.photos.length > 0 && (
            <fieldset className="options">
              <legend className="t-label">Photos to take again</legend>
              {t.photos.map((slot) => (
                <label key={slot.id} className="option">
                  <input
                    type="checkbox"
                    checked={retake.includes(slot.id)}
                    onChange={(e) =>
                      setRetake((now) =>
                        e.target.checked ? [...now, slot.id] : now.filter((id) => id !== slot.id),
                      )
                    }
                  />
                  {slot.label}
                </label>
              ))}
            </fieldset>
          )}
        </>
      )}
    </ActionDialog>
  );
}

export function ScheduleDialog({ task: t, onClose }: Props) {
  const { orgId } = useOrg();
  const installers = useInstallers(orgId);
  const [due, setDue] = useState(toIndiaInput(t.due_at));
  const [assignee, setAssignee] = useState(t.assignee_active ? t.assignee_id : '');
  return (
    <ActionDialog
      title="Reschedule or reassign"
      body={t.has_problem ? 'This also closes the reported problem.' : undefined}
      confirm="Save"
      done="Task updated."
      onClose={onClose}
      validate={() => ({
        due_at: due ? undefined : 'Choose a date and time.',
        assignee_id: assignee ? undefined : 'Choose an installer.',
      })}
      run={() =>
        unwrap(
          api.PUT('/orgs/{org_id}/tasks/{task_id}/schedule', {
            params: { path: { org_id: orgId, task_id: t.id } },
            body: {
              due_at: fromIndiaInput(due),
              assignee_id: assignee === t.assignee_id ? undefined : assignee,
            },
          }),
        )
      }
    >
      {(errors) => (
        <>
          <SelectField
            label="Installer"
            value={assignee}
            error={errors.assignee_id}
            help={
              installers.error ? "Couldn't load the installers. Close and try again." : undefined
            }
            onChange={(e) => setAssignee(e.target.value)}
          >
            <option value="">Choose</option>
            {installers.data?.map((m) => (
              <option key={m.user_id} value={m.user_id}>
                {m.name}
              </option>
            ))}
          </SelectField>
          <TextField
            label="Due (India time)"
            type="datetime-local"
            value={due}
            error={errors.due_at}
            onChange={(e) => setDue(e.target.value)}
          />
        </>
      )}
    </ActionDialog>
  );
}

export function CancelDialog({ task: t, onClose }: Props) {
  const { orgId } = useOrg();
  return (
    <NoteDialog
      title={`Cancel "${t.title}"?`}
      body="A cancelled task can't be reopened."
      label="Reason"
      help="The installer sees this."
      danger
      confirm="Cancel task"
      done="Task cancelled."
      onClose={onClose}
      send={(note) =>
        unwrap(
          api.POST('/orgs/{org_id}/tasks/{task_id}/cancel', {
            params: { path: { org_id: orgId, task_id: t.id } },
            body: { note },
          }),
        )
      }
    />
  );
}
