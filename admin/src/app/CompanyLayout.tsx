import { Link, NavLink, Outlet, useNavigate, useParams } from 'react-router';
import icon from '../assets/solacliq-icon.svg';
import { Icon, Notice, type IconName } from '../components';
import { useMe } from '../features/auth/session';
import { useReview, useUnread } from '../features/inbox/queries';
import { adminCompanies, type OrgScope } from './org';
import { Shell } from './Shell';

type Part = 'tasks' | 'registrations' | 'commissions' | 'expenses' | 'payments' | 'leads';

// The design's order, with the three screens it predates in its style.
const NAV: { path: string; label: string; icon: IconName; waiting?: Part }[] = [
  { path: 'overview', label: 'Overview', icon: 'overview' },
  { path: 'tasks', label: 'Tasks', icon: 'tasks', waiting: 'tasks' },
  { path: 'customers', label: 'Customers', icon: 'customers', waiting: 'registrations' },
  { path: 'projects', label: 'Projects', icon: 'projects' },
  { path: 'commissions', label: 'Commissions', icon: 'commissions', waiting: 'commissions' },
  { path: 'expenses', label: 'Expenses', icon: 'expenses', waiting: 'expenses' },
  { path: 'leads', label: 'Leads', icon: 'leads', waiting: 'leads' },
  { path: 'payments', label: 'Payments', icon: 'payments', waiting: 'payments' },
  { path: 'attendance', label: 'Attendance', icon: 'attendance' },
  { path: 'team', label: 'Team', icon: 'team' },
  { path: 'settings', label: 'Settings', icon: 'settings' },
];

const CLOSED = {
  pending: {
    title: 'Waiting for MarkCliq to approve',
    body: 'We check every company and call the owner. You get an email when it is approved.',
    tone: 'info',
  },
  suspended: {
    title: 'This company is suspended',
    body: 'Its data is safe. Contact MarkCliq at info@markcliq.com or +91 70092 13298.',
    tone: 'danger',
  },
  rejected: {
    title: "This company's registration wasn't approved",
    body: 'The reason was emailed to the owner. You can register again in the app.',
    tone: 'danger',
  },
} as const;

/*
  One company's screens
  ----------------------------------------------------------------------
  - only the companies this person administers; the server checks again
    on every request
  - the company is in the address, so two tabs can show two companies
  - one that isn't active shows why instead of any screen
*/
export function CompanyLayout() {
  const { orgId = '' } = useParams();
  const { data: me } = useMe();
  const navigate = useNavigate();

  const companies = me ? adminCompanies(me) : [];
  const company = companies.find((m) => m.org.id === orgId);
  const name = company?.org.name ?? '';
  const active = company?.org.status === 'active';
  const review = useReview(orgId, active);
  const unread = useUnread(orgId, active);
  const scope: OrgScope = { orgId, name, to: (path) => `/c/${orgId}/${path}` };

  if (!me) return null;
  if (!company) {
    return (
      <main className="page stack-lg">
        <Notice tone="danger" announce title="That company isn't one you manage" />
        <Link to="/">Your companies</Link>
      </main>
    );
  }
  const { status, logo_url: logo } = company.org;
  const closed = status === 'active' ? null : CLOSED[status];

  return (
    <Shell
      me={me}
      mark={logo ?? icon}
      who={
        companies.length > 1 ? (
          <select
            className="side-switch"
            aria-label="Company"
            value={orgId}
            onChange={(e) => void navigate(`/c/${e.target.value}`)}
          >
            {companies.map((m) => (
              <option key={m.org.id} value={m.org.id}>
                {m.org.name}
              </option>
            ))}
          </select>
        ) : (
          <p className="side-name">{name}</p>
        )
      }
      bell={
        !closed && (
          <NavLink
            className="side-bell"
            to={scope.to('notifications')}
            aria-label={unread.data ? `Notifications, ${unread.data} unread` : 'Notifications'}
          >
            <Icon name="bell" size={19} />
            {!!unread.data && <span className="side-unread" />}
          </NavLink>
        )
      }
      nav={
        closed
          ? undefined
          : NAV.map(({ path, label, icon: glyph, waiting }) => ({
              to: scope.to(path),
              label,
              icon: glyph,
              count: waiting && review.data?.[waiting].length,
            }))
      }
      role="Admin"
    >
      {closed ? (
        <Notice tone={closed.tone} title={closed.title} body={closed.body} />
      ) : (
        // Keyed, so no screen carries one company's state into another.
        <Outlet key={orgId} context={scope} />
      )}
    </Shell>
  );
}
