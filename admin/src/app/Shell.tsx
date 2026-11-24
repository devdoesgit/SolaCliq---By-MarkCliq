import { useEffect, useRef, useState, type ReactNode } from 'react';
import { Link, NavLink, useLocation } from 'react-router';
import { Avatar, Icon, type IconName } from '../components';
import { APP_NAME } from '../config';
import { useLogout, type Me } from '../features/auth/session';
import { AnnounceContext } from './announce';

export interface NavItem {
  to: string;
  label: string;
  icon: IconName;
  count?: number;
}

const SHOWN_MS = 6000;

/*
  The admin website's frame: the sidebar and the screen beside it
  ----------------------------------------------------------------------
  - a company's screens (CompanyLayout) and MarkCliq's (PlatformLayout)
  - a new screen starts from its top, and a screen reader starts there
  - on a narrow screen the sidebar is a top bar, its links behind Menu
  - what worked is said in a toast, on screen and to screen readers
*/
export function Shell({
  me,
  mark,
  who,
  bell,
  nav,
  role,
  children,
}: {
  me: Me;
  /** The square at the top: the company's logo, or SolaCliq's mark. */
  mark: string;
  /** Under the app's name: the company's name, or a switch between them. */
  who: ReactNode;
  bell?: ReactNode;
  /** Left out while a company can't be used. */
  nav?: NavItem[];
  /** "Admin", "MarkCliq": shown before Log out. */
  role: string;
  children: ReactNode;
}) {
  const { pathname } = useLocation();
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

  useEffect(() => {
    if (shownPath.current === pathname) return;
    shownPath.current = pathname;
    main.current?.focus();
    if (window.scrollY > 0) window.scrollTo(0, 0);
  }, [pathname]);

  const menuOpen = menuOn === pathname;

  return (
    <AnnounceContext.Provider value={setSaid}>
      <div className="shell">
        <a className="skip" href="#content">
          Skip to content
        </a>
        <header className={menuOpen ? 'side side-open' : 'side'}>
          <div className="side-top">
            <img className="side-mark" src={mark} alt="" />
            <div className="side-who">
              <p className="side-brand">{APP_NAME}</p>
              {who}
            </div>
            {bell}
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
            {nav && (
              <nav className="side-nav" aria-label="Main">
                {nav.map(({ to, label, icon, count }) => (
                  <NavLink key={to} to={to} end={to === '/'} className="side-link">
                    <Icon name={icon} size={19} />
                    {label} {!!count && <span className="side-count">{count}</span>}
                  </NavLink>
                ))}
              </nav>
            )}
            <div className="side-foot">
              <Avatar name={me.name} dark />
              <div className="side-me">
                <p className="side-person" title={me.name}>
                  {me.name}
                </p>
                <p className="side-role">
                  {role} ·{' '}
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
          {children}
        </main>
        <p className={said ? 'toast' : 'visually-hidden'} role="status">
          {said}
        </p>
      </div>
    </AnnounceContext.Provider>
  );
}
