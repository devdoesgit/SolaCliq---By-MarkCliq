import { Link } from 'react-router';
import type { ReviewItem, ReviewQueue } from '../../api/types';
import { useOverview, useSettings } from '../../app/data';
import { useOrg } from '../../app/org';
import {
  Icon,
  PageHeader,
  QueryState,
  Section,
  Stat,
  StatusPill,
  type IconName,
  type Tone,
} from '../../components';
import {
  formatLongDay,
  formatPaise,
  formatShortDate,
  formatWhen,
  greeting,
} from '../../lib/format';
import { COMMISSION, EXPENSE, LEAD } from '../../lib/labels';
import { useMe } from '../auth/session';
import { useReview } from '../inbox/queries';

interface Waiting {
  key: string;
  at: string;
  icon: IconName;
  title: string;
  sub: string;
  path: string;
  pill: { label: string; tone?: Tone };
}

const money = (item: ReviewItem) => (item.amount == null ? '' : ` ${formatPaise(item.amount)}`);
const join = (...parts: (string | undefined)[]) => parts.filter(Boolean).join(' · ');

/** Everything waiting for the admin, as one list, oldest first. */
function waitingOf(queue: ReviewQueue): Waiting[] {
  const rows: Waiting[] = [
    ...queue.tasks.map((t): Waiting => {
      const problem = t.status === 'problem';
      const reply = t.status === 'reply';
      return {
        key: `t${t.id}`,
        at: t.at,
        icon: problem ? 'alert' : reply ? 'info' : 'check',
        title: problem ? 'Problem reported' : reply ? 'Installer replied' : 'Review proof',
        sub: join(t.title, t.person),
        path: `tasks/${t.id}`,
        pill: problem
          ? { label: 'Problem', tone: 'warning' }
          : reply
            ? { label: 'Replied', tone: 'accent' }
            : { label: 'In review' },
      };
    }),
    ...queue.registrations.map((r): Waiting => ({
      key: `r${r.id}`,
      at: r.at,
      icon: 'customers',
      title: 'New customer',
      sub: join(r.title, r.person && `by ${r.person}`),
      path: `customers/${r.id}`,
      pill: { label: 'In review' },
    })),
    ...queue.payments.map((p): Waiting => ({
      key: `p${p.id}`,
      at: p.at,
      icon: 'payments',
      title: `Payment to confirm${money(p)}`,
      sub: join(p.person, p.title),
      path: 'payments?status=claimed',
      pill: { label: 'Says paid', tone: 'warning' },
    })),
    ...queue.expenses.map((e): Waiting => ({
      key: `e${e.id}`,
      at: e.at,
      icon: 'expenses',
      title: `Expense${money(e)}`,
      sub: join(e.person, e.title),
      path: `expenses/${e.id}`,
      pill: e.status === 'approved' ? EXPENSE.approved : { label: 'In review' },
    })),
    ...queue.commissions.map((c): Waiting => {
      const payable = c.status === 'payable';
      return {
        key: `c${c.id}`,
        at: c.at,
        icon: 'commissions',
        title: `${payable ? 'Commission payable' : 'Commission to approve'}${money(c)}`,
        sub: join(c.person, c.title),
        path: `commissions?status=${c.status}`,
        pill: payable ? COMMISSION.payable : { label: 'In review' },
      };
    }),
    ...queue.leads.map((l): Waiting => ({
      key: `l${l.id}`,
      at: l.at,
      icon: 'leads',
      title: 'New lead',
      sub: join(l.title, l.person),
      path: `leads/${l.id}`,
      pill: LEAD.new,
    })),
  ];
  return rows.sort((a, b) => Date.parse(a.at) - Date.parse(b.at));
}

/** Home (W5), as the admin design's Overview. */
export function OverviewPage() {
  const { orgId, name, to } = useOrg();
  const { data: me } = useMe();
  const review = useReview(orgId);
  const overview = useOverview(orgId);
  const settings = useSettings(orgId);
  const now = new Date();
  const first = me?.name.trim().split(/\s+/)[0] ?? '';

  return (
    <>
      <PageHeader
        title={`${greeting(now)}, ${first}`}
        meta={`${name} · ${formatLongDay(now)}`}
        actions={
          <Link className="sc-btn sc-btn-primary sc-btn-compact" to={to('tasks/new')}>
            <Icon name="plus" size={16} />
            <span>New task</span>
          </Link>
        }
      />
      <QueryState query={overview}>
        {(o) => (
          <div className="stats">
            <Stat
              dot="sun"
              label="Installs running"
              value={o.installs_running}
              sub={`across ${o.by_stage.length} stages`}
              to={to('projects')}
            />
            <Stat
              dot="success"
              label="Collected this month"
              value={formatPaise(o.collected_this_month)}
              sub="advances and instalments"
              to={to('payments?status=paid')}
            />
            <Stat
              dot="tan"
              label="To collect"
              value={formatPaise(o.to_collect)}
              sub="asked for, not yet confirmed"
              to={to('payments?status=due')}
            />
            <Stat
              dot="danger"
              label="Needs you"
              value={review.data ? waitingOf(review.data).length : '–'}
              sub="approvals waiting"
            />
          </div>
        )}
      </QueryState>
      <div className="overview">
        <Section title="Needs you" aside="oldest first">
          <QueryState query={review}>
            {(queue) => {
              const rows = waitingOf(queue);
              if (rows.length === 0) return <p className="empty">Nothing is waiting for you.</p>;
              return (
                <ul className="rows">
                  {rows.map((row) => (
                    <li key={row.key}>
                      <Link className="row" to={to(row.path)}>
                        <span className="row-icon">
                          <Icon name={row.icon} size={17} />
                        </span>
                        <span className="cell-main row-main">
                          <span className="row-title">{row.title}</span>
                          <span className="cell-sub">
                            {row.sub}
                            <span className="visually-hidden">, {formatWhen(row.at, now)}</span>
                          </span>
                        </span>
                        <StatusPill {...row.pill} />
                        <span className="row-chevron">
                          <Icon name="chevron" />
                        </span>
                      </Link>
                    </li>
                  ))}
                </ul>
              );
            }}
          </QueryState>
        </Section>
        {overview.data && (
          <div className="col">
            <Section title="Installs finished per week">
              <Bars weeks={overview.data.finished_by_week} />
            </Section>
            <Section title="Projects by stage" className="grow">
              <ByStage counts={overview.data.by_stage} names={settings.data?.stages} />
            </Section>
          </div>
        )}
      </div>
    </>
  );
}

/*
  Drawn as SVG: the bars' sizes are data, and the CSP allows no style
  attributes in markup
*/
function Bars({ weeks }: { weeks: { from: string; count: number }[] }) {
  const most = Math.max(1, ...weeks.map((w) => w.count));
  // Four flat lines read as a broken chart.
  if (most === 1 && weeks.every((w) => w.count === 0)) {
    return (
      <p className="bars-empty muted">
        No installs handed over in the last four weeks. Each week&apos;s count shows here.
      </p>
    );
  }
  return (
    <ol className="bars">
      {weeks.map((week, i) => {
        const height = week.count === 0 ? 4 : Math.round((week.count / most) * 124);
        return (
          <li key={week.from}>
            <span className="bars-count">{week.count}</span>
            <svg className="bars-bar" height={height} aria-hidden="true">
              <rect
                className={i === weeks.length - 1 ? 'bar-now' : 'bar'}
                width="100%"
                height="100%"
                rx="8"
              />
            </svg>
            <span className="bars-label">
              {i === weeks.length - 1
                ? 'Last 7 days'
                : `From ${formatShortDate(`${week.from}T06:30:00Z`)}`}
            </span>
          </li>
        );
      })}
    </ol>
  );
}

function ByStage({ counts, names }: { counts: number[]; names?: string[] }) {
  const most = Math.max(1, ...counts);
  return (
    <ol className="by-stage">
      {counts.map((count, i) => (
        <li key={i}>
          <span className="by-stage-name">{names?.[i] ?? `Stage ${i + 1}`}</span>
          <svg className="by-stage-track" height="10" aria-hidden="true">
            <rect className="track" width="100%" height="10" rx="5" />
            {count > 0 && (
              <rect
                className="bar-now"
                width={`${Math.max(6, (count / most) * 100)}%`}
                height="10"
                rx="5"
              />
            )}
          </svg>
          <span className="by-stage-count">{count}</span>
        </li>
      ))}
    </ol>
  );
}
