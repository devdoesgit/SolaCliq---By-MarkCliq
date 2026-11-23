import { useEffect, useRef, useState } from 'react';
import { Link, NavLink, Outlet, useLocation, useNavigate, useParams } from 'react-router';
import icon from '../assets/solacliq-icon.svg';
import { Avatar, Icon, Notice, type IconName } from '../components';
import { APP_NAME } from '../config';
import { useLogout, useMe } from '../features/auth/session';
import { useReview, useUnread } from '../features/inbox/queries';
import { AnnounceContext } from './announce';
import { adminCompanies, type OrgScope } from './org';

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

const SHOWN_MS = 6000;

/*
  One company's screens
  ----------------------------------------------------------------------
  - only the companies this person administers; the server checks again
    on every request
  - the company is in the address, so two tabs can show two companies
  - one that isn't active shows why instead of any screen
  - on a narrow screen the sidebar is a top bar, its links behind Menu
*/
export function CompanyLayout() {
  const { orgId = '' } = useParams();
  const { data: me } = useMe();
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const logout = useLogout();
  const main = useRef<HTMLElement>(null);
  const shownPath = useRef(pathname);
  const [said, setSaid] = useState('');
  // Open on the screen it was opened on, so going anywhere closes it.
  const [menuOn, setMenuOn] = useState('');

  useEffect(() => {
    if (!said) return;
    const timer = setTimeout(() => setSaid(''), SHOWN_MS);
    return () => clearTimeout(timer);
  }, [said]);

  // A new screen: from its top, and a screen reader starts there.
  useEffect(() => {
    if (shownPath.current === pathname) return;
    shownPath.current = pathname;
    main.current?.focus();
    if (window.scrollY > 0) window.scrollTo(0, 0);
  }, [pathname]);

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
  const menuOpen = menuOn === pathname;

  return (
    <AnnounceContext.Provider value={setSaid}>
      <div className="shell">
        <a className="skip" href="#content">
          Skip to content
        </a>
        <header className={menuOpen ? 'side side-open' : 'side'}>
          <div className="side-top">
            <img className="side-mark" src={logo ?? icon} alt="" />
            <div className="side-who">
              <p className="side-brand">{APP_NAME}</p>
              {companies.length > 1 ? (
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
              )}
            </div>
            {!closed && (
              <NavLink
                className="side-bell"
                to={scope.to('notifications')}
                aria-label={unread.data ? `Notifications, ${unread.data} unread` : 'Notifications'}
              >
                <Icon name="bell" size={19} />
                {!!unread.data && <span className="side-unread" />}
              </NavLink>
            )}
            <button
              type="button"
              className="side-menu"
              aria-label="Menu"
              aria-expanded={menuOpen}
              onClick={() => setMenuOn(menuOpen ? '' : pathname)}
            >
              <Icon name={menuOpen ? 'close' : 'menu'} size={19} />
            </button>
          </div>
          <div className="side-body">
            {!closed && (
              <nav className="side-nav" aria-label="Main">
                {NAV.map(({ path, label, icon: glyph, waiting }) => {
                  const count = waiting && review.data?.[waiting].length;
                  return (
                    <NavLink key={path} to={scope.to(path)} className="side-link">
                      <Icon name={glyph} size={19} />
                      {label} {!!count && <span className="side-count">{count}</span>}
                    </NavLink>
                  );
                })}
              </nav>
            )}
            <div className="side-foot">
              <Avatar name={me.name} dark />
              <div className="side-me">
                <p className="side-person" title={me.name}>
                  {me.name}
                </p>
                <p className="side-role">
                  Admin ·{' '}
                  <button
                    type="button"
                    className="link-button"
                    onClick={() => logout.mutate()}
                    disabled={logout.isPending}
                  >
                    Log out
                  </button>
                </p>
                <p className="side-legal">
                  <Link to="/terms">Terms</Link>
                  <Link to="/privacy">Privacy</Link>
                </p>
              </div>
            </div>
          </div>
        </header>
        <main id="content" className="content" tabIndex={-1} ref={main}>
          {closed ? (
            <Notice tone={closed.tone} title={closed.title} body={closed.body} />
          ) : (
            // Keyed, so no screen carries one company's state into another.
            <Outlet key={orgId} context={scope} />
          )}
        </main>
        <p className={said ? 'toast' : 'visually-hidden'} role="status">
          {said}
        </p>
      </div>
    </AnnounceContext.Provider>
  );
}
