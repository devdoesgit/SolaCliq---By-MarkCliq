import { Link } from 'react-router';
import { Button, ListRow, Notice, StatusPill, type Tone } from '../components';
import { SHOW_DEV_TOOLS } from '../config';
import { canUseAdmin, useLogout, useMe, type Me } from '../features/auth/session';

type Membership = Me['memberships'][number];

const ROLE: Record<Membership['role'], string> = {
  org_admin: 'Admin',
  worker: 'Installer',
  agent: 'Agent',
  customer: 'Customer',
};

const STATUS: Record<Membership['org']['status'], { label: string; tone: Tone }> = {
  pending: { label: 'Pending approval', tone: 'info' },
  active: { label: 'Active', tone: 'success' },
  suspended: { label: 'Suspended', tone: 'danger' },
};

/** The signed-in page until the org dashboard (F2/F3) replaces it. */
export function AccountPage() {
  const { data: me } = useMe();
  const logout = useLogout();
  if (!me) return null; // RequireSession only renders this when signed in.

  const allowed = canUseAdmin(me);

  return (
    <main className="page stack" style={{ gap: 'var(--space-8)' }}>
      <header className="stack" style={{ gap: 'var(--space-3)' }}>
        <p className="t-label muted">{me.email}</p>
        <h1 className="t-display">Hello, {me.name}</h1>
      </header>

      {!allowed && (
        <Notice
          title="This website is for solar vendors"
          body="Use the SolaCliq app on your phone to see your installation, jobs or commission."
        />
      )}

      {allowed && me.memberships.length > 0 && (
        <section className="stack" style={{ gap: 'var(--space-4)', maxWidth: '40rem' }}>
          <h2 className="t-h2">Your companies</h2>
          <ul className="sc-list">
            {me.memberships.map((m) => (
              <ListRow
                key={m.org.id}
                title={m.org.name}
                meta={ROLE[m.role]}
                end={
                  <StatusPill label={STATUS[m.org.status].label} tone={STATUS[m.org.status].tone} />
                }
              />
            ))}
          </ul>
        </section>
      )}

      {me.is_platform_admin && <p className="t-label muted">MarkCliq platform admin</p>}

      <div
        style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-4)', alignItems: 'center' }}
      >
        <Button onClick={() => logout.mutate()} disabled={logout.isPending}>
          Log out
        </Button>
        {SHOW_DEV_TOOLS && (
          <Link className="t-label" to="/gallery">
            Component gallery
          </Link>
        )}
      </div>
    </main>
  );
}
