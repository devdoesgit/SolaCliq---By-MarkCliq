import { Navigate, Outlet, useLocation, useSearchParams } from 'react-router';
import { adminCompanies } from '../../app/org';
import { Button, Notice } from '../../components';
import { useMe, type Me } from './session';
import { safeNextPath } from './validators';
import { TermsGate } from './TermsGate';

function Loading() {
  return (
    <main className="page">
      <p className="t-label muted" role="status">
        Loading
      </p>
    </main>
  );
}

function SessionError({ retry }: { retry: () => void }) {
  return (
    <main className="page">
      <Notice
        tone="danger"
        title="Can't reach the server"
        body="Check your internet connection and try again."
        announce
        action={
          <Button compact onClick={retry}>
            Try again
          </Button>
        }
      />
    </main>
  );
}

/** Pages for signed-in people. Others go to log in, and come back after. */
export function RequireSession() {
  const { data: me, isPending, isError, refetch } = useMe();
  const location = useLocation();
  if (isPending) return <Loading />;
  if (isError) return <SessionError retry={() => void refetch()} />;
  if (!me) {
    const next = `${location.pathname}${location.search}`;
    const to = next === '/' ? '/login' : `/login?next=${encodeURIComponent(next)}`;
    return <Navigate to={to} replace />;
  }
  if ((me.terms.accepted_version ?? 0) < me.terms.current_version) return <TermsGate me={me} />;
  return <Outlet />;
}

/*
  Where log in leads: the page that was opened
  ----------------------------------------------------------------------
  - unless it's a company this person doesn't manage: on a shared
    computer `next` is the last person's
*/
function landing(me: Me, next: string | null): string {
  const path = safeNextPath(next);
  const company = /^\/c\/([^/?#]+)/.exec(path)?.[1];
  return company && adminCompanies(me).some((m) => m.org.id === company) ? path : '/';
}

/*
  Log in and password pages: signed-in people go on from them
  ----------------------------------------------------------------------
  - this is also what follows a log in: `me` arriving redraws this
    before the page's own code after log in could navigate
*/
export function PublicOnly() {
  const { data: me, isPending, isError, refetch } = useMe();
  const [params] = useSearchParams();
  if (isPending) return <Loading />;
  if (isError) return <SessionError retry={() => void refetch()} />;
  if (me) return <Navigate to={landing(me, params.get('next'))} replace />;
  return <Outlet />;
}
