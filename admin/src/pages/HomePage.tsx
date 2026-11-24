import { Link, Navigate } from 'react-router';
import { adminCompanies } from '../app/org';
import { Button, Notice, StatusPill, type Tone } from '../components';
import { SHOW_DEV_TOOLS } from '../config';
import { AuthFrame } from '../features/auth/AuthLayout';
import { useLogout, useMe, type Me } from '../features/auth/session';
import { useWaiting } from '../features/platform/queries';

type OrgStatus = Me['memberships'][number]['org']['status'];

const STATUS: Record<OrgStatus, { label: string; tone: Tone }> = {
  pending: { label: 'Pending approval', tone: 'info' },
  active: { label: 'Active', tone: 'success' },
  suspended: { label: 'Suspended', tone: 'danger' },
  rejected: { label: 'Not approved', tone: 'danger' },
};

/*
  Where log in lands
  ----------------------------------------------------------------------
  - straight into the one active company
  - else the choice; a MarkCliq platform admin always gets it, with
    MarkCliq's Companies on top (F22)
*/
export function HomePage() {
  const { data: me } = useMe();
  const logout = useLogout();
  const platform = !!me?.is_platform_admin;
  const waiting = useWaiting(platform);
  if (!me) return null; // RequireSession only renders this when signed in.

  const companies = adminCompanies(me);
  if (!platform && companies.length === 1 && companies[0].org.status === 'active') {
    return <Navigate to={`/c/${companies[0].org.id}/overview`} replace />;
  }

  return (
    <AuthFrame>
      <header className="page-head-main">
        <p className="t-label muted">{me.email}</p>
        <h1 className="auth-title">Hello, {me.name}</h1>
      </header>

      {platform && (
        <section className="stack">
          <h2 className="t-h2">MarkCliq</h2>
          <ul className="sc-list">
            <li>
              <Link className="sc-row" to="/platform/companies">
                <span className="t-row-title">Companies</span>
                {waiting.data && waiting.data !== '0' && (
                  <StatusPill label={`${waiting.data} waiting`} tone="info" />
                )}
              </Link>
            </li>
          </ul>
        </section>
      )}

      {companies.length === 0 && !platform && (
        <Notice
          title="This website is for solar vendors"
          body="Use the SolaCliq app on your phone to see your installation, jobs or commission."
        />
      )}

      {companies.length > 0 && (
        <section className="stack">
          <h2 className="t-h2">Your companies</h2>
          <ul className="sc-list">
            {companies.map(({ org }) => (
              <li key={org.id}>
                <Link className="sc-row" to={`/c/${org.id}`}>
                  <span className="t-row-title">{org.name}</span>
                  <StatusPill {...STATUS[org.status]} />
                </Link>
              </li>
            ))}
          </ul>
        </section>
      )}

      <div className="actions">
        <Button onClick={() => logout.mutate()} disabled={logout.isPending}>
          Log out
        </Button>
        {SHOW_DEV_TOOLS && <Link to="/gallery">Component gallery</Link>}
      </div>
    </AuthFrame>
  );
}
