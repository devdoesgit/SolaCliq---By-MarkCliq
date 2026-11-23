import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useRef, useState, type FormEvent } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router';
import { api } from '../../api/client';
import { ApiProblem, unwrap } from '../../api/problem';
import type { CustomerSummary } from '../../api/types';
import { useAnnounce } from '../../app/announce';
import { useInstallers, useStages } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  Avatar,
  Button,
  Notice,
  PageHeader,
  QueryState,
  Section,
  SelectField,
  TextArea,
  TextField,
  type Errors,
} from '../../components';
import { fromIndiaInput } from '../../lib/format';
import { useMe } from '../auth/session';
import { LineList } from './LineList';
import { TaskPreview } from './TaskPreview';

type Picked = Pick<CustomerSummary, 'id' | 'name' | 'reference' | 'stage' | 'place' | 'system_kw'>;

const FORM = 'new-task';

/** W3: a task for an installer. Its customer first, then the rest. */
export function NewTaskPage() {
  const { orgId, to } = useOrg();
  const [params, setParams] = useSearchParams();
  const id = params.get('customer') ?? '';
  const customer = useQuery({
    queryKey: ['org', orgId, 'customer', id],
    enabled: id !== '',
    queryFn: ({ signal }) =>
      unwrap(
        api.GET('/orgs/{org_id}/admin/customers/{customer_id}', {
          params: { path: { org_id: orgId, customer_id: id } },
          signal,
        }),
      ),
  });

  return (
    <>
      <PageHeader
        title="New task"
        meta="Tasks / New"
        actions={
          <>
            <Link className="sc-btn sc-btn-outline sc-btn-compact" to={to('tasks')}>
              <span>Cancel</span>
            </Link>
            {id && customer.data?.kyc_status === 'approved' && (
              <Button type="submit" form={FORM} variant="primary" compact icon="check">
                Assign task
              </Button>
            )}
          </>
        }
      />
      {id ? (
        <QueryState query={customer}>
          {(c) =>
            c.kyc_status === 'approved' ? (
              <TaskForm key={c.id} customer={c} onChange={() => setParams({})} />
            ) : (
              <Notice
                tone="danger"
                title={`${c.name} isn't verified`}
                body="Tasks are only for verified customers."
              />
            )
          }
        </QueryState>
      ) : (
        <CustomerPicker onPick={(picked) => setParams({ customer: picked })} />
      )}
    </>
  );
}

function CustomerPicker({ onPick }: { onPick: (id: string) => void }) {
  const { orgId } = useOrg();
  const [text, setText] = useState('');
  const [q, setQ] = useState('');
  const found = useQuery({
    queryKey: ['org', orgId, 'customer-picker', q],
    queryFn: ({ signal }) =>
      unwrap(
        api.GET('/orgs/{org_id}/admin/customers', {
          params: {
            path: { org_id: orgId },
            query: { kyc_status: 'approved', q: q || undefined, limit: 25 },
          },
          signal,
        }),
      ),
  });
  return (
    <Section title="Which project?">
      <form
        className="search"
        role="search"
        onSubmit={(event) => {
          event.preventDefault();
          setQ(text.trim());
        }}
      >
        <TextField
          label="Search verified customers"
          type="search"
          maxLength={100}
          value={text}
          onChange={(e) => setText(e.target.value)}
        />
        <Button type="submit">Search</Button>
      </form>
      <QueryState query={found}>
        {({ items, page }) =>
          items.length === 0 ? (
            <p className="empty">
              {q ? `No verified customers match "${q}".` : 'No verified customers yet.'}
            </p>
          ) : (
            <>
              <ul className="sc-list">
                {items.map((c) => (
                  <li key={c.id}>
                    <button type="button" className="sc-row pick" onClick={() => onPick(c.id)}>
                      <span className="sc-row-main">
                        <span className="t-row-title">{c.name}</span>
                        <span className="cell-sub">
                          {c.reference} · {c.place}
                        </span>
                      </span>
                      {c.stage && <span className="cell-sub">{c.stage.name}</span>}
                    </button>
                  </li>
                ))}
              </ul>
              {page.next_cursor && (
                <p className="t-body-sm muted">More match. Search to narrow it down.</p>
              )}
            </>
          )
        }
      </QueryState>
    </Section>
  );
}

function TaskForm({ customer, onChange }: { customer: Picked; onChange: () => void }) {
  const { orgId, to } = useOrg();
  const navigate = useNavigate();
  const announce = useAnnounce();
  const client = useQueryClient();
  const installers = useInstallers(orgId);
  const { data: me } = useMe();
  const settings = useStages(orgId);
  const [stage, setStage] = useState(String(customer.stage?.index ?? 1));
  // Undefined until typed: it follows the stage's name.
  const [typedTitle, setTitle] = useState<string>();
  const [assignee, setAssignee] = useState('');
  const [due, setDue] = useState('');
  const [note, setNote] = useState('');
  // Undefined until edited: they follow the stage's template (F19).
  const [typedPhotos, setPhotos] = useState<string[]>();
  const [typedChecks, setChecks] = useState<string[]>();
  const [errors, setErrors] = useState<Errors>({});
  const [problem, setProblem] = useState<ApiProblem | null>(null);
  const [busy, setBusy] = useState(false);
  const sending = useRef(false);
  // The same key while the task is the same, so a retry can't make two.
  const sent = useRef({ body: '', key: '' });

  const template = settings.data?.[Number(stage) - 1];
  const title = typedTitle ?? template?.name ?? '';
  const photos = typedPhotos ?? (template?.photos.length ? template.photos : ['']);
  const checks = typedChecks ?? template?.checklist ?? [];
  // Says where the lines came from while they're the template's.
  const fromTemplate = (edited: string[] | undefined, lines: string[] = []) =>
    !edited && template && lines.length ? ` · from the ${template.name} template` : '';

  // Another stage brings its own template.
  function chooseStage(value: string) {
    setStage(value);
    setPhotos(undefined);
    setChecks(undefined);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (sending.current) return;
    const found: Errors = {
      title: title.trim() ? undefined : 'Enter a title.',
      assignee_id: assignee ? undefined : 'Choose an installer.',
      due_at: due ? undefined : 'Choose a date and time.',
    };
    setErrors(found);
    setProblem(null);
    if (Object.values(found).some(Boolean)) {
      event.currentTarget.querySelector<HTMLElement>('[required]:invalid')?.focus();
      return;
    }
    const body = {
      customer_id: customer.id,
      title: title.trim(),
      stage_index: Number(stage),
      assignee_id: assignee,
      due_at: fromIndiaInput(due),
      admin_note: note.trim() || undefined,
      photos: photos
        .map((label) => label.trim())
        .filter(Boolean)
        .map((label, i) => ({ id: `photo-${i + 1}`, label })),
      checklist: checks
        .map((text) => text.trim())
        .filter(Boolean)
        .map((text, i) => ({ id: `check-${i + 1}`, text })),
    };
    const json = JSON.stringify(body);
    if (sent.current.body !== json) sent.current = { body: json, key: crypto.randomUUID() };
    sending.current = true;
    setBusy(true);
    try {
      const done = await unwrap(
        api.POST('/orgs/{org_id}/tasks', {
          params: { path: { org_id: orgId }, header: { 'Idempotency-Key': sent.current.key } },
          body,
        }),
      );
      void client.invalidateQueries({ queryKey: ['org', orgId] });
      announce('Task assigned. The installer is told.');
      void navigate(to(`tasks/${done.id}`), { replace: true });
    } catch (error) {
      const failed =
        error instanceof ApiProblem
          ? error
          : new ApiProblem(0, 'unknown', 'Something went wrong. Try again.');
      setProblem(failed);
      setErrors(failed.fields);
    } finally {
      sending.current = false;
      setBusy(false);
    }
  }

  const stages = settings.data?.map((s) => s.name) ?? [];
  const place = [customer.system_kw && `${customer.system_kw} kW`, customer.place]
    .filter(Boolean)
    .join(' · ');

  return (
    <div className="split split-preview">
      <form id={FORM} className="card form" onSubmit={(event) => void submit(event)} noValidate>
        {problem && (
          <Notice
            tone="danger"
            announce
            title={problem.message}
            body={Object.values(problem.fields).join(' ')}
          />
        )}
        {installers.error && <Notice tone="danger" title="Couldn't load the installers" announce />}
        {settings.error && <Notice tone="danger" title="Couldn't load the stages" announce />}
        {installers.data?.length === 0 && (
          <Notice tone="warning" title="No installers yet" body="Add one in Team first." />
        )}
        <div className="picked">
          <span className="field-label">Project</span>
          <div className="picked-box">
            <Avatar name={customer.name} size="sm" />
            <span className="picked-name">
              {[customer.name, place].filter(Boolean).join(' · ')}
            </span>
            <button type="button" className="link-button" onClick={onChange}>
              Change customer
            </button>
          </div>
        </div>
        <div className="form-grid">
          <SelectField label="Stage" value={stage} onChange={(e) => chooseStage(e.target.value)}>
            {stages.map((name, i) => (
              <option key={name} value={i + 1}>
                {i + 1}. {name}
              </option>
            ))}
          </SelectField>
          <SelectField
            label="Installer"
            required
            value={assignee}
            error={errors.assignee_id}
            onChange={(e) => setAssignee(e.target.value)}
          >
            <option value="">Choose</option>
            {installers.data?.map((m) => (
              <option key={m.user_id} value={m.user_id}>
                {m.name}
                {m.status === 'invited' ? " (hasn't set up the app yet)" : ''}
              </option>
            ))}
          </SelectField>
          <TextField
            label="Title"
            required
            maxLength={100}
            value={title}
            error={errors.title}
            onChange={(e) => setTitle(e.target.value)}
          />
          <TextField
            label="Due (India time)"
            type="datetime-local"
            required
            value={due}
            error={errors.due_at}
            onChange={(e) => setDue(e.target.value)}
          />
        </div>
        <LineList
          title={`Checklist${fromTemplate(typedChecks, template?.checklist)}`}
          item="Step"
          icon="tasks"
          max={200}
          lines={checks}
          error={errors.checklist}
          onChange={setChecks}
        />
        <LineList
          title={`Photos the installer must add${fromTemplate(typedPhotos, template?.photos)}`}
          item="Photo"
          icon="camera"
          chips
          max={80}
          lines={photos}
          error={errors.photos}
          onChange={setPhotos}
        />
        <TextArea
          label="Note for the installer (optional)"
          maxLength={500}
          value={note}
          error={errors.admin_note}
          onChange={(e) => setNote(e.target.value)}
        />
        {busy && (
          <p className="cell-sub" role="status">
            Sending…
          </p>
        )}
      </form>
      <TaskPreview
        installer={installers.data?.find((m) => m.user_id === assignee)?.name}
        title={title}
        stage={Number(stage)}
        stages={stages.length || 7}
        due={due ? fromIndiaInput(due) : undefined}
        customer={customer.name}
        place={place}
        note={note.trim()}
        from={me?.name ?? ''}
        photos={photos.filter((label) => label.trim())}
        checks={checks.filter((text) => text.trim())}
      />
    </div>
  );
}
