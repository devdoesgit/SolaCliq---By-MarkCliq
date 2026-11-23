import { Link, useSearchParams } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import type { TaskSummary, TaskView } from '../../api/types';
import { useInstallers, usePages } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  Avatar,
  Button,
  Icon,
  PageHeader,
  QueryState,
  SelectField,
  StatusPill,
} from '../../components';
import { formatShortDate, formatTime, formatWhen } from '../../lib/format';

interface Column {
  view: TaskView;
  label: string;
  hint: string;
  dot: string;
  empty: string;
}

// The design's four columns.
const COLUMNS: Column[] = [
  { view: 'assigned', label: 'Assigned', hint: 'by due date', dot: 'sun', empty: 'None assigned.' },
  {
    view: 'submitted',
    label: 'In review',
    hint: 'needs you',
    dot: 'tan',
    empty: 'Nothing is waiting for your approval.',
  },
  {
    view: 'returned',
    label: 'Returned',
    hint: 'with installer',
    dot: 'danger',
    empty: 'None sent back.',
  },
  { view: 'done', label: 'Done', hint: 'newest first', dot: 'success', empty: 'None done yet.' },
];

const PROBLEMS: Column = {
  view: 'problem',
  label: 'Problems',
  hint: 'reported',
  dot: 'danger',
  empty: 'No problems reported.',
};

// More than this and the chips would take over the screen.
const MOST_CHIPS = 6;

/** W3: every task, on a board by where it stands. */
export function TasksPage() {
  const { orgId, name, to } = useOrg();
  const [params, setParams] = useSearchParams();
  const installers = useInstallers(orgId);
  const assignee = params.get('assignee') ?? '';
  const problems = params.get('view') === 'problem';

  const people = installers.data ?? [];
  // Someone removed still has tasks, and links point to them.
  const listed = !assignee || people.some((m) => m.user_id === assignee);

  function change(key: string, value: string) {
    const next = new URLSearchParams(params);
    if (value) next.set(key, value);
    else next.delete(key);
    setParams(next);
  }
  function chipTo(key: string, value: string) {
    const next = new URLSearchParams(params);
    if (value) next.set(key, value);
    else next.delete(key);
    return `?${next}`;
  }

  return (
    <>
      <PageHeader
        title="Tasks"
        meta={name}
        actions={
          <Link className="sc-btn sc-btn-primary sc-btn-compact" to={to('tasks/new')}>
            <Icon name="plus" size={16} />
            <span>New task</span>
          </Link>
        }
      />
      <div className="toolbar">
        {people.length > MOST_CHIPS ? (
          <SelectField
            label="Installer"
            value={assignee}
            onChange={(e) => change('assignee', e.target.value)}
          >
            <option value="">All installers</option>
            {!listed && <option value={assignee}>The chosen installer</option>}
            {people.map((m) => (
              <option key={m.user_id} value={m.user_id}>
                {m.name}
              </option>
            ))}
          </SelectField>
        ) : (
          <nav className="chips" aria-label="Installer">
            <Link
              className="chip"
              to={chipTo('assignee', '')}
              aria-current={assignee ? undefined : 'true'}
            >
              All installers
            </Link>
            {!listed && (
              <Link className="chip" to={chipTo('assignee', assignee)} aria-current="true">
                The chosen installer
              </Link>
            )}
            {people.map((m) => (
              <Link
                key={m.user_id}
                className="chip"
                to={chipTo('assignee', m.user_id)}
                aria-current={m.user_id === assignee ? 'true' : undefined}
              >
                {m.name}
              </Link>
            ))}
          </nav>
        )}
        <Link
          className="chip chip-end"
          to={chipTo('view', problems ? '' : 'problem')}
          aria-current={problems ? 'true' : undefined}
        >
          <Icon name="alert" size={15} />
          Problems
        </Link>
      </div>
      <div className={problems ? 'board board-one' : 'board'}>
        {(problems ? [PROBLEMS] : COLUMNS).map((column) => (
          <BoardColumn key={`${column.view}-${assignee}`} column={column} assignee={assignee} />
        ))}
      </div>
    </>
  );
}

function BoardColumn({ column, assignee }: { column: Column; assignee: string }) {
  const { orgId } = useOrg();
  const { view, label, hint, dot, empty } = column;
  const tasks = usePages(orgId, ['tasks', view, assignee], (cursor, signal) =>
    unwrap(
      api.GET('/orgs/{org_id}/admin/tasks', {
        params: {
          path: { org_id: orgId },
          query: { view, assignee_id: assignee || undefined, cursor },
        },
        signal,
      }),
    ),
  );
  const items = tasks.data?.pages.flatMap((page) => page.items) ?? [];
  // All of them are here only when there's no next page.
  const whole = !tasks.hasNextPage;
  const shown =
    view === 'assigned' && whole
      ? [...items].sort((a, b) => Date.parse(a.due_at) - Date.parse(b.due_at))
      : items;
  return (
    <section className="column" aria-label={label}>
      <div className="column-head">
        <span className={`dot dot-${dot}`} aria-hidden="true" />
        <h2>{label}</h2>
        {tasks.data && <span className="column-count">{`${items.length}${whole ? '' : '+'}`}</span>}
        <span className="column-hint">{view === 'assigned' && !whole ? 'newest first' : hint}</span>
      </div>
      <QueryState query={tasks}>
        {() =>
          items.length === 0 ? (
            <p className="column-empty">{empty}</p>
          ) : (
            <>
              <ul className="column-cards">
                {shown.map((task) => (
                  <li key={task.id}>
                    <TaskCard task={task} />
                  </li>
                ))}
              </ul>
              {tasks.hasNextPage && (
                <div className="more">
                  <Button
                    compact
                    disabled={tasks.isFetchingNextPage}
                    onClick={() => void tasks.fetchNextPage()}
                  >
                    Show more
                  </Button>
                </div>
              )}
            </>
          )
        }
      </QueryState>
    </section>
  );
}

function TaskCard({ task: t }: { task: TaskSummary }) {
  const { to } = useOrg();
  const final = t.status === 'approved' || t.status === 'cancelled';
  const when =
    t.status === 'submitted'
      ? `Sent ${formatTime(t.status_at)}`
      : final
        ? formatShortDate(t.status_at)
        : formatWhen(t.due_at);
  return (
    <Link className="task-card" to={to(`tasks/${t.id}`)}>
      <span className="task-card-top">
        <span className="eyebrow">
          S{t.stage.index} · {t.title}
        </span>
        {t.status === 'submitted' && <StatusPill label="Review" tone="accent" />}
        {t.has_problem && !final && <StatusPill label="Problem" tone="warning" />}
        {t.status === 'cancelled' && <StatusPill label="Cancelled" tone="quiet" />}
      </span>
      <span className="cell-main">
        <span className="task-card-name">{t.customer_name}</span>
        <span className="cell-sub">
          {[t.system_kw && `${t.system_kw} kW`, t.place].filter(Boolean).join(' · ')}
        </span>
      </span>
      <span className="task-card-foot">
        <Avatar name={t.assignee_name} size="sm" />
        <span className="task-card-who">{t.assignee_name}</span>
        {!t.assignee_active && !final ? (
          <StatusPill label="Removed" tone="danger" />
        ) : (
          <span className="task-card-when">{when}</span>
        )}
      </span>
    </Link>
  );
}
