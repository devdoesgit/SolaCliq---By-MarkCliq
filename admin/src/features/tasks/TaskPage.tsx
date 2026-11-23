import { useQuery } from '@tanstack/react-query';
import { Link, useParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { Task } from '../../api/types';
import { FILE_LINKS_MS } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  DialogButton,
  Facts,
  FileView,
  Icon,
  MapLink,
  Notice,
  PageHeader,
  Person,
  QueryState,
  Section,
  StageBar,
  StatusPill,
} from '../../components';
import { formatDateTime, formatTime, formatWhen } from '../../lib/format';
import { EVENT, PROBLEM, TASK } from '../../lib/labels';
import { ApproveDialog, CancelDialog, ReturnDialog, ScheduleDialog } from './TaskDialogs';

/** W3: one task. The proof on the left, the decision on the right. */
export function TaskPage() {
  const { orgId, to } = useOrg();
  const { taskId = '' } = useParams();
  const task = useQuery({
    queryKey: ['org', orgId, 'task', taskId],
    queryFn: ({ signal }) =>
      unwrap(
        api.GET('/orgs/{org_id}/admin/tasks/{task_id}', {
          params: { path: { org_id: orgId, task_id: taskId } },
          signal,
        }),
      ),
    // Its photo links expire.
    refetchInterval: FILE_LINKS_MS,
  });

  return (
    <QueryState query={task}>
      {(t) => (
        <>
          <PageHeader
            title={`${t.customer_name} · ${t.title}`}
            back={{ to: to('tasks'), label: 'Back to tasks' }}
            meta={`Tasks / ${TASK[t.status].label} / ${t.reference} · ${t.assignee_name}`}
          />
          <div className="split">
            <div className="col">
              <Alerts task={t} />
              {/* Open or closed, the task leads; under review, its proof does. */}
              {t.status !== 'submitted' && <Summary task={t} />}
              <Photos task={t} />
              <div className="pair">
                <Checklist task={t} />
                <Notes task={t} />
              </div>
              <Section title="Details">
                <Facts
                  items={[
                    ['Phone', t.phone && <a href={`tel:+91${t.phone}`}>{t.phone}</a>],
                    ['Address', t.address],
                    ['Site', t.lat === undefined ? undefined : <MapLink lat={t.lat} lng={t.lng} />],
                    ['Installer', t.assignee_name],
                    ['Due', formatDateTime(t.due_at)],
                    ['Submitted', t.submitted_at && formatDateTime(t.submitted_at)],
                  ]}
                />
              </Section>
            </div>
            <div className="col col-side">
              {t.status === 'submitted' && <Summary task={t} />}
              <Decisions task={t} />
              <History task={t} />
              {t.status !== 'submitted' && !isFinal(t) && (
                <Link className="sc-btn sc-btn-block" to={to(`projects/${t.customer_id}`)}>
                  <Icon name="projects" size={16} />
                  <span>Open project</span>
                </Link>
              )}
            </div>
          </div>
        </>
      )}
    </QueryState>
  );
}

function Summary({ task: t }: { task: Task }) {
  const { to } = useOrg();
  return (
    <section className="card" aria-label="Task">
      <div className="card-head">
        <span className="eyebrow">
          {t.reference} · Stage {t.stage.index} of {t.stage.count}
        </span>
        <span className="pills">
          {t.has_problem && <StatusPill tone="warning" label="Problem" />}
          <StatusPill {...TASK[t.status]} />
        </span>
      </div>
      <p className="card-lead">{t.title}</p>
      <StageBar index={t.stage.index} count={t.stage.count} finished={false} />
      <Link className="row row-plain" to={to(`customers/${t.customer_id}`)}>
        <Person name={t.customer_name} sub="Open project" />
        <span className="row-chevron">
          <Icon name="chevron" />
        </span>
      </Link>
    </section>
  );
}

const isFinal = (t: Task) => t.status === 'approved' || t.status === 'cancelled';

function Decisions({ task: t }: { task: Task }) {
  const { to } = useOrg();
  if (isFinal(t)) {
    return (
      <Section title="This task is closed">
        <p className="cell-sub">
          {t.status === 'approved' ? 'Approved' : 'Cancelled'} tasks are locked. The history stays
          on the project.
        </p>
        <Link className="sc-btn sc-btn-block" to={to(`projects/${t.customer_id}`)}>
          Open project
        </Link>
      </Section>
    );
  }
  if (t.status === 'submitted') {
    return (
      <Section title="Your decision">
        <div className="decide">
          <DialogButton
            key="approve"
            label="Approve"
            icon="check"
            variant="primary"
            block
            dialog={(close) => <ApproveDialog task={t} onClose={close} />}
          />
          <p className="next-step">
            <span className="eyebrow">On approve</span>
            {t.stage.index < t.stage.count
              ? `The install moves on to stage ${t.stage.index + 1}, unless it's already further.`
              : 'The install waits for your handover.'}
          </p>
          <DialogButton
            key="return"
            label="Send back"
            icon="back"
            block
            dialog={(close) => <ReturnDialog task={t} onClose={close} />}
          />
          <DialogButton
            key="cancel-submitted"
            label="Cancel task"
            icon="close"
            variant="danger"
            block
            dialog={(close) => <CancelDialog task={t} onClose={close} />}
          />
        </div>
      </Section>
    );
  }
  return (
    <Section title="Manage">
      <div className="manage-list">
        <DialogButton
          key="schedule"
          label="Reschedule or reassign"
          hint="Change the day, or pick another installer"
          icon="alarm"
          dialog={(close) => <ScheduleDialog task={t} onClose={close} />}
        />
        <DialogButton
          key="cancel-open"
          label="Cancel task"
          hint="The installer is told, history is kept"
          icon="close"
          variant="danger"
          dialog={(close) => <CancelDialog task={t} onClose={close} />}
        />
      </div>
    </Section>
  );
}

function Alerts({ task: t }: { task: Task }) {
  const final = t.status === 'approved' || t.status === 'cancelled';
  return (
    <>
      {!final && !t.assignee_active && (
        <Notice
          tone="danger"
          title={`${t.assignee_name} is no longer in the company`}
          body={
            t.status === 'submitted'
              ? 'Approve it, or send it back and then give it to another installer.'
              : 'Give it to another installer with "Reschedule or reassign".'
          }
        />
      )}
      {t.has_problem && t.problem && (
        <Section title="Problem reported" className="card-problem">
          <Facts
            items={[
              ['Reason', PROBLEM[t.problem.reason]],
              ['What happened', t.problem.note],
              ['When', formatWhen(t.problem.at)],
            ]}
          />
          <p className="cell-sub">Rescheduling or reassigning closes the problem.</p>
          {t.problem.photo && (
            <div className="file-single">
              <FileView file={t.problem.photo} name="the problem photo" />
            </div>
          )}
        </Section>
      )}
      {t.status === 'returned' && t.returned_note && (
        <Notice
          tone="danger"
          title={`Returned to ${t.assignee_name} · waiting for the retake`}
          body={`Your note: “${t.returned_note}”`}
        />
      )}
      {t.status === 'approved' && (
        <Notice
          tone="success"
          title={`Approved ${formatWhen(t.status_at)}`}
          body={
            t.stage.index < t.stage.count
              ? `${t.customer_name} moved on to stage ${t.stage.index + 1}, unless already further.`
              : `${t.customer_name}'s install is ready for handover.`
          }
        />
      )}
      {t.status === 'cancelled' && t.cancelled_note && (
        <Notice tone="info" title="Cancelled" body={t.cancelled_note} />
      )}
    </>
  );
}

function Photos({ task: t }: { task: Task }) {
  if (t.photos.length === 0) return null;
  const taken = t.photos.filter((slot) => slot.photo).length;
  if (taken === 0) {
    return (
      <Section title="Photos needed">
        <ul className="needed">
          {t.photos.map((slot) => (
            <li key={slot.id} className="needed-item">
              <Icon name="camera" size={15} />
              {slot.label}
              {slot.retake && <StatusPill tone="danger" label="Retake asked" />}
            </li>
          ))}
        </ul>
      </Section>
    );
  }
  return (
    <Section
      title="Proof photos"
      aside={
        <span className={taken === t.photos.length ? 'good' : undefined}>
          {taken} of {t.photos.length}
        </span>
      }
    >
      <ul className="tiles tiles-proof">
        {t.photos.map((slot) => (
          <li key={slot.id} className="tile">
            {slot.photo ? (
              <div className="proof">
                <FileView file={slot.photo} name={slot.label} />
                <span className="proof-when" aria-hidden="true">
                  <Icon name="pin" size={12} />
                  {formatTime(slot.photo.taken_at)}
                </span>
              </div>
            ) : (
              <p className="file-missing">No photo yet</p>
            )}
            <div className="tile-text">
              <span className="tile-title">{slot.label}</span>
              {slot.retake && <StatusPill tone="danger" label="Retake asked" />}
              {slot.photo && (
                <span className="cell-sub">
                  <MapLink lat={slot.photo.lat} lng={slot.photo.lng} />
                  {slot.photo.accuracy_m !== undefined &&
                    ` ±${Math.round(slot.photo.accuracy_m)} m`}
                  <span className="visually-hidden">, {formatDateTime(slot.photo.taken_at)}</span>
                </span>
              )}
            </div>
          </li>
        ))}
      </ul>
    </Section>
  );
}

function Checklist({ task: t }: { task: Task }) {
  if (t.checklist.length === 0) return null;
  return (
    <Section title="Checklist">
      <ul className="checks" aria-label="Checklist">
        {t.checklist.map((item) => (
          <li key={item.id}>
            <span className={item.done ? 'tick tick-done' : 'tick'} aria-hidden="true">
              {item.done && <Icon name="check" size={12} />}
            </span>
            <span>
              {item.text}
              <span className="visually-hidden">, {item.done ? 'done' : 'not done'}</span>
            </span>
          </li>
        ))}
      </ul>
    </Section>
  );
}

function Notes({ task: t }: { task: Task }) {
  if (!t.worker_note && !t.admin_note) return null;
  return (
    <Section title={t.worker_note ? 'Note from the installer' : 'Note for the installer'}>
      {t.worker_note && (
        <>
          <p className="note-text">{t.worker_note}</p>
          <Person
            size="sm"
            name={t.assignee_name}
            sub={t.submitted_at && `Submitted ${formatWhen(t.submitted_at)}`}
          />
        </>
      )}
      {t.admin_note && (
        <p className="quote">
          {t.worker_note && <span className="eyebrow">Your note</span>}
          {t.admin_note}
        </p>
      )}
    </Section>
  );
}

function History({ task: t }: { task: Task }) {
  return (
    <Section
      title="History"
      aside={
        <span className="with-icon">
          <Icon name="lock" size={13} />
          Kept
        </span>
      }
    >
      <ol className="history">
        {t.events.map((event) => (
          <li key={`${event.at}-${event.kind}`} className={`history-${event.kind}`}>
            <span className="history-title">
              {EVENT[event.kind]} by {event.actor_name}
            </span>
            {event.detail && <p className="history-detail">{event.detail}</p>}
            <span className="cell-sub">{formatWhen(event.at)}</span>
          </li>
        ))}
      </ol>
    </Section>
  );
}
